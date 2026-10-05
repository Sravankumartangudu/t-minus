// Renders the T-Minus app icon: a dark squircle with a neon countdown ring and a launching rocket.
//   swift Icon/make_icon.swift   → writes Icon/AppIcon.icns
import AppKit

let size = 1024.0
let green = NSColor(red: 0.20, green: 1.00, blue: 0.55, alpha: 1)
let cyan = NSColor(red: 0.15, green: 0.85, blue: 1.00, alpha: 1)
let orange = NSColor(red: 1.00, green: 0.55, blue: 0.10, alpha: 1)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let cg = NSGraphicsContext.current!.cgContext
    cg.scaleBy(x: CGFloat(px) / size, y: CGFloat(px) / size)
    draw(cg)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

func draw(_ cg: CGContext) {
    // Body follows Apple's icon grid: 824pt squircle centred in a 1024 canvas.
    let body = CGRect(x: 100, y: 100, width: 824, height: 824)
    let squircle = CGPath(roundedRect: body, cornerWidth: 185, cornerHeight: 185, transform: nil)

    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -12), blur: 28, color: NSColor.black.withAlphaComponent(0.5).cgColor)
    cg.addPath(squircle)
    cg.setFillColor(NSColor.black.cgColor)
    cg.fillPath()
    cg.restoreGState()

    cg.saveGState()
    cg.addPath(squircle)
    cg.clip()
    let bg = CGGradient(colorsSpace: nil, colors: [
        NSColor(red: 0.10, green: 0.10, blue: 0.20, alpha: 1).cgColor,
        NSColor(red: 0.02, green: 0.02, blue: 0.05, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(bg, start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 100), options: [])
    let glow = CGGradient(colorsSpace: nil, colors: [
        green.withAlphaComponent(0.22).cgColor, green.withAlphaComponent(0).cgColor,
    ] as CFArray, locations: [0, 1])!
    cg.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 512), startRadius: 0,
                          endCenter: CGPoint(x: 512, y: 512), endRadius: 420, options: [])

    // Stars
    var seed: UInt64 = 7
    func rnd() -> CGFloat {
        seed = seed &* 6364136223846793005 &+ 1442695040888963407
        return CGFloat(seed >> 33) / CGFloat(UInt32.max >> 1)
    }
    for _ in 0..<40 {
        let p = CGPoint(x: 120 + rnd() * 784, y: 120 + rnd() * 784)
        let r = 1.5 + rnd() * 3
        cg.setFillColor(NSColor.white.withAlphaComponent(0.25 + rnd() * 0.5).cgColor)
        cg.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }

    let c = CGPoint(x: 512, y: 512)
    let radius: CGFloat = 300

    // Tick marks around the dial
    for i in 0..<60 {
        let a = CGFloat(i) / 60 * 2 * .pi
        let major = i % 5 == 0
        let r1 = radius + 34, r2 = radius + (major ? 62 : 48)
        cg.move(to: CGPoint(x: c.x + cos(a) * r1, y: c.y + sin(a) * r1))
        cg.addLine(to: CGPoint(x: c.x + cos(a) * r2, y: c.y + sin(a) * r2))
        cg.setStrokeColor(NSColor.white.withAlphaComponent(major ? 0.55 : 0.2).cgColor)
        cg.setLineWidth(major ? 7 : 4)
        cg.setLineCap(.round)
        cg.strokePath()
    }

    // Track and the remaining-time arc (counting down from 12 o'clock, ~3/4 left)
    cg.setLineWidth(34)
    cg.setStrokeColor(NSColor.white.withAlphaComponent(0.08).cgColor)
    cg.addArc(center: c, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
    cg.strokePath()

    let start = CGFloat.pi / 2, end = start - 1.5 * .pi
    let arc = CGMutablePath()
    arc.addArc(center: c, radius: radius, startAngle: start, endAngle: end, clockwise: true)
    cg.saveGState()
    cg.setShadow(offset: .zero, blur: 40, color: green.cgColor)
    cg.addPath(arc.copy(strokingWithWidth: 34, lineCap: .round, lineJoin: .round, miterLimit: 1))
    cg.clip()
    let ring = CGGradient(colorsSpace: nil, colors: [cyan.cgColor, green.cgColor] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(ring, start: CGPoint(x: 212, y: 212), end: CGPoint(x: 812, y: 812), options: [])
    cg.restoreGState()
    // Re-stroke for the glow (clip drops the shadow)
    cg.saveGState()
    cg.setShadow(offset: .zero, blur: 50, color: green.withAlphaComponent(0.9).cgColor)
    cg.addPath(arc)
    cg.setLineWidth(10)
    cg.setLineCap(.round)
    cg.setStrokeColor(NSColor.white.withAlphaComponent(0.6).cgColor)
    cg.strokePath()
    cg.restoreGState()

    // Glowing head of the countdown
    let head = CGPoint(x: c.x + cos(end) * radius, y: c.y + sin(end) * radius)
    cg.saveGState()
    cg.setShadow(offset: .zero, blur: 36, color: green.cgColor)
    cg.setFillColor(NSColor.white.cgColor)
    cg.fillEllipse(in: CGRect(x: head.x - 26, y: head.y - 26, width: 52, height: 52))
    cg.restoreGState()

    // Rocket, tilted up and to the right, launching out of the dial
    cg.saveGState()
    cg.translateBy(x: 512, y: 500)
    cg.rotate(by: -.pi / 5)

    // Flame
    cg.saveGState()
    cg.setShadow(offset: .zero, blur: 40, color: orange.cgColor)
    let flame = CGMutablePath()
    flame.move(to: CGPoint(x: -46, y: -120))
    flame.addQuadCurve(to: CGPoint(x: 0, y: -300), control: CGPoint(x: -40, y: -220))
    flame.addQuadCurve(to: CGPoint(x: 46, y: -120), control: CGPoint(x: 40, y: -220))
    flame.closeSubpath()
    cg.addPath(flame)
    cg.clip()
    let fire = CGGradient(colorsSpace: nil, colors: [
        NSColor(red: 1, green: 0.95, blue: 0.6, alpha: 1).cgColor, orange.cgColor,
        NSColor(red: 1, green: 0.2, blue: 0.3, alpha: 0).cgColor,
    ] as CFArray, locations: [0, 0.45, 1])!
    cg.drawLinearGradient(fire, start: CGPoint(x: 0, y: -120), end: CGPoint(x: 0, y: -300), options: [])
    cg.restoreGState()

    // Fins
    cg.setFillColor(NSColor(red: 1, green: 0.25, blue: 0.45, alpha: 1).cgColor)
    for s in [-1.0, 1.0] as [CGFloat] {
        let fin = CGMutablePath()
        fin.move(to: CGPoint(x: s * 52, y: -20))
        fin.addLine(to: CGPoint(x: s * 112, y: -120))
        fin.addLine(to: CGPoint(x: s * 104, y: -150))
        fin.addLine(to: CGPoint(x: s * 52, y: -110))
        fin.closeSubpath()
        cg.addPath(fin)
        cg.fillPath()
    }

    // Body
    let hull = CGMutablePath()
    hull.move(to: CGPoint(x: 0, y: 210))
    hull.addCurve(to: CGPoint(x: 58, y: 20), control1: CGPoint(x: 44, y: 170), control2: CGPoint(x: 62, y: 100))
    hull.addLine(to: CGPoint(x: 50, y: -125))
    hull.addLine(to: CGPoint(x: -50, y: -125))
    hull.addLine(to: CGPoint(x: -58, y: 20))
    hull.addCurve(to: CGPoint(x: 0, y: 210), control1: CGPoint(x: -62, y: 100), control2: CGPoint(x: -44, y: 170))
    cg.saveGState()
    cg.setShadow(offset: .zero, blur: 30, color: cyan.withAlphaComponent(0.6).cgColor)
    cg.addPath(hull)
    cg.setFillColor(NSColor.white.cgColor)
    cg.fillPath()
    cg.restoreGState()
    cg.saveGState()
    cg.addPath(hull)
    cg.clip()
    let shade = CGGradient(colorsSpace: nil, colors: [
        NSColor(white: 1, alpha: 1).cgColor, NSColor(red: 0.72, green: 0.78, blue: 0.9, alpha: 1).cgColor,
    ] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(shade, start: CGPoint(x: -20, y: 0), end: CGPoint(x: 60, y: 0), options: [.drawsBeforeStartLocation])
    // Nose cone band
    cg.setFillColor(NSColor(red: 1, green: 0.25, blue: 0.45, alpha: 1).cgColor)
    cg.fill(CGRect(x: -70, y: 150, width: 140, height: 80))
    cg.restoreGState()

    // Porthole
    cg.setFillColor(NSColor(red: 0.08, green: 0.1, blue: 0.2, alpha: 1).cgColor)
    cg.fillEllipse(in: CGRect(x: -32, y: 30, width: 64, height: 64))
    cg.setFillColor(cyan.cgColor)
    cg.fillEllipse(in: CGRect(x: -22, y: 40, width: 44, height: 44))
    cg.setFillColor(NSColor.white.withAlphaComponent(0.8).cgColor)
    cg.fillEllipse(in: CGRect(x: -12, y: 60, width: 14, height: 14))
    cg.restoreGState()

    // Glass sheen across the top of the squircle
    let sheen = CGGradient(colorsSpace: nil, colors: [
        NSColor.white.withAlphaComponent(0.10).cgColor, NSColor.white.withAlphaComponent(0).cgColor,
    ] as CFArray, locations: [0, 1])!
    cg.drawLinearGradient(sheen, start: CGPoint(x: 0, y: 924), end: CGPoint(x: 0, y: 600), options: [])
    cg.restoreGState()

    cg.addPath(squircle)
    cg.setStrokeColor(NSColor.white.withAlphaComponent(0.12).cgColor)
    cg.setLineWidth(3)
    cg.strokePath()
}

let dir = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let iconset = dir.appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for pt in [16, 32, 128, 256, 512] {
    try! render(pt).write(to: iconset.appendingPathComponent("icon_\(pt)x\(pt).png"))
    try! render(pt * 2).write(to: iconset.appendingPathComponent("icon_\(pt)x\(pt)@2x.png"))
}
try! render(1024).write(to: dir.appendingPathComponent("AppIcon.png"))

let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", dir.appendingPathComponent("AppIcon.icns").path]
try! p.run()
p.waitUntilExit()
try? FileManager.default.removeItem(at: iconset)
print(p.terminationStatus == 0 ? "✓ wrote \(dir.path)/AppIcon.icns" : "✗ iconutil failed")
