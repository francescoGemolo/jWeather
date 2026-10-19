import SwiftUI
import AppKit

struct UnitChip: View {
    @Environment(\.palette) private var palette
    @ObservedObject var store: WeatherStore

    var body: some View {
        Button { store.useFahrenheit.toggle() } label: {
            Text(store.useFahrenheit ? WeatherMessages.fahrenheit : WeatherMessages.celsius)
                .font(Theme.font(12, .medium))
                .foregroundStyle(palette.foreground)
                .padding(.horizontal, 12)
                .frame(height: 26)
                .glassChip(Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(WeatherMessages.unitToggle)
    }
}

struct QuitChip: View {
    @Environment(\.palette) private var palette
    var body: some View {
        Button { NSApp.terminate(nil) } label: {
            Image(systemName: "power")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(palette.foreground.opacity(0.8))
                .frame(width: 26, height: 26)
                .glassChip(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(WeatherMessages.quitApp)
    }
}

struct CityPager: View {
    @Environment(\.palette) private var palette
    @ObservedObject var store: WeatherStore

    var body: some View {
        let accent = store.accent
        HStack(spacing: 6) {
            ForEach(store.cityManager.cities) { city in
                let isCurrent = city.id == store.cityManager.selectedID
                Capsule()
                    .fill(isCurrent ? accent : palette.line)
                    .frame(width: isCurrent ? 18 : 6, height: 6)
                    .contentShape(Rectangle().inset(by: -6))
                    .onTapGesture { store.selectCity(city) }
                    .accessibilityLabel(city.name)
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .glassChip(Capsule())
        .animation(.easeInOut(duration: 0.4), value: store.cityManager.selectedID)
    }
}

struct CloseButton: View {
    @Environment(\.palette) private var palette
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(palette.foreground.opacity(0.72))
                .frame(width: 28, height: 28)
                .glassChip(Circle())
                .frame(width: 42, height: 42)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(WeatherMessages.closeSheet)
    }
}

struct AccentCTAStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(15, .semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background {
                ZStack {
                    Capsule().fill(accent)
                    Capsule().fill(LinearGradient(stops: [.init(color: Color.white.opacity(0.10), location: 0),
                                                          .init(color: Color.white.opacity(0), location: 0.55)],
                                                  startPoint: .top, endPoint: .bottom))
                    Capsule().strokeBorder(LinearGradient(colors: [Color.white.opacity(0.14), Color.clear],
                                                          startPoint: .top, endPoint: .center), lineWidth: 1)
                }
            }
            .shadow(color: accent.opacity(0.18), radius: 5, x: 0, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .animation(.easeInOut(duration: 0.8), value: accent)
    }
}

struct SheetHandle: View {
    @Environment(\.palette) private var palette
    @ObservedObject var store: WeatherStore

    var body: some View {
        Capsule()
            .fill(palette.line)
            .frame(width: 36, height: 5)
            .padding(.bottom, 14)
            .contentShape(Rectangle().inset(by: -10))
            .onTapGesture { store.activeSheet = nil }
            .gesture(DragGesture(minimumDistance: 6).onEnded { value in
                if value.translation.height > 30 { store.activeSheet = nil }
            })
            .accessibilityLabel(WeatherMessages.closeSheet)
    }
}

struct SheetChrome: ViewModifier {
    @Environment(\.palette) private var palette
    @ObservedObject var store: WeatherStore
    let dragToClose: Bool
    let translucent: Bool

    func body(content: Content) -> some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 24, bottomLeadingRadius: 0,
                                           bottomTrailingRadius: 0, topTrailingRadius: 24,
                                           style: .continuous)
        content
            .padding(.top, 8)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .background {
                shape.fill(palette.sheet.opacity(translucent ? 0.86 : 1))
                    .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: -4)
            }
            .overlay(alignment: .topTrailing) {
                CloseButton { store.activeSheet = nil }
                    .padding(.top, 1)
                    .padding(.trailing, 7)
            }
            .gesture(DragGesture(minimumDistance: 10).onEnded { value in
                if value.translation.height > 50 { store.activeSheet = nil }
            }, including: dragToClose ? .all : .subviews)
    }
}

extension View {
    func sheetChrome(store: WeatherStore, dragToClose: Bool = true, translucent: Bool = false) -> some View {
        modifier(SheetChrome(store: store, dragToClose: dragToClose, translucent: translucent))
    }
}