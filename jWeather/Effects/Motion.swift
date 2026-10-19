import SwiftUI

enum MotionRate: Double {
    case relaxed = 24
    case regular = 30
    case fast = 60
}

private struct WidgetVisibleKey: EnvironmentKey {
    static let defaultValue = true
}

extension EnvironmentValues {
    var widgetVisible: Bool {
        get { self[WidgetVisibleKey.self] }
        set { self[WidgetVisibleKey.self] = newValue }
    }
}

struct MotionTimeline<Content: View>: View {
    private let rate: MotionRate
    private let content: (Double) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.widgetVisible) private var widgetVisible

    init(_ rate: MotionRate, @ViewBuilder content: @escaping (Double) -> Content) {
        self.rate = rate
        self.content = content
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / rate.rawValue, paused: reduceMotion || !widgetVisible)) { timeline in
            content(reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate)
        }
    }
}

struct FadeLayer<Content: View>: View {
    private let active: Bool
    private let duration: Double
    private let content: () -> Content
    @State private var mounted: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(active: Bool, duration: Double = 1.0, @ViewBuilder content: @escaping () -> Content) {
        self.active = active
        self.duration = duration
        self.content = content
        _mounted = State(initialValue: active)
    }

    var body: some View {
        let seconds = reduceMotion ? 0.25 : duration
        ZStack {
            if mounted { content() }
        }
        .opacity(active ? 1 : 0)
        .animation(.easeInOut(duration: seconds), value: active)
        .allowsHitTesting(false)
        .task(id: active) {
            if active {
                mounted = true
            } else {
                try? await Task.sleep(nanoseconds: UInt64((seconds + 0.15) * 1_000_000_000))
                if !Task.isCancelled { mounted = false }
            }
        }
    }
}