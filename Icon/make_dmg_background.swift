// Renders the background for the T-Minus.dmg installer window (640×400, plus @2x).
//   swift Icon/make_dmg_background.swift <out.tiff>
// build.sh --dist runs this; icons sit at (160, 190) and (480, 190) in Finder's top-left coordinates.
import AppKit

let w = 640.0, h = 400.0
let green = NSColor(red: 0.20, green: 1.00, blue: 0.55, alpha: 1)
let cyan = NSColor(red: 0.15, green: 0.85, blue: 1.00, alpha: 1)

func render(scale: Int) -> NSBitmapImageRep {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(w) * scale, pixelsHigh: Int(h) * scale,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: w, height: h)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let cg = NSGraphicsContext.current!.cgContext
    cg.scaleBy(x: CGFloat(scale), y: CGFloat(scale))

    let bg = CGGradient(colorsSpace: nil, colors: [
        NSColor(red: 0.10, green: 0.10, blue: 0.20, alpha: 1).cgColor,
        NSColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(bg, start: CGPoint(x: 0, y: h), end: .zero, options: [])

    var seed: UInt64 = 11
    func rnd() -> CGFloat {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(seed >> 33) / CGFloat(UInt32.max >> 1)
    }
    for _ in 0..<70 {
        let r = 0.6 + rnd() * 1.4
        cg.setFillColor(NSColor.white.withAlphaComponent(0.15 + rnd() * 0.45).cgColor)
        cg.fillEllipse(in: CGRect(x: rnd() * w, y: rnd() * h, width: r * 2, height: r * 2))
    }

    // Dashed launch trajectory from the app to Applications, ending in an arrowhead
    let y = h - 190
    cg.saveGState()
    cg.setShadow(offset: .zero, blur: 12, color: green.cgColor)
    cg.setStrokeColor(green.cgColor)
    cg.setLineWidth(4)
    cg.setLineCap(.round)
    cg.setLineDash(phase: 0, lengths: [2, 12])
    cg.move(to: CGPoint(x: 245, y: y))
    cg.addQuadCurve(to: CGPoint(x: 385, y: y), control: CGPoint(x: 315, y: y + 40))
    cg.strokePath()
    cg.setLineDash(phase: 0, lengths: [])
    cg.setFillColor(green.cgColor)
    cg.move(to: CGPoint(x: 398, y: y - 4))
    cg.addLine(to: CGPoint(x: 376, y: y + 12))
    cg.addLine(to: CGPoint(x: 380, y: y - 12))
    cg.closePath()
    cg.fillPath()
    cg.restoreGState()

    // Finder draws icon labels in black (Light Mode) or white (Dark Mode); a mid-grey nameplate
    // under each label keeps both readable on the dark background.
    for x in [160.0, 480.0] {
        let plate = CGPath(roundedRect: CGRect(x: x - 75, y: h - 283, width: 150, height: 28),
                           cornerWidth: 14, cornerHeight: 14, transform: nil)
        cg.addPath(plate)
        cg.setFillColor(NSColor.white.withAlphaComponent(0.4).cgColor)
        cg.fillPath()
    }

    func text(_ s: String, _ size: CGFloat, _ weight: NSFont.Weight, _ color: NSColor, y: CGFloat, mono: Bool = false) {
        let font = mono ? NSFont.monospacedSystemFont(ofSize: size, weight: weight) : NSFont.systemFont(ofSize: size, weight: weight)
        let para = NSMutableParagraphStyle()
        para.alignment = .center
        let str = NSAttributedString(string: s, attributes: [.font: font, .foregroundColor: color, .paragraphStyle: para, .kern: mono ? 2 : 0])
        str.draw(in: CGRect(x: 0, y: y, width: w, height: size * 1.5))
    }
    text("T-MINUS // MEETING LAUNCH CONTROL", 13, .bold, green, y: h - 50, mono: true)
    text("Drag T-Minus into Applications to install", 17, .semibold, .white, y: 80)
    text("First launch blocked? System Settings → Privacy & Security → Open Anyway", 11, .regular,
         cyan.withAlphaComponent(0.8), y: 44)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "background.tiff"
// A multi-representation TIFF lets Finder pick the sharp 2x image on Retina screens.
let data = NSBitmapImageRep.tiffRepresentationOfImageReps(in: [render(scale: 1), render(scale: 2)], using: .lzw, factor: 0)!
try! data.write(to: URL(fileURLWithPath: out))
print("✓ wrote \(out)")
