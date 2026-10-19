import SwiftUI

struct HeroView: View {
    @Environment(\.palette) private var palette
    @ObservedObject var store: WeatherStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let temp = store.temperature.map { store.displayTemp($0) }
        let accent = store.accent

        ZStack(alignment: .topLeading) {
            MascotView(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: 6, y: 18)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 2) {
                    Text(temp.map { "\($0)" } ?? WeatherMessages.missingValue)
                        .font(Theme.font(84, .ultraLight))
                        .tracking(-4)
                        .monospacedDigit()
                        .foregroundStyle(palette.foreground)
                        .contentTransition(.numericText(value: Double(temp ?? 0)))
                    Text("°")
                        .font(Theme.font(34, .ultraLight))
                        .foregroundStyle(palette.mute)
                        .padding(.top, 12)
                }
                .frame(height: 84)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.45), value: temp)

                Text(store.conditionTitle)
                    .font(Theme.font(17, .semibold))
                    .foregroundStyle(accent)
                    .contentTransition(.opacity)
                    .padding(.top, 10)
                    .animation(.easeInOut(duration: reduceMotion ? 0.2 : 0.8), value: store.accent)
                    .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.4), value: store.conditionTitle)

                HStack(spacing: 10) {
                    Text("\(WeatherMessages.lowPrefix) \(store.tempText(store.low))").foregroundStyle(Theme.low)
                    Text("\(WeatherMessages.highPrefix) \(store.tempText(store.high))").foregroundStyle(Theme.high)
                }
                .font(Theme.font(13, .medium))
                .padding(.top, 6)

                Text(store.captionText)
                    .font(Theme.font(12.5))
                    .lineSpacing(1.5)
                    .foregroundStyle(palette.mute)
                    .contentTransition(.opacity)
                    .frame(width: 124, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeInOut(duration: reduceMotion ? 0.15 : 0.4), value: store.captionText)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if store.cityManager.cities.count > 1 {
                CityPager(store: store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .offset(x: -2, y: 22)
            }
        }
    }
}