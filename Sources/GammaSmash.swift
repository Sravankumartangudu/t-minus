import SwiftUI

/// Superhero style inspired by a certain big green rage monster: the card gets hurled at your
/// screen, the glass cracks, shards fly, and a "SMASH!" burst pops up.
struct GammaSmashView: View {
    let meeting: Meeting
    let onAction: (OverlayAction) -> Void

    private let green = Color(red: 0.45, green: 0.92, blue: 0.25)
    private let purple = Color(red: 0.62, green: 0.32, blue: 0.9)
    private let impact = 0.28

    var body: some View {
        HeroStage(meeting: meeting, primary: green, accent: purple, kicker: "SMASH TIME IN", dim: 0.5, exit: 0.5,
                  onAction: onAction) { f in
            let fly = seg(f.t, 0, impact)
            let quake = f.t > impact ? max(0, 1 - (f.t - impact) / 0.55) : 0
            let jx = (hash01(Int(f.t * 60), 1) - 0.5) * 34 * quake
            let jy = (hash01(Int(f.t * 60), 2) - 0.5) * 34 * quake
            // Join punches the card through the screen; anything else shrinks it away.
            let exitScale = f.action == .join ? 1 + (1 - f.fade(0.4)) * 0.5 : f.fade(0.4)
            ZStack {
                Cracks(t: f.t, impact: impact, center: f.center, green: green)
                    .opacity(f.fade(0.5))
                Debris(t: f.t, impact: impact, center: f.center, green: green)
                f.card
                    .scaleEffect(max(0.01, (3.2 - 2.2 * easeInCubic(fly)) * exitScale))
                    .rotationEffect(.degrees(12 * (1 - fly) - 2))
                    .opacity(min(1, fly * 3) * f.fade(0.4))
                    .position(f.center)
                ComicPop(text: "SMASH!", fill: green, size: 50)
                    .rotationEffect(.degrees(-12))
                    .scaleEffect(max(0.01, easeOutBack(seg(f.t, impact, 0.3))))
                    .opacity(f.fade(0.3))
                    .position(x: f.center.x + 230, y: f.center.y - 205)
            }
            .offset(x: jx, y: jy)
        }
    }
}

/// Radial cracks spreading out from the impact, joined by a few concentric fractures.
private struct Cracks: View {
    let t: Double
    let impact: Double
    let center: CGPoint
    let green: Color

    var body: some View {
        Canvas { ctx, size in
            // Pulsing gamma glow behind the card.
            let glow = (0.28 + 0.08 * sin(t * 4)) * min(1, t / impact)
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
                Gradient(colors: [green.opacity(glow), .clear]), center: center, startRadius: 100, endRadius: 650))

            let g = easeOutCubic(seg(t, impact, 0.3))
            guard g > 0 else { return }
            let rays = 22
            var lines = Path()
            var dirs: [CGVector] = []
            var lengths: [Double] = []
            for i in 0..<rays {
                let a = Double(i) / Double(rays) * 2 * .pi + (hash01(i, 71) - 0.5) * 0.22
                let d = CGVector(dx: cos(a), dy: sin(a))
                let full = 380 + hash01(i, 72) * 760
                dirs.append(d)
                lengths.append(full)
                let len = CGFloat(full * g)
                let start = CGPoint(x: center.x + d.dx * 120, y: center.y + d.dy * 120)
                let end = CGPoint(x: center.x + d.dx * len, y: center.y + d.dy * len)
                lines.addLines(jagged(from: start, to: end, segments: 9, roughness: 9, seed: i * 13))
            }
            for k in 0..<3 {
                let r = 210 + Double(k) * 170
                for i in 0..<rays where hash01(i, 80 + k) > 0.4 {
                    let j = (i + 1) % rays
                    guard lengths[i] * g > r, lengths[j] * g > r else { continue }
                    let r1 = CGFloat(r), r2 = CGFloat(r * (0.9 + hash01(i, 90 + k) * 0.2))
                    let p1 = CGPoint(x: center.x + dirs[i].dx * r1, y: center.y + dirs[i].dy * r1)
                    let p2 = CGPoint(x: center.x + dirs[j].dx * r2, y: center.y + dirs[j].dy * r2)
                    lines.addLines(jagged(from: p1, to: p2, segments: 4, roughness: 6, seed: i * 7 + k))
                }
            }
            var shadow = ctx
            shadow.translateBy(x: 1.5, y: 1.5)
            shadow.stroke(lines, with: .color(.black.opacity(0.6)), lineWidth: 2.5)
            ctx.stroke(lines, with: .color(.white.opacity(0.85)), lineWidth: 1.2)
        }
        .allowsHitTesting(false)
    }
}

/// Glass shards thrown outward from the impact, tumbling under gravity.
private struct Debris: View {
    let t: Double
    let impact: Double
    let center: CGPoint
    let green: Color

    var body: some View {
        Canvas { ctx, _ in
            let age = t - impact
            guard age > 0, age < 1.6 else { return }
            for i in 0..<60 {
                let a = hash01(i, 101) * 2 * .pi
                let start: Double = 140 + hash01(i, 103) * 120
                let speed: Double = 300 + hash01(i, 102) * 800
                let dist = CGFloat(start + speed * age)
                let x = center.x + CGFloat(cos(a)) * dist
                let y = center.y + CGFloat(sin(a)) * dist + CGFloat(1300 * age * age)
                let s = CGFloat(5 + hash01(i, 104) * 12)
                var g = ctx
                g.opacity = max(0, 1 - age / 1.6)
                g.translateBy(x: x, y: y)
                g.rotate(by: .radians(age * (3 + hash01(i, 105) * 9)))
                var shard = Path()
                shard.move(to: CGPoint(x: 0, y: -s))
                shard.addLine(to: CGPoint(x: s * 0.7, y: s * 0.6))
                shard.addLine(to: CGPoint(x: -s * 0.5, y: s * 0.4))
                shard.closeSubpath()
                g.fill(shard, with: .color(i % 4 == 0 ? green : .white.opacity(0.8)))
            }
        }
        .allowsHitTesting(false)
    }
}
