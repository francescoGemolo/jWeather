import SwiftUI

struct StatItem {
    let label: String
    let value: String
}

struct StatsRow: View {
    @Environment(\.palette) private var palette
    let items: [StatItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                StatCell(item: items[index])
                    .padding(.leading, index == 0 ? 0 : 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .leading) {
                        if index > 0 {
                            Rectangle().fill(palette.line).frame(width: 1)
                        }
                    }
            }
        }
    }
}

struct StatCell: View {
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let item: StatItem

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(item.label)
                .font(Theme.font(11))
                .tracking(0.2)
                .foregroundStyle(palette.mute)
            Text(item.value)
                .font(Theme.font(19, .light))
                .tracking(-0.3)
                .foregroundStyle(palette.foreground)
                .contentTransition(.numericText())
                .animation(reduceMotion ? nil : .easeOut(duration: 0.4), value: item.value)
        }
    }
}