import SwiftUI

struct SheetHost: View {
    @ObservedObject var store: WeatherStore

    var body: some View {
        ZStack(alignment: .bottom) {
            if let sheet = store.activeSheet {
                if sheet != .test {
                    Color.black.opacity(0.25)
                        .transition(.opacity)
                        .onTapGesture { store.activeSheet = nil }
                }
                Group {
                    switch sheet {
                    case .hourly: HourlySheet(store: store)
                    case .cities: CitiesSheet(store: store)
                    case .test: TestToolsSheet(store: store)
                    }
                }
                .transition(.move(edge: .bottom))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .animation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.5), value: store.activeSheet)
    }
}

struct HourlySheet: View {
    @Environment(\.palette) private var palette
    @ObservedObject var store: WeatherStore

    var body: some View {
        let points = store.hourlyPoints
        let temps = points.compactMap { $0.temperature }
        let minTemp = temps.min() ?? 0
        let accent = store.accent

        VStack(spacing: 0) {
            SheetHandle(store: store)

            Text(WeatherMessages.nextHoursTitle)
                .font(Theme.font(11, .medium))
                .tracking(0.4)
                .foregroundStyle(palette.mute)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 12)

            if points.isEmpty {
                Text(WeatherMessages.noHourlyData)
                    .font(Theme.font(13))
                    .foregroundStyle(palette.mute)
                    .frame(maxWidth: .infinity, minHeight: 96)
            } else {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(points.indices, id: \.self) { index in
                        let point = points[index]
                        VStack(spacing: 6) {
                            Text(store.tempText(point.temperature))
                                .font(Theme.font(15))
                                .foregroundStyle(palette.foreground)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(index == 0 ? accent : palette.line)
                                .frame(width: 5, height: min(12 + CGFloat((point.temperature ?? minTemp) - minTemp) * 8, 52))
                            Text(index == 0 ? WeatherMessages.nowLabel : store.timeString(point.time))
                                .font(Theme.font(11))
                                .foregroundStyle(palette.mute)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 96, alignment: .bottom)
            }

            StatsRow(items: [
                StatItem(label: WeatherMessages.uvIndex, value: store.plainText(store.uvIndex)),
                StatItem(label: WeatherMessages.rainChance, value: store.percentText(store.rainChance)),
                StatItem(label: WeatherMessages.sunset, value: store.sunsetText)
            ])
            .padding(.top, 12)
            .overlay(alignment: .top) { Rectangle().fill(palette.line).frame(height: 1) }
            .padding(.top, 16)
        }
        .sheetChrome(store: store)
    }
}