import SwiftUI

/// Superhero style inspired by a caped detective's call sign: a night skyline appears, a searchlight
/// sweeps up and projects the countdown onto the clouds, and the card rises out of the city.
struct NightSignalView: View {
    let meeting: Meeting
    let onAction: (OverlayAction) -> Void

    private let yellow = Color(red: 1.0, green: 0.85, blue: 0.3)
    private let amber = Color(red: 1.0, green: 0.6, blue: 0.12)

    var body: some View {
        HeroStage(meeting: meeting, primary: yellow, accent: amber, kicker: "CITY NEEDS YOU IN", dim: 0.15,
                  onAction: onAction) { f in
            let spot = spotCenter(f)
            let light = lightLevel(f)
            let rise = easeOutCubic(seg(f.t, 1.0, 0.7))
            let drop = f.action == .join ? 0 : (1 - f.fade(0.5)) * 300
            ZStack {
                NightCity(t: f.t, size: f.size, spot: spot, light: light, yellow: yellow, amber: amber)
                    .opacity(f.fade(0.7))
                Text(f.countdown)
                    .font(.system(size: 54, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.black.opacity(0.82))
                    .blur(radius: 0.8)
                    .opacity(seg(f.t, 1.1, 0.3) * light * f.fade(0.5))
                    .position(spot)
                    .allowsHitTesting(false)
                f.card
                    .opacity(rise * f.fade(0.4))
                    .position(x: f.center.x, y: f.size.height * 0.6 + CGFloat((1 - rise) * 420 + drop))
            }
        }
    }

    /// Where the searchlight hits the clouds: sweeps in from the top-left, then sways gently.
    private func spotCenter(_ f: HeroFrame) -> CGPoint {
        let p = CGFloat(easeOutCubic(seg(f.t, 0.2, 1.1)))
        let from = CGPoint(x: f.size.width * 0.08, y: f.size.height * 0.06)
        let to = CGPoint(x: f.size.width * 0.5, y: f.size.height * 0.2)
        return CGPoint(x: from.x + (to.x - from.x) * p + CGFloat(sin(f.t * 0.8) * 6),
                       y: from.y + (to.y - from.y) * p + CGFloat(cos(f.t * 0.6) * 3))
    }

    /// The lamp sputters on, and sputters off when dismissed.
    private func lightLevel(_ f: HeroFrame) -> Double {
        if let c = f.closing, f.action != .join {
            return c < 0.18 ? (hash01(Int(c * 50), 5) > 0.5 ? 1 : 0.2) : 0
        }
        if f.t < 0.15 { return 0 }
        if f.t < 0.4 { return hash01(Int(f.t * 30), 6) > 0.4 ? 1 : 0.15 }
        return 1
    }
}

private struct NightCity: View {
    let t: Double
    let size: CGSize
    let spot: CGPoint
    let light: Double
    let yellow: Color
    let amber: Color

    var body: some View {
        Canvas { ctx, _ in
            let w = size.width, h = size.height
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [Color(red: 0.02, green: 0.03, blue: 0.09).opacity(0.93),
                                  Color(red: 0.06, green: 0.05, blue: 0.12).opacity(0.82)]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: h)))

            // Stars and moon.
            for i in 0..<70 {
                let p = CGPoint(x: CGFloat(hash01(i, 51)) * w, y: CGFloat(hash01(i, 52)) * h * 0.55)
                let twinkle = 0.3 + 0.7 * abs(sin(t * (0.5 + hash01(i, 53) * 2) + Double(i)))
                ctx.fill(dot(p, CGFloat(1 + hash01(i, 54))), with: .color(.white.opacity(0.5 * twinkle)))
            }
            let moon = CGPoint(x: w * 0.86, y: h * 0.13)
            ctx.drawLayer { g in
                g.addFilter(.blur(radius: 30))
                g.fill(dot(moon, 70), with: .color(.white.opacity(0.18)))
            }
            ctx.fill(dot(moon, 38), with: .color(Color(red: 0.92, green: 0.92, blue: 0.85).opacity(0.85)))

            // Searchlights: a second lamp sweeps the sky; the main one holds the signal.
            let roam = CGPoint(x: w * 0.75 + CGFloat(sin(t * 0.45)) * w * 0.35, y: h * 0.02)
            beam(ctx, from: CGPoint(x: w * 0.78, y: h + 20), to: roam, spread: 60, alpha: 0.35 * light)
            beam(ctx, from: CGPoint(x: w * 0.3, y: h + 20), to: spot, spread: 150, alpha: light)

            // Low clouds, lit up where the beam hits them.
            ctx.drawLayer { g in
                g.addFilter(.blur(radius: 30))
                for i in 0..<22 {
                    let c = CGPoint(x: CGFloat(hash01(i, 55)) * w + CGFloat(sin(t * 0.12 + Double(i)) * 25),
                                    y: h * CGFloat(0.06 + hash01(i, 56) * 0.26))
                    let rw = CGFloat(200 + hash01(i, 57) * 240), rh = CGFloat(60 + hash01(i, 58) * 60)
                    let d = hypot(c.x - spot.x, c.y - spot.y) / 380
                    let lit = max(0, 1 - Double(d)) * light
                    let color = Color(red: 0.13 + lit * 0.5, green: 0.13 + lit * 0.4, blue: 0.18 + lit * 0.1)
                    g.fill(Path(ellipseIn: CGRect(x: c.x - rw / 2, y: c.y - rh / 2, width: rw, height: rh)),
                           with: .color(color.opacity(0.7)))
                }
            }

            // The signal itself.
            if light > 0 {
                let glow = CGRect(x: spot.x - 190, y: spot.y - 105, width: 380, height: 210)
                ctx.drawLayer { g in
                    g.addFilter(.blur(radius: 30))
                    g.fill(Path(ellipseIn: glow), with: .color(yellow.opacity(0.5 * light)))
                }
                let disc = CGRect(x: spot.x - 165, y: spot.y - 92, width: 330, height: 184)
                ctx.fill(Path(ellipseIn: disc), with: .radialGradient(
                    Gradient(colors: [yellow.opacity(0.95 * light), amber.opacity(0.7 * light)]),
                    center: spot, startRadius: 0, endRadius: 170))
            }

            skyline(ctx, w: w, h: h)
        }
        .allowsHitTesting(false)
    }

    private func beam(_ ctx: GraphicsContext, from src: CGPoint, to dst: CGPoint, spread: CGFloat, alpha: Double) {
        guard alpha > 0 else { return }
        let dx = dst.x - src.x, dy = dst.y - src.y
        let len = max(1, hypot(dx, dy))
        let nx = -dy / len, ny = dx / len
        var cone = Path()
        cone.move(to: CGPoint(x: src.x + nx * 14, y: src.y + ny * 14))
        cone.addLine(to: CGPoint(x: dst.x + nx * spread, y: dst.y + ny * spread))
        cone.addLine(to: CGPoint(x: dst.x - nx * spread, y: dst.y - ny * spread))
        cone.addLine(to: CGPoint(x: src.x - nx * 14, y: src.y - ny * 14))
        cone.closeSubpath()
        ctx.drawLayer { g in
            g.addFilter(.blur(radius: 10))
            g.blendMode = .plusLighter
            g.fill(cone, with: .linearGradient(
                Gradient(colors: [yellow.opacity(0.5 * alpha), yellow.opacity(0.08 * alpha)]),
                startPoint: src, endPoint: dst))
        }
    }

    /// Building silhouettes with lit windows (a few flick on and off) and blinking antenna lights.
    private func skyline(_ ctx: GraphicsContext, w: CGFloat, h: CGFloat) {
        let building = Color(red: 0.015, green: 0.015, blue: 0.03)
        var windows = Path()
        var beacons = Path()
        var x: CGFloat = -10
        var b = 0
        while x < w + 10 {
            let bw = CGFloat(40 + hash01(b, 61) * 80)
            let bh = h * CGFloat(0.12 + hash01(b, 62) * 0.22)
            let top = h - bh
            ctx.fill(Path(CGRect(x: x, y: top, width: bw, height: bh)), with: .color(building))
            if hash01(b, 63) > 0.7 {
                var mast = Path()
                mast.move(to: CGPoint(x: x + bw / 2, y: top))
                mast.addLine(to: CGPoint(x: x + bw / 2, y: top - 30))
                ctx.stroke(mast, with: .color(building), lineWidth: 2)
                if Int(t * 1.5 + Double(b)) % 2 == 0 { beacons.addPath(dot(CGPoint(x: x + bw / 2, y: top - 31), 2.5)) }
            }
            var row = 0
            var wy = top + 10
            while wy < h - 8 {
                var col = 0
                var wx = x + 6
                while wx < x + bw - 10 {
                    let on = hash01(b * 1000 + row, col + 7) > 0.72
                    let flick = hash01(b * 31 + row * 7 + col, Int(t / 3)) > 0.08
                    if on && flick { windows.addRect(CGRect(x: wx, y: wy, width: 5, height: 7)) }
                    wx += 12
                    col += 1
                }
                wy += 16
                row += 1
            }
            x += bw + 2
            b += 1
        }
        ctx.fill(windows, with: .color(yellow.opacity(0.55)))
        ctx.fill(beacons, with: .color(.red))
    }
}
