import SwiftUI
import AppKit

enum MascotLoader {
    struct Prepared {
        let image: NSImage
        let aspect: CGFloat
    }

    static let referenceWidth: CGFloat = 176
    private static var cache: [String: Prepared] = [:]

    static func prepared(forAsset name: String) -> Prepared {
        if let hit = cache[name] { return hit }
        let result = build(name)
        cache[name] = result
        return result
    }

    static var referenceBox: CGSize {
        let reference = WeatherCondition.sunny.mascotAsset(for: .day)
        return CGSize(width: referenceWidth, height: referenceWidth / prepared(forAsset: reference).aspect)
    }

    static func displaySize(forAsset name: String) -> CGSize {
        let box = referenceBox
        let aspect = prepared(forAsset: name).aspect
        let width = min(max((box.width * box.height * aspect).squareRoot(), box.width * 0.8), box.width * 1.3)
        return CGSize(width: width, height: width / aspect)
    }

    private static func build(_ name: String) -> Prepared {
        let source = NSImage(named: NSImage.Name(name))
            ?? NSImage(named: NSImage.Name(WeatherCondition.sunny.mascotAsset(for: .day)))
            ?? NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: nil)
            ?? NSImage()
        if let cg = source.cgImage(forProposedRect: nil, context: nil, hints: nil),
           let rect = opaqueBounds(of: cg),
           let cropped = cg.cropping(to: rect) {
            let image = NSImage(cgImage: cropped, size: NSSize(width: cropped.width, height: cropped.height))
            return Prepared(image: image, aspect: CGFloat(cropped.width) / CGFloat(max(cropped.height, 1)))
        }
        return Prepared(image: source, aspect: source.size.width / max(source.size.height, 1))
    }

    private static func opaqueBounds(of image: CGImage) -> CGRect? {
        let scale = min(1, 256 / Double(max(image.width, image.height)))
        let w = max(1, Int(Double(image.width) * scale))
        let h = max(1, Int(Double(image.height) * scale))
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        var bounds: (minX: Int, minY: Int, maxX: Int, maxY: Int) = (w, h, -1, -1)

        pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                          bytesPerRow: w * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            let bytes = buffer.bindMemory(to: UInt8.self)
            for y in 0..<h {
                for x in 0..<w where bytes[(y * w + x) * 4 + 3] > 10 {
                    bounds.minX = min(bounds.minX, x); bounds.maxX = max(bounds.maxX, x)
                    bounds.minY = min(bounds.minY, y); bounds.maxY = max(bounds.maxY, y)
                }
            }
        }
        guard bounds.maxX >= bounds.minX, bounds.maxY >= bounds.minY else { return nil }

        let sx = Double(image.width) / Double(w)
        let sy = Double(image.height) / Double(h)
        let rect = CGRect(x: Double(bounds.minX) * sx - sx, y: Double(bounds.minY) * sy - sy,
                          width: Double(bounds.maxX - bounds.minX + 1) * sx + 2 * sx,
                          height: Double(bounds.maxY - bounds.minY + 1) * sy + 2 * sy)
        return rect.integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
    }
}

struct CatMotion {
    var rotation = 0.0
    var scaleX = 1.0
    var scaleY = 1.0
    var offsetX = 0.0
    var offsetY = 0.0

    init() {}

    init(condition: WeatherCondition, phase: DayPhase, time t: Double) {
        func pulse(_ period: Double) -> Double { (1 - cos(2 * Double.pi * t / period)) / 2 }
        switch condition {
        case .sunny where phase == .night:
            let f = pulse(5.5); scaleX = 1 + 0.015 * f; scaleY = 1 - 0.012 * f
        case .sunny:
            rotation = -1.6 * cos(2 * Double.pi * t / 6)
        case .cloudy:
            let f = pulse(5.5); scaleX = 1 + 0.015 * f; scaleY = 1 - 0.012 * f
        case .rain:
            let f = pulse(3.2); scaleX = 1 + 0.02 * f; scaleY = 1 - 0.025 * f
        case .snow:
            offsetY = -6 * pulse(2.8)
        case .storm:
            offsetX = 1.1 * sin(2 * Double.pi * 6.5 * t)
        case .fog:
            let f = pulse(4.5); scaleX = 1 + 0.015 * f; scaleY = 1 - 0.012 * f
        }
    }
}

struct GlowView: View {
    let accent: Color
    let time: Double

    var body: some View {
        let f = (1 - cos(2 * Double.pi * time / 6)) / 2
        Circle()
            .fill(accent)
            .mask {
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.26), location: 0),
                        .init(color: Color.white.opacity(0.15), location: 0.26),
                        .init(color: Color.white.opacity(0.07), location: 0.46),
                        .init(color: Color.white.opacity(0.02), location: 0.64),
                        .init(color: Color.white.opacity(0), location: 0.78)
                    ]),
                    center: .center, startRadius: 0, endRadius: 240)
            }
            .scaleEffect(1 + 0.07 * f)
            .opacity(1 - 0.25 * f)
    }
}

struct MascotView: View {
    @ObservedObject var store: WeatherStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var popped = false
    @State private var recentTaps: [Date] = []
    @State private var showerCount = 0

    var body: some View {
        let condition = store.condition
        let phase = store.dayPhase
        let asset = store.mascotAssetName
        let prepared = MascotLoader.prepared(forAsset: asset)
        let box = MascotLoader.referenceBox
        let size = MascotLoader.displaySize(forAsset: asset)

        MotionTimeline(.regular) { time in
            let motion = reduceMotion ? CatMotion() : CatMotion(condition: condition, phase: phase, time: time)

            ZStack(alignment: .top) {
                GlowView(accent: store.accent, time: time)
                    .frame(width: 340, height: 340)
                    .offset(y: box.height * 0.56 - 170)

                Ellipse()
                    .fill(RadialGradient(colors: [Color.black.opacity(0.14), Color.black.opacity(0)],
                                         center: .center, startRadius: 0, endRadius: 80))
                    .frame(width: 160, height: 18)
                    .offset(y: box.height - 12)

                ZStack(alignment: .bottomTrailing) {
                    Image(nsImage: prepared.image)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: size.width, height: size.height)
                        .id(asset)
                        .transition(.opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.94, anchor: .bottom)))
                }
                .frame(width: box.width, height: box.height, alignment: .bottomTrailing)
                .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.4), value: asset)
                .shadow(color: Color.black.opacity(0.14), radius: 6, x: 0, y: 12)
                .rotationEffect(.degrees(motion.rotation), anchor: .bottom)
                .scaleEffect(x: motion.scaleX * (popped ? 0.94 : 1),
                             y: motion.scaleY * (popped ? 1.05 : 1),
                             anchor: .bottom)
                .offset(x: motion.offsetX, y: motion.offsetY)
            }
            .frame(width: box.width, height: box.height, alignment: .top)
        }
        .frame(width: box.width, height: box.height)
        .contentShape(Rectangle())
        .onTapGesture {
            store.mascotTapped()
            triggerPop()
            registerTap()
        }
        .overlay(alignment: .top) {
            HeartShower(trigger: showerCount, reduceMotion: reduceMotion)
                .offset(y: 30)
        }
        .onChange(of: store.mascotAssetName) { triggerPop() }
        .accessibilityLabel(WeatherMessages.mascotAccessibility)
        .accessibilityAddTraits(.isButton)
    }

    private func registerTap() {
        let now = Date()
        recentTaps = recentTaps.filter { now.timeIntervalSince($0) < 3 } + [now]
        if recentTaps.count >= 5 {
            recentTaps = []
            showerCount += 1
        }
    }

    private func triggerPop() {
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.12)) { popped = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.interpolatingSpring(stiffness: 220, damping: 9)) { popped = false }
        }
    }
}

struct HeartShower: View {
    let trigger: Int
    let reduceMotion: Bool

    @State private var start: Date?

    private struct Heart {
        let dx: CGFloat, rise: CGFloat, size: CGFloat, delay: Double, sway: CGFloat
    }

    private static let hearts: [Heart] = [
        Heart(dx: -46, rise: 96, size: 11, delay: 0.00, sway: 6),
        Heart(dx: 38, rise: 118, size: 14, delay: 0.12, sway: -7),
        Heart(dx: -14, rise: 128, size: 9, delay: 0.24, sway: 5),
        Heart(dx: 58, rise: 84, size: 10, delay: 0.34, sway: -5),
        Heart(dx: -62, rise: 112, size: 13, delay: 0.46, sway: 7),
        Heart(dx: 14, rise: 104, size: 12, delay: 0.58, sway: -6),
        Heart(dx: -30, rise: 138, size: 10, delay: 0.70, sway: 6),
        Heart(dx: 46, rise: 132, size: 9, delay: 0.82, sway: -4),
        Heart(dx: 0, rise: 150, size: 15, delay: 0.94, sway: 5)
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: start == nil)) { timeline in
            ZStack {
                if let start = start {
                    ForEach(Self.hearts.indices, id: \.self) { index in
                        let heart = Self.hearts[index]
                        let progress = min(max((timeline.date.timeIntervalSince(start) - heart.delay) / 2.2, 0), 1)
                        Image(systemName: "heart.fill")
                            .font(.system(size: heart.size))
                            .foregroundStyle(Color(hex: 0xf2707a))
                            .scaleEffect(0.6 + 0.4 * CGFloat(min(progress * 4, 1)))
                            .offset(x: heart.dx + heart.sway * CGFloat(sin(progress * 6)),
                                    y: -heart.rise * CGFloat(1 - pow(1 - progress, 2)))
                            .opacity(progress <= 0 ? 0 : 0.9 * sin(progress * Double.pi))
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) {
            guard !reduceMotion else { return }
            start = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
                if let started = start, Date().timeIntervalSince(started) >= 3.3 { start = nil }
            }
        }
    }
}