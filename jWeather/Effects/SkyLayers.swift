import SwiftUI

struct SunLayer: View {
    private struct Mote {
        let x: Double, phase: Double, speed: Double, sway: Double, radius: Double, twinkle: Double
    }

    private static let motes: [Mote] = {
        var random = SeededRandom(seed: 1012202606)
        return (0..<9).map { _ in
            Mote(x: random.next(), phase: random.next(), speed: 5 + random.next() * 6,
                 sway: 6 + random.next() * 10, radius: 1 + random.next() * 1.3, twinkle: 0.4 + random.next() * 0.6)
        }
    }()

    var body: some View {
        MotionTimeline(.relaxed) { time in
            Canvas { context, size in
                let width = Double(size.width)
                let height = Double(size.height)
                let ox = width - 14
                let oy = -10.0
                let origin = CGPoint(x: ox, y: oy)

                let light = 0.86 + 0.09 * wave(time, period: 9) + 0.05 * wave(time, period: 23, phase: 1)
                let glowRadius = 240.0
                context.fill(discPath(x: ox, y: oy, radius: glowRadius),
                             with: .radialGradient(Gradient(colors: [Theme.sun.opacity(0.30 * light),
                                                                     Theme.sun.opacity(0.10 * light),
                                                                     Theme.sun.opacity(0)]),
                                                   center: origin, startRadius: 0, endRadius: glowRadius))

                let rotation = time * 2 * Double.pi / 240
                for index in 0..<10 {
                    let k = Double(index)
                    let angle = rotation + k * 2 * Double.pi / 10
                    let breathe = 0.5 + 0.5 * wave(time, period: 11 + k * 1.7, phase: k * 1.3)
                    let length = 360 + 50 * wave(time, period: 17 + k, phase: k)
                    let alpha = 0.13 * (0.35 + 0.65 * breathe)
                    let tip = CGPoint(x: ox + cos(angle) * length, y: oy + sin(angle) * length)
                    for (half, factor) in [(0.075, 0.4), (0.033, 1.0)] {
                        var path = Path()
                        path.move(to: origin)
                        path.addLine(to: CGPoint(x: ox + cos(angle - half) * length, y: oy + sin(angle - half) * length))
                        path.addLine(to: CGPoint(x: ox + cos(angle + half) * length, y: oy + sin(angle + half) * length))
                        path.closeSubpath()
                        context.fill(path, with: .linearGradient(Gradient(colors: [Theme.sun.opacity(alpha * factor),
                                                                                   Theme.sun.opacity(0)]),
                                                                 startPoint: origin, endPoint: tip))
                    }
                }

                let coreRadius = 62.0 * (1 + 0.05 * wave(time, period: 6))
                context.fill(discPath(x: ox, y: oy, radius: coreRadius),
                             with: .radialGradient(Gradient(colors: [Color.white.opacity(0.9),
                                                                     Theme.sun.opacity(0.55),
                                                                     Theme.sun.opacity(0)]),
                                                   center: origin, startRadius: 0, endRadius: coreRadius))

                let travel = height * 0.8
                for (index, mote) in Self.motes.enumerated() {
                    let progress = positiveMod(mote.phase + time * mote.speed / travel, 1)
                    let y = height * 0.9 - progress * travel
                    let x = mote.x * width + mote.sway * sin(time * 0.4 + Double(index))
                    let alpha = 0.4 * sin(progress * Double.pi) * (0.6 + 0.4 * sin(time * mote.twinkle * 2 + Double(index)))
                    context.fill(discPath(x: x, y: y, radius: mote.radius),
                                 with: .color(Theme.sun.opacity(max(alpha, 0))))
                }
            }
        }
    }
}

struct MoonLayer: View {
    var body: some View {
        MotionTimeline(.relaxed) { time in
            Canvas { context, size in
                let x = Double(size.width) - 54
                let y = 88.0
                let breathe = 0.85 + 0.15 * wave(time, period: 12)
                let glowRadius = 78.0
                context.fill(discPath(x: x, y: y, radius: glowRadius),
                             with: .radialGradient(Gradient(colors: [Theme.moon.opacity(0.22 * breathe),
                                                                     Theme.moon.opacity(0.08 * breathe),
                                                                     Theme.moon.opacity(0)]),
                                                   center: CGPoint(x: x, y: y), startRadius: 0, endRadius: glowRadius))

                var mask = Path(CGRect(origin: .zero, size: size))
                mask.addPath(discPath(x: x + 7, y: y - 4, radius: 13))
                var crescent = context
                crescent.clip(to: mask, style: FillStyle(eoFill: true))
                crescent.fill(discPath(x: x, y: y, radius: 15), with: .color(Theme.moon.opacity(0.95)))
            }
        }
    }
}

struct StarsLayer: View {
    private struct Star {
        let x: Double, y: Double, size: Double, speed: Double, phase: Double
    }

    private static let stars: [Star] = {
        var random = SeededRandom(seed: 20261012)
        return (0..<26).map { _ in
            Star(x: random.next(), y: random.next() * 0.62, size: 1.0 + random.next() * 1.6,
                 speed: 0.4 + random.next() * 0.9, phase: random.next() * 6.28)
        }
    }()

    private static let shootingInterval = 18.0

    var body: some View {
        MotionTimeline(.relaxed) { time in
            Canvas { context, size in
                let width = Double(size.width)
                let height = Double(size.height)
                for star in Self.stars {
                    let twinkle = 0.45 + 0.55 * (0.5 + 0.5 * sin(time * star.speed + star.phase))
                    let x = star.x * width
                    let y = star.y * height
                    context.fill(discPath(x: x, y: y, radius: star.size * 1.5),
                                 with: .color(Color.white.opacity(0.10 * twinkle)))
                    context.fill(discPath(x: x, y: y, radius: star.size / 2),
                                 with: .color(Color.white.opacity(0.85 * twinkle)))
                }

                let slot = Int(floor(time / Self.shootingInterval))
                let start = Double(slot) * Self.shootingInterval + 4 + unitHash(slot, salt: 5) * 9
                let age = time - start
                if age >= 0, age < 0.9 {
                    let progress = age / 0.9
                    let x0 = width * (0.1 + 0.5 * unitHash(slot, salt: 6))
                    let y0 = 20 + 60 * unitHash(slot, salt: 7)
                    let head = CGPoint(x: x0 + 90 * progress, y: y0 + 45 * progress)
                    let tail = CGPoint(x: head.x - 28, y: head.y - 14)
                    var path = Path()
                    path.move(to: tail)
                    path.addLine(to: head)
                    let fade = sin(progress * Double.pi)
                    context.stroke(path,
                                   with: .linearGradient(Gradient(colors: [Color.white.opacity(0), Color.white.opacity(0.9 * fade)]),
                                                         startPoint: tail, endPoint: head),
                                   style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                }
            }
        }
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 240
        let sy = rect.height / 100
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy)
        }
        var path = Path()
        path.move(to: p(34, 84))
        path.addCurve(to: p(22, 52), control1: p(12, 84), control2: p(4, 62))
        path.addCurve(to: p(56, 34), control1: p(18, 34), control2: p(40, 24))
        path.addCurve(to: p(112, 22), control1: p(62, 12), control2: p(94, 4))
        path.addCurve(to: p(168, 36), control1: p(128, 6), control2: p(162, 12))
        path.addCurve(to: p(210, 60), control1: p(190, 26), control2: p(216, 40))
        path.addCurve(to: p(212, 86), control1: p(232, 62), control2: p(236, 84))
        path.addCurve(to: p(34, 84), control1: p(160, 92), control2: p(90, 92))
        path.closeSubpath()
        return path
    }
}

private struct CloudSpec {
    let width: Double
    let top: Double
    let period: Double
    let phase: Double
    let bobPeriod: Double
    let opacity: Double

    static let all = [
        CloudSpec(width: 139, top: 66, period: 34, phase: 0.15, bobPeriod: 9, opacity: 1),
        CloudSpec(width: 102, top: 128, period: 44, phase: 0.55, bobPeriod: 12, opacity: 1),
        CloudSpec(width: 190, top: 28, period: 70, phase: 0.80, bobPeriod: 15, opacity: 0.6),
        CloudSpec(width: 84, top: 190, period: 52, phase: 0.30, bobPeriod: 11, opacity: 0.85)
    ]
}

private struct CloudBand: View {
    let spec: CloudSpec
    let time: Double
    let shade: Double
    @Environment(\.palette) private var palette

    var body: some View {
        let height = spec.width * 100 / 240
        let high = palette.cloudHigh.darkened(shade).color
        let low = palette.cloudLow.darkened(shade).color
        Canvas { context, size in
            let travel = Double(size.width) + spec.width
            let progress = positiveMod(time / spec.period + spec.phase, 1)
            let x = -spec.width + travel * progress
            let bob = 2 * (1 - cos(2 * Double.pi * time / spec.bobPeriod))
            let rect = CGRect(x: x, y: 6 + bob, width: spec.width, height: height)
            let path = CloudShape().path(in: rect)
            context.fill(path.offsetBy(dx: 0, dy: 6), with: .color(Color.black.opacity(0.06)))
            context.fill(path, with: .linearGradient(Gradient(colors: [high, low]),
                                                     startPoint: CGPoint(x: rect.midX, y: rect.minY),
                                                     endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
            let highlight = CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.1,
                                   width: rect.width * 0.45, height: rect.height * 0.3)
            context.fillSoftEllipse(in: highlight, color: high, opacity: 0.7, steps: 6)
        }
        .frame(height: height + 28)
        .offset(y: spec.top)
        .opacity(spec.opacity)
    }
}

struct CloudsLayer: View, Animatable {
    let count: Int
    var shade: Double

    var animatableData: Double {
        get { shade }
        set { shade = newValue }
    }

    var body: some View {
        MotionTimeline(.relaxed) { time in
            ZStack(alignment: .topLeading) {
                ForEach(CloudSpec.all.indices, id: \.self) { index in
                    FadeLayer(active: index < count) {
                        CloudBand(spec: CloudSpec.all[index], time: time, shade: shade)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

struct FogLayer: View {
    private struct Veil {
        let y: Double, width: Double, height: Double, speed: Double, alpha: Double, phase: Double, swayPeriod: Double
    }

    private static let veils = [
        Veil(y: 0.20, width: 420, height: 92, speed: 9, alpha: 0.20, phase: 0.10, swayPeriod: 19),
        Veil(y: 0.38, width: 480, height: 112, speed: -6, alpha: 0.22, phase: 0.55, swayPeriod: 23),
        Veil(y: 0.55, width: 440, height: 100, speed: 12, alpha: 0.20, phase: 0.80, swayPeriod: 17),
        Veil(y: 0.72, width: 520, height: 120, speed: -8, alpha: 0.24, phase: 0.30, swayPeriod: 29),
        Veil(y: 0.90, width: 400, height: 92, speed: 5, alpha: 0.18, phase: 0.65, swayPeriod: 21)
    ]

    @Environment(\.palette) private var palette

    var body: some View {
        let fog = palette.fog
        MotionTimeline(.relaxed) { time in
            Canvas { context, size in
                let width = Double(size.width)
                let height = Double(size.height)
                for (index, veil) in Self.veils.enumerated() {
                    let k = Double(index)
                    let span = width + veil.width
                    let centerX = positiveMod(veil.phase * span + veil.speed * time, span) - veil.width / 2
                    let centerY = height * veil.y + 7 * wave(time, period: veil.swayPeriod, phase: k)
                    let alpha = veil.alpha * (0.8 + 0.2 * wave(time, period: veil.swayPeriod * 1.3, phase: k * 1.7))
                    let rect = CGRect(x: centerX - veil.width / 2, y: centerY - veil.height / 2,
                                      width: veil.width, height: veil.height)
                    context.fillSoftEllipse(in: rect, color: fog, opacity: alpha, steps: 12)
                }
            }
        }
    }
}