import SwiftUI

/// Superhero style inspired by a friendly neighbourhood wall-crawler: webs spread in from the
/// screen corners and the card swings in on a web line. Join zips it away; anything else snaps the line.
struct WebSlingerView: View {
    let meeting: Meeting
    let onAction: (OverlayAction) -> Void

    private let red = Color(red: 0.92, green: 0.14, blue: 0.18)
    private let blue = Color(red: 0.22, green: 0.42, blue: 0.96)

    var body: some View {
        HeroStage(meeting: meeting, primary: red, accent: blue, kicker: "SENSES TINGLING", onAction: onAction) { f in
            let anchor = CGPoint(x: f.size.width / 2, y: -20)
            let pos = cardPosition(f, anchor: anchor)
            ZStack {
                WebCorners(t: f.t, size: f.size)
                    .opacity(f.fade())
                WebLine(anchor: anchor, end: pos, reach: lineReach(f))
                f.card
                    .rotationEffect(.radians(swing(f.t) * 0.3 + tumble(f)))
                    .position(pos)
                ComicPop(text: "THWIP!", fill: red, size: 38)
                    .rotationEffect(.degrees(-10))
                    .scaleEffect(max(0.01, easeOutBack(seg(f.t, 0.05, 0.3))))
                    .opacity(1 - seg(f.t, 1.0, 0.3))
                    .position(x: f.size.width / 2 + 180, y: 110)
            }
        }
    }

    /// A damped pendulum: the card drops in high from the left and settles into a gentle sway.
    private func swing(_ t: Double) -> Double {
        -1.45 * exp(-0.85 * t) * cos(2.4 * t) + 0.03 * sin(1.3 * t)
    }

    private func cardPosition(_ f: HeroFrame, anchor: CGPoint) -> CGPoint {
        let length = f.size.height * 0.53
        let a = swing(f.t)
        var p = CGPoint(x: anchor.x + length * CGFloat(sin(a)), y: anchor.y + length * CGFloat(cos(a)))
        if let c = f.closing {
            // Join: zipped up and away. Otherwise the line snaps and the card drops.
            p.y += CGFloat((f.action == .join ? -2600.0 : 2600.0) * c * c)
        }
        return p
    }

    private func lineReach(_ f: HeroFrame) -> Double {
        guard let c = f.closing, f.action != .join else { return 1 }
        return max(0, 0.5 - c * 1.5)
    }

    private func tumble(_ f: HeroFrame) -> Double {
        guard let c = f.closing, f.action != .join else { return 0 }
        return c * 2.5
    }
}

private struct WebLine: View {
    let anchor: CGPoint
    let end: CGPoint
    let reach: Double

    var body: some View {
        Canvas { ctx, _ in
            guard reach > 0 else { return }
            let k = CGFloat(reach)
            let tip = CGPoint(x: anchor.x + (end.x - anchor.x) * k, y: anchor.y + (end.y - anchor.y) * k)
            var line = Path()
            line.move(to: anchor)
            line.addLine(to: tip)
            ctx.stroke(line, with: .color(.white.opacity(0.25)), lineWidth: 7)
            ctx.stroke(line, with: .color(.white.opacity(0.95)), lineWidth: 2)
        }
        .allowsHitTesting(false)
    }
}

/// Spider-webs that spin out from each screen corner.
private struct WebCorners: View {
    let t: Double
    let size: CGSize

    var body: some View {
        Canvas { ctx, _ in
            let corners: [(CGPoint, CGFloat, CGFloat, Double, CGFloat)] = [
                (CGPoint(x: 0, y: 0), 1, 1, 0.05, 400),
                (CGPoint(x: size.width, y: 0), -1, 1, 0.2, 400),
                (CGPoint(x: 0, y: size.height), 1, -1, 0.35, 280),
                (CGPoint(x: size.width, y: size.height), -1, -1, 0.5, 280),
            ]
            let strands = 9
            let step = Double.pi / 2 / Double(strands - 1)
            for (o, sx, sy, delay, maxReach) in corners {
                let grow = easeOutCubic(seg(t, delay, 0.6))
                guard grow > 0 else { continue }
                let reach = maxReach * CGFloat(grow)
                func at(_ a: Double, _ r: CGFloat) -> CGPoint {
                    CGPoint(x: o.x + sx * r * CGFloat(cos(a)), y: o.y + sy * r * CGFloat(sin(a)))
                }
                var web = Path()
                for i in 0..<strands {
                    web.move(to: o)
                    web.addLine(to: at(Double(i) * step, reach))
                }
                for k in 1...7 {
                    let r = reach * CGFloat(k) / 7.5
                    web.move(to: at(0, r))
                    for i in 1..<strands {
                        // Each ring segment sags toward the corner like real silk.
                        web.addQuadCurve(to: at(Double(i) * step, r), control: at((Double(i) - 0.5) * step, r * 0.86))
                    }
                }
                ctx.stroke(web, with: .color(.white.opacity(0.55)), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}
