import Foundation

enum SimulatedNetwork: CaseIterable {
    case online, offline, error
}

struct SimulationState: Equatable {
    var condition: WeatherCondition
    var intensity: WeatherIntensity
    var isNight: Bool
    var network: SimulatedNetwork = .online
}

enum Simulator {
    private static let codes: [WeatherCondition: [Int]] = [
        .sunny: [0, 0, 0],
        .cloudy: [2, 3, 3],
        .fog: [45, 45, 45],
        .rain: [51, 63, 65],
        .snow: [71, 73, 75],
        .storm: [95, 95, 99]
    ]

    private static let baseTemperature: [WeatherCondition: Int] = [
        .sunny: 24, .cloudy: 18, .fog: 8, .rain: 13, .snow: -1, .storm: 17
    ]

    static func snapshot(for city: City, state: SimulationState, now: Date = Date()) -> WeatherSnapshot {
        let hour: TimeInterval = 3600
        let code = codes[state.condition]?[state.intensity.rawValue] ?? 0
        let base = (baseTemperature[state.condition] ?? 18) - (state.isNight ? 5 : 0)
        let wet = state.condition == .rain || state.condition == .storm || state.condition == .snow
        let sun: [SunInterval] = state.isNight
            ? [SunInterval(sunrise: now.addingTimeInterval(-18 * hour), sunset: now.addingTimeInterval(-6 * hour)),
               SunInterval(sunrise: now.addingTimeInterval(6 * hour), sunset: now.addingTimeInterval(18 * hour))]
            : [SunInterval(sunrise: now.addingTimeInterval(-6 * hour), sunset: now.addingTimeInterval(6 * hour)),
               SunInterval(sunrise: now.addingTimeInterval(18 * hour), sunset: now.addingTimeInterval(30 * hour))]
        let hourly = (0..<6).map {
            HourlyPoint(time: now.addingTimeInterval(Double($0) * hour),
                        temperature: base - $0 / 2,
                        precipitationChance: wet ? 80 : 10)
        }
        return WeatherSnapshot(cityID: city.id,
                               fetchedAt: now,
                               timeZoneID: city.timezone ?? TimeZone.current.identifier,
                               weatherCode: code,
                               temperature: base,
                               feelsLike: base - 1,
                               humidity: state.condition == .fog ? 96 : (wet ? 88 : 55),
                               windKmh: state.condition == .storm ? 28 : (wet ? 14 : 9),
                               precipitationChance: wet ? 80 : 10,
                               high: base + 3,
                               low: base - 4,
                               uvIndexMax: state.condition == .sunny && !state.isNight ? 7 : 2,
                               hourly: hourly,
                               sun: sun)
    }
}