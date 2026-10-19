import SwiftUI

struct Particle {
    let x: Double
    let y: Double
    let depth: Double
    let phase: Double
    let jitter: Double

    static func buckets(count: Int, seed: UInt64) -> [[Particle]] {
        var random = SeededRandom(seed: seed)
        var result: [[Particle]] = [[], [], []]
        for _ in 0..<count {
            let particle = Particle(x: random.next(), y: random.next(), depth: random.next(),
                                    phase: random.next() * 2 * Double.pi, jitter: random.next())
            result[min(2, Int(particle.depth * 3))].append(particle)
        }
        return result
    }
}

struct StreakField {
    let count: Int
    let speed: ClosedRange<Double>
    let length: ClosedRange<Double>
    let width: ClosedRange<Double>
    let alpha: ClosedRange<Double>
    let slope: Double
    let gust: Double
    let buckets: [[Particle]]

    init(count: Int, speed: ClosedRange<Double>, length: ClosedRange<Double>, width: ClosedRange<Double>,
         alpha: ClosedRange<Double>, slope: Double, gust: Double, seed: UInt64) {
        self.count = count
        self.speed = speed
        self.length = length
        self.width = width
        self.alpha = alpha
        self.slope = slope
        self.gust = gust
        buckets = Particle.buckets(count: count, seed: seed)
    }

    private static let lightRain = StreakField(count: 36, speed: 380...560, length: 9...15, width: 0.7...1.0,
                                               alpha: 0.12...0.26, slope: 0.04, gust: 0.015, seed: 11)
    private static let moderateRain = StreakField(count: 78, speed: 560...900, length: 12...22, width: 0.8...1.3,
                                                  alpha: 0.16...0.34, slope: 0.09, gust: 0.03, seed: 12)
    private static let heavyRain = StreakField(count: 130, speed: 820...1300, length: 16...32, width: 0.9...1.7,
                                               alpha: 0.20...0.42, slope: 0.20, gust: 0.06, seed: 13)
    private static let moderateStorm = StreakField(count: 110, speed: 850...1350, length: 16...30, width: 0.9...1.6,
                                                   alpha: 0.20...0.40, slope: 0.28, gust: 0.10, seed: 14)
    private static let heavyStorm = StreakField(count: 160, speed: 1000...1600, length: 18...36, width: 1.0...1.9,
                                                alpha: 0.22...0.46, slope: 0.38, gust: 0.14, seed: 15)

    static func rain(_ level: WeatherIntensity) -> StreakField {
        switch level {
        case .light: return lightRain
        case .moderate: return moderateRain
        case .heavy: return heavyRain
        }
    }

    static func storm(_ level: WeatherIntensity) -> StreakField {
        level == .heavy ? heavyStorm : moderateStorm
    }

    func draw(in context: inout GraphicsContext, size: CGSize, time: Double, color: Color) {
        let width = Double(size.width)
        let height = Double(size.height)
        let gustRate = 0.7
        let slopeNow = slope + gust * sin(gustRate * time)
        let drift = slope * time - (gust / gustRate) * (cos(gustRate * time) - 1)
        let spanX = width + 120

        for (index, bucket) in buckets.enumerated() {
            let middle = (Double(index) + 0.5) / 3
            let length = lerp(self.length, middle)
            let spanY = height + 2 * length
            var path = Path()
            for particle in bucket {
                let speed = lerp(self.speed, particle.depth) * (0.92 + 0.16 * particle.jitter)
                let y = positiveMod(particle.y * spanY + speed * time, spanY) - length
                let x = positiveMod(particle.x * spanX - speed * drift, spanX) - 60
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + length * slopeNow, y: y - length))
            }
            context.stroke(path,
                           with: .color(color.opacity(lerp(alpha, middle))),
                           style: StrokeStyle(lineWidth: CGFloat(lerp(self.width, middle)), lineCap: .round))
        }
    }
}

struct FlakeField {
    let fall: ClosedRange<Double>
    let radius: ClosedRange<Double>
    let sway: ClosedRange<Double>
    let wind: Double
    let gust: Double
    let buckets: [[Particle]]

    init(count: Int, fall: ClosedRange<Double>, radius: ClosedRange<Double>, sway: ClosedRange<Double>,
         wind: Double, gust: Double, seed: UInt64) {
        self.fall = fall
        self.radius = radius
        self.sway = sway
        self.wind = wind
        self.gust = gust
        buckets = Particle.buckets(count: count, seed: seed)
    }

    private static let light = FlakeField(count: 34, fall: 14...34, radius: 1.0...2.3, sway: 6...14,
                                          wind: 3, gust: 4, seed: 21)
    private static let moderate = FlakeField(count: 62, fall: 22...52, radius: 1.1...2.8, sway: 8...20,
                                             wind: 9, gust: 10, seed: 22)
    private static let heavy = FlakeField(count: 112, fall: 34...84, radius: 1.1...3.2, sway: 10...26,
                                          wind: 20, gust: 18, seed: 23)

    static func snow(_ level: WeatherIntensity) -> FlakeField {
        switch level {
        case .light: return light
        case .moderate: return moderate
        case .heavy: return heavy
        }
    }

    func draw(in context: inout GraphicsContext, size: CGSize, time: Double, color: Color) {
        let width = Double(size.width)
        let height = Double(size.height)
        let spanX = width + 80
        let spanY = height + 20
        let gustRate = 0.3
        let windOffset = wind * time + (gust / gustRate) * sin(gustRate * time)
        var crystals = Path()

        for (index, bucket) in buckets.enumerated() {
            var halos = Path()
            var cores = Path()
            for flake in bucket {
                let depth = flake.depth
                let radius = lerp(self.radius, depth)
                let speed = lerp(fall, depth) * (0.85 + 0.3 * flake.jitter)
                let y = positiveMod(flake.y * spanY + speed * time, spanY) - 10
                let swing = lerp(sway, depth) * sin((0.4 + 0.8 * flake.jitter) * time + flake.phase)
                let x = positiveMod(flake.x * spanX + swing + windOffset * (0.4 + 0.6 * depth), spanX) - 40
                halos.addEllipse(in: CGRect(x: x - radius * 2.2, y: y - radius * 2.2, width: radius * 4.4, height: radius * 4.4))
                cores.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2))

                if depth > 0.85, flake.jitter > 0.45 {
                    let spin = time * (flake.jitter - 0.5) + flake.phase
                    let arm = radius * 2.6
                    for spoke in 0..<3 {
                        let angle = spin + Double(spoke) * Double.pi / 3
                        crystals.move(to: CGPoint(x: x - cos(angle) * arm, y: y - sin(angle) * arm))
                        crystals.addLine(to: CGPoint(x: x + cos(angle) * arm, y: y + sin(angle) * arm))
                    }
                }
            }
            let alpha = 0.26 + 0.15 * Double(index)
            context.fill(halos, with: .color(color.opacity(alpha * 0.22)))
            context.fill(cores, with: .color(color.opacity(alpha)))
        }
        context.stroke(crystals, with: .color(color.opacity(0.55)),
                       style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
    }
}

private extension Palette {
    func tinted(day: UInt32, night: UInt32) -> Color {
        Tone(day).mixed(with: Tone(night), darkness).color
    }
}

struct RainLayer: View {
    let level: WeatherIntensity
    @Environment(\.palette) private var palette

    var body: some View {
        let field = StreakField.rain(level)
        let color = palette.tinted(day: 0x2f7cf6, night: 0xa9c8ff)
        MotionTimeline(.fast) { time in
            Canvas { context, size in
                field.draw(in: &context, size: size, time: time, color: color)
            }
        }
    }
}

struct SnowLayer: View {
    let level: WeatherIntensity
    @Environment(\.palette) private var palette

    var body: some View {
        let field = FlakeField.snow(level)
        let color = palette.tinted(day: 0x43b8f0, night: 0xe6f2ff)
        MotionTimeline(.regular) { time in
            Canvas { context, size in
                field.draw(in: &context, size: size, time: time, color: color)
            }
        }
    }
}

struct StormLayer: View {
    let level: WeatherIntensity
    @Environment(\.palette) private var palette

    var body: some View {
        let field = StreakField.storm(level)
        let color = palette.tinted(day: 0x7b5cf5, night: 0xc2b3ff)
        MotionTimeline(.fast) { time in
            Canvas { context, size in
                field.draw(in: &context, size: size, time: time, color: color)
                Lightning.draw(in: &context, size: size, time: time, level: level)
            }
        }
    }
}

extension Lightning {
    static func draw(in context: inout GraphicsContext, size: CGSize, time: Double, level: WeatherIntensity) {
        guard let strike = current(at: time, level: level) else { return }
        let intensity = strike.level
        let width = Double(size.width)
        let height = Double(size.height)

        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: [Theme.bolt.opacity(0.34 * intensity), Theme.bolt.opacity(0)]),
                                           startPoint: .zero, endPoint: CGPoint(x: 0, y: height * 0.65)))
        guard strike.age < 0.24 else { return }

        var random = SeededRandom(seed: UInt64(truncatingIfNeeded: strike.seed) &* 7919 &+ 17)
        var x = width * (0.15 + 0.5 * random.next())
        var y = -4.0
        let endY = height * (0.38 + 0.2 * random.next())
        var path = Path()
        path.move(to: CGPoint(x: x, y: y))
        while y < endY {
            y += 16 + random.next() * 18
            x += (random.next() - 0.5) * 34
            path.addLine(to: CGPoint(x: x, y: y))
        }
        let style = { (lineWidth: CGFloat) in StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round) }
        context.stroke(path, with: .color(Theme.bolt.opacity(0.22 * intensity)), style: style(9))
        context.stroke(path, with: .color(Theme.bolt.opacity(0.5 * intensity)), style: style(3.5))
        context.stroke(path, with: .color(Color.white.opacity(intensity)), style: style(1.4))
    }
}