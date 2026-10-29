// Draws the MDView app icon (1024×1024 PNG): a paper sheet with the Markdown mark on a dusk gradient.
import AppKit

let size: CGFloat = 1024
let ctx = CGContext(data: nil, width: Int(size), height: Int(size), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat(hex >> 16 & 255) / 255, green: CGFloat(hex >> 8 & 255) / 255, blue: CGFloat(hex & 255) / 255, alpha: a)
}
func gradient(_ colors: [CGColor]) -> CGGradient { CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: nil)! }

// Squircle background on the macOS icon grid (824pt body, 100pt margin).
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let squircle = CGPath(roundedRect: body, cornerWidth: 186, cornerHeight: 186, transform: nil)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: rgb(0, 0.35))
ctx.addPath(squircle); ctx.setFillColor(rgb(0x1E1B4B)); ctx.fillPath()
ctx.restoreGState()
ctx.saveGState()
ctx.addPath(squircle); ctx.clip()
ctx.drawLinearGradient(gradient([rgb(0x312E81), rgb(0x7C3AED), rgb(0xF472B6), rgb(0xFDBA74)]),
                       start: CGPoint(x: 100, y: 924), end: CGPoint(x: 924, y: 100), options: [])
// soft glow behind the page
ctx.drawRadialGradient(gradient([rgb(0xFFFFFF, 0.35), rgb(0xFFFFFF, 0)]), startCenter: CGPoint(x: 512, y: 560), startRadius: 0,
                       endCenter: CGPoint(x: 512, y: 560), endRadius: 420, options: [])
ctx.restoreGState()

// Paper sheet with a folded corner, slightly tilted.
ctx.saveGState()
ctx.translateBy(x: 512, y: 512); ctx.rotate(by: -0.06); ctx.translateBy(x: -512, y: -512)
let page = CGRect(x: 262, y: 196, width: 500, height: 632), fold: CGFloat = 120
let sheet = CGMutablePath()
sheet.move(to: CGPoint(x: page.minX + 36, y: page.minY))
sheet.addLine(to: CGPoint(x: page.maxX - 36, y: page.minY))
sheet.addQuadCurve(to: CGPoint(x: page.maxX, y: page.minY + 36), control: CGPoint(x: page.maxX, y: page.minY))
sheet.addLine(to: CGPoint(x: page.maxX, y: page.maxY - fold))
sheet.addLine(to: CGPoint(x: page.maxX - fold, y: page.maxY))
sheet.addLine(to: CGPoint(x: page.minX + 36, y: page.maxY))
sheet.addQuadCurve(to: CGPoint(x: page.minX, y: page.maxY - 36), control: CGPoint(x: page.minX, y: page.maxY))
sheet.addLine(to: CGPoint(x: page.minX, y: page.minY + 36))
sheet.addQuadCurve(to: CGPoint(x: page.minX + 36, y: page.minY), control: CGPoint(x: page.minX, y: page.minY))
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: rgb(0x1E1B4B, 0.45))
ctx.addPath(sheet); ctx.setFillColor(rgb(0xFFFFFF)); ctx.fillPath()
ctx.restoreGState()
// dog-ear
let ear = CGMutablePath()
ear.move(to: CGPoint(x: page.maxX, y: page.maxY - fold))
ear.addLine(to: CGPoint(x: page.maxX - fold + 14, y: page.maxY - fold))
ear.addQuadCurve(to: CGPoint(x: page.maxX - fold, y: page.maxY - fold + 14), control: CGPoint(x: page.maxX - fold, y: page.maxY - fold))
ear.addLine(to: CGPoint(x: page.maxX - fold, y: page.maxY))
ear.closeSubpath()
ctx.saveGState()
ctx.addPath(ear); ctx.clip()
ctx.drawLinearGradient(gradient([rgb(0xE9D5FF), rgb(0xC4B5FD)]), start: CGPoint(x: page.maxX - fold, y: page.maxY),
                       end: CGPoint(x: page.maxX, y: page.maxY - fold), options: [])
ctx.restoreGState()

// Markdown mark: "M" + down arrow, filled with the background gradient.
let mark = CGMutablePath()
let mx: CGFloat = 318, my: CGFloat = 470, mh: CGFloat = 220, sw: CGFloat = 54
mark.addLines(between: [CGPoint(x: mx, y: my), CGPoint(x: mx, y: my + mh), CGPoint(x: mx + sw, y: my + mh),
                        CGPoint(x: mx + 105, y: my + mh - 92), CGPoint(x: mx + 210 - sw, y: my + mh),
                        CGPoint(x: mx + 210, y: my + mh), CGPoint(x: mx + 210, y: my), CGPoint(x: mx + 210 - sw, y: my),
                        CGPoint(x: mx + 210 - sw, y: my + mh - 112), CGPoint(x: mx + 105, y: my + mh - 170),
                        CGPoint(x: mx + sw, y: my + mh - 112), CGPoint(x: mx + sw, y: my)])
mark.closeSubpath()
let ax: CGFloat = 610
mark.addLines(between: [CGPoint(x: ax - 28, y: my + mh), CGPoint(x: ax + 28, y: my + mh), CGPoint(x: ax + 28, y: my + 92),
                        CGPoint(x: ax + 82, y: my + 92), CGPoint(x: ax, y: my), CGPoint(x: ax - 82, y: my + 92),
                        CGPoint(x: ax - 28, y: my + 92)])
mark.closeSubpath()
ctx.saveGState()
ctx.addPath(mark); ctx.clip()
ctx.drawLinearGradient(gradient([rgb(0x4C1D95), rgb(0x7C3AED), rgb(0xDB2777)]),
                       start: CGPoint(x: mx, y: my + mh), end: CGPoint(x: ax + 82, y: my), options: [])
ctx.restoreGState()

// Rendered "text" lines below the mark.
let lines: [(CGFloat, CGFloat, UInt32)] = [(392, 388, 0xA78BFA), (340, 300, 0xE5E7EB), (288, 360, 0xE5E7EB), (236, 240, 0xE5E7EB)]
for (y, w, c) in lines {
    ctx.addPath(CGPath(roundedRect: CGRect(x: 318, y: y, width: w, height: 26), cornerWidth: 13, cornerHeight: 13, transform: nil))
    ctx.setFillColor(rgb(c)); ctx.fillPath()
}
ctx.restoreGState()

// "Fast" badge: a lightning bolt in a white-ringed disc, bottom-right.
let c = CGPoint(x: 752, y: 262)
ctx.setShadow(offset: CGSize(width: 0, height: -6), blur: 16, color: rgb(0x1E1B4B, 0.45))
ctx.addEllipse(in: CGRect(x: c.x - 74, y: c.y - 74, width: 148, height: 148)); ctx.setFillColor(rgb(0xFFFFFF)); ctx.fillPath()
ctx.setShadow(offset: .zero, blur: 0, color: nil)
ctx.saveGState()
ctx.addEllipse(in: CGRect(x: c.x - 60, y: c.y - 60, width: 120, height: 120)); ctx.clip()
ctx.drawLinearGradient(gradient([rgb(0x312E81), rgb(0x1E1B4B)]), start: CGPoint(x: c.x, y: c.y + 60), end: CGPoint(x: c.x, y: c.y - 60), options: [])
ctx.restoreGState()
let bolt: [CGPoint] = [(15, 55), (-32, -5), (-2, -5), (-15, -55), (32, 8), (2, 8)].map { CGPoint(x: c.x + $0.0, y: c.y + $0.1) }
ctx.addLines(between: bolt); ctx.closePath()
ctx.setFillColor(rgb(0xFACC15)); ctx.fillPath()

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: out)
