// MDView — a tiny native Markdown previewer. Live-reloads when the file changes.
import Cocoa
import WebKit

let mdExtensions: Set<String> = ["md", "markdown", "mdown", "mkd", "mkdn", "mdx", "txt"]

final class PreviewWindow: NSWindowController, NSWindowDelegate, WKNavigationDelegate {
    let fileURL: URL
    private let webView: WKWebView
    private var watcher: DispatchSourceFileSystemObject?
    private var pageReady = false

    init(url: URL) {
        fileURL = url
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // no white flash in dark mode
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 860, height: 900),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = url.lastPathComponent
        window.representedURL = url
        window.contentView = webView
        window.tabbingMode = .preferred
        super.init(window: window)
        window.delegate = self
        webView.navigationDelegate = self
        if !window.setFrameUsingName("MDViewWindow") { window.center() }
        window.setFrameAutosaveName("MDViewWindow")

        let index = Bundle.main.url(forResource: "index", withExtension: "html")!
        webView.loadFileURL(index, allowingReadAccessTo: URL(fileURLWithPath: "/"))
        watch()
    }
    required init?(coder: NSCoder) { fatalError() }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pageReady = true
        render()
    }

    func render() {
        guard pageReady else { return }
        let text = (try? String(contentsOf: fileURL, encoding: .utf8))
            ?? (try? String(contentsOf: fileURL, encoding: .isoLatin1)) ?? ""
        let base = fileURL.deletingLastPathComponent().absoluteString
        let args = try! JSONSerialization.data(withJSONObject: [text, base])
        webView.evaluateJavaScript("render(...\(String(data: args, encoding: .utf8)!))")
    }

    // Editors often save by replacing the file, so re-attach the watcher after delete/rename.
    private func watch() {
        watcher?.cancel()
        let fd = open(fileURL.path, O_EVTONLY)
        guard fd >= 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.watch() }
            return
        }
        let src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd,
                                                            eventMask: [.write, .extend, .delete, .rename],
                                                            queue: .main)
        src.setEventHandler { [weak self, weak src] in
            guard let self, let src else { return }
            if !src.data.isDisjoint(with: [.delete, .rename]) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.watch(); self.render() }
            } else {
                self.render()
            }
        }
        src.setCancelHandler { Darwin.close(fd) }
        src.resume()
        watcher = src
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard action.navigationType == .linkActivated, let url = action.request.url else {
            return decisionHandler(.allow)
        }
        decisionHandler(.cancel)
        if url.isFileURL && mdExtensions.contains(url.pathExtension.lowercased()) {
            AppDelegate.shared.open(url)
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func reload(_ sender: Any?) { render() }
    @objc func zoomIn(_ sender: Any?) { webView.pageZoom = min(webView.pageZoom + 0.1, 3) }
    @objc func zoomOut(_ sender: Any?) { webView.pageZoom = max(webView.pageZoom - 0.1, 0.5) }
    @objc func zoomReset(_ sender: Any?) { webView.pageZoom = 1 }
    @objc func revealInFinder(_ sender: Any?) { NSWorkspace.shared.activateFileViewerSelecting([fileURL]) }

    func windowWillClose(_ notification: Notification) {
        watcher?.cancel()
        AppDelegate.shared.windows.removeAll { $0 === self }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    var windows: [PreviewWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        let files = CommandLine.arguments.dropFirst().filter { !$0.hasPrefix("-") }
        files.forEach { open(URL(fileURLWithPath: $0)) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.windows.isEmpty { self.openDocument(nil) }
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) { urls.forEach(open) }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { openDocument(nil) }
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func open(_ url: URL) {
        let url = url.standardizedFileURL
        if let existing = windows.first(where: { $0.fileURL == url }) {
            existing.showWindow(nil)
            return
        }
        let wc = PreviewWindow(url: url)
        windows.append(wc)
        wc.showWindow(nil)
        NSDocumentController.shared.noteNewRecentDocumentURL(url)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = []
        NSApp.activate(ignoringOtherApps: true)
        if panel.runModal() == .OK {
            panel.urls.forEach(open)
        } else if windows.isEmpty {
            NSApp.terminate(nil)
        }
    }

    private func buildMenu() {
        let main = NSMenu()
        func add(_ title: String, _ items: [NSMenuItem]) {
            let item = NSMenuItem()
            let menu = NSMenu(title: title)
            items.forEach(menu.addItem)
            item.submenu = menu
            main.addItem(item)
        }
        func item(_ title: String, _ action: Selector, _ key: String, _ mods: NSEvent.ModifierFlags = .command) -> NSMenuItem {
            let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
            i.keyEquivalentModifierMask = mods
            return i
        }
        add("MDView", [item("Hide MDView", #selector(NSApplication.hide(_:)), "h"),
                       .separator(),
                       item("Quit MDView", #selector(NSApplication.terminate(_:)), "q")])
        add("File", [item("Open…", #selector(openDocument(_:)), "o"),
                     item("Reveal in Finder", #selector(PreviewWindow.revealInFinder(_:)), "r", [.command, .shift]),
                     .separator(),
                     item("Close", #selector(NSWindow.performClose(_:)), "w")])
        add("Edit", [item("Copy", #selector(NSText.copy(_:)), "c"),
                     item("Select All", #selector(NSText.selectAll(_:)), "a")])
        add("View", [item("Reload", #selector(PreviewWindow.reload(_:)), "r"),
                     .separator(),
                     item("Zoom In", #selector(PreviewWindow.zoomIn(_:)), "="),
                     item("Zoom Out", #selector(PreviewWindow.zoomOut(_:)), "-"),
                     item("Actual Size", #selector(PreviewWindow.zoomReset(_:)), "0")])
        add("Window", [item("Minimize", #selector(NSWindow.performMiniaturize(_:)), "m")])
        NSApp.mainMenu = main
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
app.delegate = AppDelegate.shared
app.run()
