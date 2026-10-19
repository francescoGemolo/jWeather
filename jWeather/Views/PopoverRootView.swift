import SwiftUI

final class PopoverModel: ObservableObject {
    @Published var caretX: CGFloat = 170
    @Published var appeared = false
}

struct PopoverRootView: View {
    @ObservedObject var store: WeatherStore
    @ObservedObject var model: PopoverModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let isNight = store.dayPhase == .night
        WeatherWidgetView(store: store, caretX: model.caretX)
            .frame(width: Theme.panelWidth)
            .modifier(NightPalette(night: isNight ? 1 : 0, systemIsDark: colorScheme == .dark))
            .animation(.easeInOut(duration: reduceMotion ? 0.25 : SkyTiming.dayNight), value: isNight)
            .environment(\.widgetVisible, model.appeared)
            .scaleEffect(model.appeared || reduceMotion ? 1 : 0.96,
                         anchor: UnitPoint(x: model.caretX / Theme.panelWidth, y: 0))
            .opacity(model.appeared ? 1 : 0)
            .animation(.easeOut(duration: reduceMotion ? 0.15 : 0.3), value: model.appeared)
    }
}

struct PopoverShape: Shape {
    static let caretHeight: CGFloat = 8
    static let caretWidth: CGFloat = 16

    var caretX: CGFloat
    var radius: CGFloat = Theme.panelRadius

    func path(in rect: CGRect) -> Path {
        let top = rect.minY + Self.caretHeight
        let half = Self.caretWidth / 2
        let x = min(max(caretX, radius + half + 2), rect.width - radius - half - 2)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + radius, y: top))
        path.addLine(to: CGPoint(x: x - half, y: top))
        path.addLine(to: CGPoint(x: x - 2.4, y: rect.minY + 1.2))
        path.addQuadCurve(to: CGPoint(x: x + 2.4, y: rect.minY + 1.2), control: CGPoint(x: x, y: rect.minY - 0.6))
        path.addLine(to: CGPoint(x: x + half, y: top))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: top))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: top), tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: radius)
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: radius)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: top), radius: radius)
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: top), tangent2End: CGPoint(x: rect.midX, y: top), radius: radius)
        path.closeSubpath()
        return path
    }
}