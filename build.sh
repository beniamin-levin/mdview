#!/bin/zsh
# Builds MDView.app and installs it to ~/Applications.
set -e
cd "$(dirname "$0")"
APP=build/MDView.app
rm -rf build && mkdir -p $APP/Contents/MacOS $APP/Contents/Resources
# Universal binary (Apple Silicon + Intel), runs on macOS 13 and later
for arch in arm64 x86_64; do
  swiftc -O -target $arch-apple-macos13 main.swift -o build/MDView-$arch -framework Cocoa -framework WebKit
done
lipo -create build/MDView-arm64 build/MDView-x86_64 -output $APP/Contents/MacOS/MDView
cp Resources/* $APP/Contents/Resources/
# App icon: icon/icon-1024.png (drawn by icon/make_icon.swift) -> AppIcon.icns
ICONSET=build/AppIcon.iconset && mkdir -p $ICONSET
for s in 16 32 128 256 512; do
  sips -z $s $s icon/icon-1024.png --out $ICONSET/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) icon/icon-1024.png --out $ICONSET/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns $ICONSET -o $APP/Contents/Resources/AppIcon.icns
cat > $APP/Contents/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>MDView</string>
  <key>CFBundleIdentifier</key><string>fyi.benlevin.mdview</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleExecutable</key><string>MDView</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>CFBundleDocumentTypes</key><array><dict>
    <key>CFBundleTypeName</key><string>Markdown</string>
    <key>CFBundleTypeRole</key><string>Viewer</string>
    <key>LSHandlerRank</key><string>Alternate</string>
    <key>LSItemContentTypes</key><array><string>net.daringfireball.markdown</string></array>
    <key>CFBundleTypeExtensions</key><array><string>md</string><string>markdown</string><string>mdown</string><string>mkd</string><string>mdx</string></array>
  </dict></array>
</dict></plist>
EOF
codesign --force --sign - $APP
mkdir -p ~/Applications
rm -rf ~/Applications/MDView.app && cp -R $APP ~/Applications/
LSR=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
$LSR -f ~/Applications/MDView.app
$LSR -u "$PWD/$APP" 2>/dev/null || true; rm -rf build  # keep only one copy in "Open With"
echo "Installed ~/Applications/MDView.app"
