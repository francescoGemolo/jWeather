import SwiftUI

enum WeatherIntensity: Int, CaseIterable {
    case light, moderate, heavy

    init(weatherCode code: Int) {
        switch code {
        case 1, 2, 51, 56, 61, 66, 71, 77, 80, 85:
            self = .light
        case 3, 55, 57, 65, 67, 75, 82, 86, 96, 99:
            self = .heavy
        default:
            self = .moderate
        }
    }
}

enum WeatherCondition: String, CaseIterable, Identifiable {
    case sunny, cloudy, rain, snow, storm, fog

    var id: String { rawValue }

    init(weatherCode code: Int) {
        switch code {
        case 0, 1: self = .sunny
        case 2, 3: self = .cloudy
        case 45, 48: self = .fog
        case 51...57, 61...67, 80...82: self = .rain
        case 71...77, 85, 86: self = .snow
        case 95...99: self = .storm
        default: self = .cloudy
        }
    }

    var label: String { WeatherMessages.conditionName(self) }

    func symbolName(for phase: DayPhase) -> String {
        switch self {
        case .sunny: return phase == .night ? "moon.stars" : "sun.max"
        case .cloudy: return phase == .night ? "cloud.moon" : "cloud"
        case .rain: return "cloud.rain"
        case .snow: return "snowflake"
        case .storm: return "cloud.bolt"
        case .fog: return "cloud.fog"
        }
    }

    func mascotAsset(for phase: DayPhase) -> String {
        switch self {
        case .sunny: return phase == .night ? "cat_4" : "cat_1"
        case .cloudy: return "cat_2"
        case .rain: return "cat_3"
        case .snow: return "cat_4"
        case .storm: return "cat_5"
        case .fog: return "cat_6"
        }
    }

    func accent(for phase: DayPhase) -> Color {
        if phase == .night, self == .sunny { return Color(hex: 0x7f86ff) }
        return accent
    }

    var accent: Color {
        switch self {
        case .sunny: return Color(hex: 0xff8a00)
        case .cloudy: return Color(hex: 0x6f7fa6)
        case .rain: return Color(hex: 0x2f7cf6)
        case .snow: return Color(hex: 0x43b8f0)
        case .storm: return Color(hex: 0x7b5cf5)
        case .fog: return Color(hex: 0x7f8ea3)
        }
    }
}