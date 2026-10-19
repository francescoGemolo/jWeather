import SwiftUI

struct TestToolsSheet: View {
    @ObservedObject var store: WeatherStore
    @Environment(\.palette) private var palette

    private var seed: SimulationState {
        store.simulation ?? SimulationState(condition: store.condition,
                                            intensity: store.intensity,
                                            isNight: store.dayPhase == .night)
    }

    private var isSimulating: Binding<Bool> {
        Binding(get: { store.simulation != nil },
                set: { store.setSimulation($0 ? seed : nil) })
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<SimulationState, Value>) -> Binding<Value> {
        Binding(get: { seed[keyPath: keyPath] },
                set: { value in
                    var state = seed
                    state[keyPath: keyPath] = value
                    store.setSimulation(state)
                })
    }

    var body: some View {
        VStack(spacing: 10) {
            SheetHandle(store: store)

            HStack {
                Text(WeatherMessages.testToolsTitle)
                    .font(Theme.font(11, .medium))
                    .tracking(0.4)
                    .foregroundStyle(palette.mute)
                Spacer(minLength: 8)
                Picker("", selection: isSimulating) {
                    Text(WeatherMessages.sourceReal).tag(false)
                    Text(WeatherMessages.sourceSimulated).tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 150)
                .padding(.trailing, 34)
            }

            HStack(spacing: 4) {
                ForEach(WeatherCondition.allCases) { condition in
                    conditionButton(condition)
                }
            }

            HStack(spacing: 8) {
                Picker("", selection: binding(\.intensity)) {
                    ForEach(WeatherIntensity.allCases, id: \.self) { level in
                        Text(WeatherMessages.intensityName(level)).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)

                Picker("", selection: binding(\.isNight)) {
                    Text(WeatherMessages.dayName).tag(false)
                    Text(WeatherMessages.nightName).tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 128)
            }

            Picker("", selection: binding(\.network)) {
                ForEach(SimulatedNetwork.allCases, id: \.self) { network in
                    Text(WeatherMessages.networkName(network)).tag(network)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .controlSize(.small)
        }
        .sheetChrome(store: store, dragToClose: false, translucent: true)
    }

    private func conditionButton(_ condition: WeatherCondition) -> some View {
        let selected = store.condition == condition
        return Button {
            var state = seed
            state.condition = condition
            store.setSimulation(state)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: condition.symbolName(for: store.dayPhase))
                    .font(.system(size: 15))
                Text(condition.label)
                    .font(Theme.font(9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundStyle(selected ? Color.white : palette.foreground)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(selected ? condition.accent : palette.chipFill))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.25), value: selected)
        .accessibilityLabel(condition.label)
    }
}