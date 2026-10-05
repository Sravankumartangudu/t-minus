import SwiftUI

/// Superhero style inspired by a star-spangled super-soldier: a spinning round shield ricochets
/// off the screen edges with sparks, lands, and the card unfolds beneath it.
struct StarShieldView: View {
    let meeting: Meeting
    let onAction: (OverlayAction) -> Void

    private let red = Color(red: 0.84, green: 0.13, blue: 0.16)
    private let blue = Color(red: 0.16, green: 0.3, blue: 0.78)

    var body: some View {
        HeroStage(meeting: meeting, primary: red, accent: blue, kicker: "ASSEMBLE IN", dim: 0.5,
                  onAction: onAction) { f in
            let cardCenter = CGPoint(x: f.center.x, y: f.size.height * 0.56)
            let emerge = easeOutBack(seg(f.t, 1.3, 0.5))
            ZStack {
                Canvas { ctx, size in
                    let full = Path(CGRect(origin: .zero, size: size))
                    ctx.fill(full, with: .radialGradient(Gradient(colors: [red.opacity(0.28), .clear]),
                                                         center: CGPoint(x: 0, y: size.height), startRadius: 0, endRadius: size.width * 0.6))
                    ctx.fill(full, with: .radialGradient(Gradient(colors: [blue.opacity(0.28), .clear]),
                                                         center: CGPoint(x: size.width, y: 0), startRadius: 0, endRadius: size.width * 0.6))
                }
                .opacity(f.fade())
                .allowsHitTesting(false)
                f.card
                    .scaleEffect(max(0.01, emerge), anchor: .top)
                    .opacity(seg(f.t, 1.3, 0.2) * f.fade(0.4))
                    .position(cardCenter)
                ShieldFlight(t: f.t, size: f.size, rest: CGPoint(x: cardCenter.x, y: cardCenter.y - 200),
                             closing: f.closing, joined: f.action == .join, red: red, blue: blue)
            }
        }
    }
}

private struct ShieldFlight: View {
    let t: Double
    let size: CGSize
    let rest: CGPoint
    let closing: Double?
    let joined: Bool
    let red: Color
    let blue: Color

    private let r0: CGFloat = 80
    private let landing = 1.35

    /// Ricochet points and the time the shield reaches each one.
    private var hits: [(CGPoint, Double)] {
        [(CGPoint(x: -120, y: size.height * 0.28), 0),
         (CGPoint(x: size.width - r0, y: size.height * 0.12), 0.42),
         (CGPoint(x: r0, y: size.height * 0.66), 0.86),
         (rest, landing)]
    }

    var body: some View {
        Canvas { ctx, _ in
            let c = closing ?? 0
            let leaving = closing != nil && joined
            let alpha = closing != nil && !joined ? max(0, 1 - c / 0.4) : 1
            let r = r0 - (r0 - 58) * CGFloat(easeOutCubic(seg(t, 1.2, 0.4)))

            // Motion trail while flying (or when thrown off on join).
            if t < landing + 0.05 || leaving {
                for k in stride(from: 6, through: 1, by: -1) {
                    let dt = Double(k) * 0.025
                    let p = position(at: t - dt, leaving: leaving ? max(0, c - dt) : nil)
                    ctx.fill(dot(p, r * 0.95), with: .color(red.opacity(0.2 * (1 - Double(k) / 7) * alpha)))
                }
            }

            // Sparks where it clangs off each edge and when it lands.
            for (i, hit) in hits.dropFirst().enumerated() {
                let age = t - hit.1
                guard age > 0, age < 0.35 else { continue }
                var sparks = Path()
                for s in 0..<22 {
                    let a = hash01(i * 50 + s, 111) * 2 * .pi
                    let d1 = r0 * 0.9 + CGFloat(age * 500 * (0.5 + hash01(i * 50 + s, 112)))
                    let d2 = d1 + 18
                    sparks.move(to: CGPoint(x: hit.0.x + d1 * CGFloat(cos(a)), y: hit.0.y + d1 * CGFloat(sin(a))))
                    sparks.addLine(to: CGPoint(x: hit.0.x + d2 * CGFloat(cos(a)), y: hit.0.y + d2 * CGFloat(sin(a))))
                }
                ctx.stroke(sparks, with: .color(Color(red: 1, green: 0.95, blue: 0.7).opacity(1 - age / 0.35)), lineWidth: 2)
            }

            let spin = (t < landing ? t * 13 : landing * 13 + (1 - exp(-(t - landing) * 4)) * 3.2) + (leaving ? c * 25 : 0)
            drawShield(ctx, at: position(at: t, leaving: leaving ? c : nil), radius: r, angle: spin, alpha: alpha)
        }
        .allowsHitTesting(false)
    }

    private func position(at time: Double, leaving c: Double?) -> CGPoint {
        var p = rest
        let pts = hits
        if time <= 0 {
            p = pts[0].0
        } else if time < landing {
            for i in 1..<pts.count where time <= pts[i].1 {
                let (a, ta) = pts[i - 1], (b, tb) = pts[i]
                var u = (time - ta) / (tb - ta)
                if i == pts.count - 1 { u = easeOutCubic(u) }
                p = CGPoint(x: a.x + (b.x - a.x) * CGFloat(u), y: a.y + (b.y - a.y) * CGFloat(u))
                break
            }
        } else {
            p.y += CGFloat(sin(time * 1.6) * 3 * seg(time, landing, 0.5))
        }
        if let c {
            // Join: the shield is thrown off toward the top-right corner.
            p.x += CGFloat(1800 * c)
            p.y -= CGFloat(1800 * c)
        }
        return p
    }

    private func drawShield(_ ctx: GraphicsContext, at p: CGPoint, radius r: CGFloat, angle: Double, alpha: Double) {
        var g = ctx
        g.opacity = alpha
        g.drawLayer { s in
            s.addFilter(.blur(radius: 18))
            s.fill(dot(p, r * 1.05), with: .color(blue.opacity(0.6)))
        }
        let silver = Color(white: 0.93)
        g.fill(dot(p, r), with: .color(red))
        g.fill(dot(p, r * 0.8), with: .color(silver))
        g.fill(dot(p, r * 0.6), with: .color(red))
        g.fill(dot(p, r * 0.4), with: .color(blue))
        g.fill(star(at: p, outer: r * 0.38, inner: r * 0.15, angle: angle), with: .color(silver))

        // A glint that rides around the rim so the spin reads clearly.
        var glint = Path()
        glint.addArc(center: p, radius: r * 0.7, startAngle: .radians(angle), endAngle: .radians(angle + 0.7), clockwise: false)
        g.stroke(glint, with: .color(.white.opacity(0.7)), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        g.fill(dot(p, r), with: .linearGradient(
            Gradient(colors: [.white.opacity(0.35), .clear, .black.opacity(0.25)]),
            startPoint: CGPoint(x: p.x - r, y: p.y - r), endPoint: CGPoint(x: p.x + r, y: p.y + r)))
        g.stroke(dot(p, r), with: .color(.black.opacity(0.4)), lineWidth: 2)
    }

    private func star(at c: CGPoint, outer: CGFloat, inner: CGFloat, angle: Double) -> Path {
        var p = Path()
        for i in 0..<10 {
            let a = angle - .pi / 2 + Double(i) * .pi / 5
            let rr = i % 2 == 0 ? outer : inner
            let pt = CGPoint(x: c.x + rr * CGFloat(cos(a)), y: c.y + rr * CGFloat(sin(a)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}
