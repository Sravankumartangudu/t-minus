import SwiftUI

/// Superhero style inspired by a hammer-wielding god of thunder: storm clouds roll in, rain
/// falls, and a lightning bolt slams the card down with a shockwave. Lightning keeps crackling.
struct ThunderGodView: View {
    let meeting: Meeting
    let onAction: (OverlayAction) -> Void

    private let bolt = Color(red: 0.5, green: 0.78, blue: 1.0)
    private let violet = Color(red: 0.72, green: 0.58, blue: 1.0)

    var body: some View {
        HeroStage(meeting: meeting, primary: bolt, accent: violet, kicker: "STORM ARRIVES IN", dim: 0.5, exit: 0.6,
                  onAction: onAction) { f in
            let target = CGPoint(x: f.center.x, y: f.size.height * 0.56)
            let drop = easeInCubic(seg(f.t, 0.32, 0.18))
            let quake = f.t >= 0.5 ? max(0, 1 - (f.t - 0.5) / 0.5) : 0
            let jx = (hash01(Int(f.t * 60), 1) - 0.5) * 28 * quake
            let jy = (hash01(Int(f.t * 60), 2) - 0.5) * 28 * quake
            ZStack {
                Storm(t: f.t, size: f.size, target: target, closing: f.closing, joined: f.action == .join,
                      bolt: bolt, violet: violet)
                    .opacity(f.action == .join ? 1 : f.fade(0.6))
                f.card
                    .opacity(f.t < 0.32 ? 0 : f.fade(0.4))
                    .position(x: target.x, y: target.y - CGFloat(1 - drop) * f.size.height * 0.9)
            }
            .offset(x: jx, y: jy)
        }
    }
}

private struct Storm: View {
    let t: Double
    let size: CGSize
    let target: CGPoint
    let closing: Double?
    let joined: Bool
    let bolt: Color
    let violet: Color

    var body: some View {
        Canvas { ctx, _ in
            let w = size.width, h = size.height
            let strike = currentStrike()
            let flash = strike.map { boltAlpha($0.age) * ($0.main ? 1 : 0.6) } ?? 0

            // Dark sky and drifting storm clouds, lit up by lightning.
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
                Gradient(colors: [Color(red: 0.03, green: 0.05, blue: 0.12).opacity(0.85), .clear]),
                startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.65)))
            ctx.drawLayer { g in
                g.addFilter(.blur(radius: 40))
                for i in 0..<26 {
                    let x = CGFloat(hash01(i, 21) * 1.2 - 0.1) * w + CGFloat(sin(t * 0.15 + Double(i)) * 30)
                    let y = CGFloat(hash01(i, 22)) * h * 0.22 - 40
                    let rw = CGFloat(220 + hash01(i, 23) * 260), rh = CGFloat(90 + hash01(i, 24) * 90)
                    let shade = 0.1 + hash01(i, 25) * 0.08 + flash * 0.3
                    g.fill(Path(ellipseIn: CGRect(x: x - rw / 2, y: y - rh / 2, width: rw, height: rh)),
                           with: .color(Color(red: shade, green: shade * 1.05, blue: min(1, shade * 1.35))))
                }
            }

            // Slanted rain.
            var rain = Path()
            for i in 0..<180 {
                let speed = 1300 + hash01(i, 31) * 700
                let x0 = CGFloat(hash01(i, 32)) * (w + 300)
                let span = Double(h) + 200
                let y = CGFloat((hash01(i, 33) * span + t * speed).truncatingRemainder(dividingBy: span) - 100)
                let x = x0 - y * 0.25
                rain.move(to: CGPoint(x: x, y: y))
                rain.addLine(to: CGPoint(x: x - 7, y: y - 28))
            }
            ctx.stroke(rain, with: .color(Color(red: 0.7, green: 0.8, blue: 1).opacity(0.28)), lineWidth: 1)

            // Lightning.
            if let s = strike {
                let a = boltAlpha(s.age)
                let parts = boltPaths(seed: s.seed, main: s.main)
                ctx.drawLayer { g in
                    g.addFilter(.blur(radius: 14))
                    g.blendMode = .plusLighter
                    for (i, p) in parts.enumerated() {
                        g.stroke(polyline(p), with: .color(violet.opacity(a)), lineWidth: i == 0 ? 14 : 6)
                    }
                }
                for (i, p) in parts.enumerated() {
                    ctx.stroke(polyline(p), with: .color(.white.opacity(a)),
                               style: StrokeStyle(lineWidth: i == 0 ? 3 : 1.5, lineCap: .round, lineJoin: .round))
                }
            }

            // Static crackling along the card's edges once it has landed.
            let tick = Int(t / 0.45)
            if t > 0.8, closing == nil, t - Double(tick) * 0.45 < 0.12 {
                var sparks = Path()
                for j in 0..<3 {
                    let s = tick * 7 + j
                    let (p, n) = edgePoint(hash01(s, 41), hash01(s, 42))
                    let out = CGFloat(50 + hash01(s, 43) * 70)
                    let end = CGPoint(x: p.x + n.dx * out + CGFloat(hash01(s, 44) - 0.5) * 40,
                                      y: p.y + n.dy * out + CGFloat(hash01(s, 45) - 0.5) * 40)
                    sparks.addLines(jagged(from: p, to: end, segments: 6, roughness: 9, seed: s))
                }
                ctx.drawLayer { g in
                    g.addFilter(.blur(radius: 5))
                    g.stroke(sparks, with: .color(bolt), lineWidth: 5)
                }
                ctx.stroke(sparks, with: .color(.white), lineWidth: 1.3)
            }

            // Shockwave rippling out from where the card lands.
            let sw = t - 0.5
            if sw > 0 && sw < 0.7 {
                let r = CGFloat(40 + sw / 0.7 * 620)
                let ground = CGPoint(x: target.x, y: target.y + 185)
                let ring = Path(ellipseIn: CGRect(x: ground.x - r, y: ground.y - r * 0.18, width: r * 2, height: r * 0.36))
                ctx.stroke(ring, with: .color(bolt.opacity(1 - sw / 0.7)), lineWidth: 4)
            }

            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(flash * 0.35)))
        }
        .allowsHitTesting(false)
    }

    /// The bolt on screen right now, if any.
    private func currentStrike() -> (seed: Int, age: Double, main: Bool)? {
        if let c = closing, joined { return (999, c, true) }
        if t >= 0.4 && t < 0.75 { return (1, t - 0.4, true) }
        guard t > 1.8 else { return nil }
        let period = 2.6
        let k = Int((t - 1.8) / period)
        let age = t - 1.8 - Double(k) * period
        return age < 0.35 ? (k + 2, age, false) : nil
    }

    /// Lightning flickers: bright, dim, bright again, then fades.
    private func boltAlpha(_ age: Double) -> Double {
        switch age {
        case ..<0.05: return 1
        case ..<0.09: return 0.25
        case ..<0.16: return 1
        default: return max(0, 1 - (age - 0.16) / 0.18)
        }
    }

    /// The trunk of a bolt plus a few side branches. Main strikes hit the top of the card.
    private func boltPaths(seed: Int, main: Bool) -> [[CGPoint]] {
        let w = size.width, h = size.height
        let start = main
            ? CGPoint(x: target.x + CGFloat(hash01(seed, 1) - 0.5) * 300, y: -10)
            : CGPoint(x: CGFloat(hash01(seed, 1)) * w, y: -10)
        let end = main
            ? CGPoint(x: target.x, y: target.y - 180)
            : CGPoint(x: CGFloat(hash01(seed, 2)) * w, y: h * CGFloat(0.35 + hash01(seed, 3) * 0.4))
        let trunk = jagged(from: start, to: end, segments: 22, roughness: 22, seed: seed * 97)
        var parts = [trunk]
        for b in 0..<3 {
            let from = trunk[5 + b * 5]
            let dir: CGFloat = hash01(seed, 10 + b) > 0.5 ? 1 : -1
            let to = CGPoint(x: from.x + dir * CGFloat(100 + hash01(seed, 20 + b) * 150),
                             y: from.y + CGFloat(90 + hash01(seed, 30 + b) * 120))
            parts.append(jagged(from: from, to: to, segments: 8, roughness: 12, seed: seed * 31 + b))
        }
        return parts
    }

    /// A point on the card's border (u picks the side, v the position along it) and its outward normal.
    private func edgePoint(_ u: Double, _ v: Double) -> (CGPoint, CGVector) {
        let hw: CGFloat = 222, hh: CGFloat = 182
        let v = CGFloat(v)
        switch Int(u * 4) {
        case 0: return (CGPoint(x: target.x - hw + v * 2 * hw, y: target.y - hh), CGVector(dx: 0, dy: -1))
        case 1: return (CGPoint(x: target.x + hw, y: target.y - hh + v * 2 * hh), CGVector(dx: 1, dy: 0))
        case 2: return (CGPoint(x: target.x - hw + v * 2 * hw, y: target.y + hh), CGVector(dx: 0, dy: 1))
        default: return (CGPoint(x: target.x - hw, y: target.y - hh + v * 2 * hh), CGVector(dx: -1, dy: 0))
        }
    }
}
