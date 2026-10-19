import SwiftUI

struct WeatherWidgetView: View {
    @Environment(\.palette) private var palette
    @ObservedObject var store: WeatherStore
    var caretX: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            HeaderRow(store: store)
                .frame(height: 28)
                .zIndex(3)

            HeroView(store: store)
                .frame(height: 188)
                .padding(.top, 6)
                .zIndex(2)

            StatsRow(items: [
                StatItem(label: WeatherMessages.feelsLike, value: store.tempText(store.feelsLike)),
                StatItem(label: WeatherMessages.wind, value: store.windText(store.windKmh)),
                StatItem(label: WeatherMessages.humidity, value: store.percentText(store.humidity))
            ])
            .padding(.top, 48)
            .zIndex(1)

            Button(WeatherMessages.hourlyButton) { store.activeSheet = .hourly }
                .buttonStyle(AccentCTAStyle(accent: store.accent))
                .padding(.top, 16)
                .zIndex(1)
        }
        .padding(.top, 12 + PopoverShape.caretHeight)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .frame(width: Theme.panelWidth)
        .background { AtmosphereView(scene: store.scene, accent: store.accent) }
        .overlay { StormFlashOverlay(scene: store.scene) }
        .overlay { SheetHost(store: store) }
        .overlay(PopoverShape(caretX: caretX).stroke(palette.line, lineWidth: 2))
        .overlay(PopoverShape(caretX: caretX)
            .stroke(LinearGradient(colors: [palette.glassHighlight.opacity(0.7), Color.clear],
                                   startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.3)), lineWidth: 2)
            .allowsHitTesting(false))
        .clipShape(PopoverShape(caretX: caretX))
        .contentShape(Rectangle())
        .contextMenu {
            Button(WeatherMessages.menuRefresh) { store.refresh(.manual) }
            Button(WeatherMessages.menuTestTools) { store.toggleTestTools() }
        }
    }
}

struct HeaderRow: View {
    @Environment(\.palette) private var palette
    @ObservedObject var store: WeatherStore

    var body: some View {
        HStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Button { store.activeSheet = .cities } label: {
                    HStack(spacing: 4) {
                        Text(store.cityName)
                            .font(Theme.font(13, .semibold))
                            .foregroundStyle(palette.foreground)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(palette.mute)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .layoutPriority(1)
                .accessibilityLabel(WeatherMessages.changeCity)

                Text(store.headerSubtitle)
                    .font(Theme.font(13))
                    .foregroundStyle(palette.mute)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 4)
            HStack(spacing: 6) {
                UnitChip(store: store)
                QuitChip()
            }
        }
    }
}