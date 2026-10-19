import SwiftUI

struct SkyScene: Equatable {
    let condition: WeatherCondition
    let intensity: WeatherIntensity
    let isNight: Bool
}

extension SkyScene {
    var sunStrength: Double {
        guard !isNight else { return 0 }
        switch condition {
        case .sunny: return 1
        case .cloudy: return intensity == .light ? 0.5 : 0
        default: return 0
        }
    }

    var moonStrength: Double {
        guard isNight else { return 0 }
        switch condition {
        case .sunny: return 1
        case .cloudy: return intensity == .light ? 0.6 : 0
        default: return 0
        }
    }

    var starsStrength: Double {
        guard isNight else { return 0 }
        switch condition {
        case .sunny: return 1
        case .cloudy: return intensity == .light ? 0.55 : 0
        default: return 0
        }
    }

    var cloudCount: Int {
        switch condition {
        case .sunny, .fog: return 0
        case .cloudy:
            switch intensity {
            case .light: return 2
            case .moderate: return 3
            case .heavy: return 4
            }
        case .rain: return intensity == .light ? 2 : (intensity == .moderate ? 3 : 4)
        case .snow: return 3
        case .storm: return 4
        }
    }

    var cloudShade: Double {
        switch condition {
        case .sunny, .fog, .snow: return 0
        case .cloudy: return intensity == .heavy ? 0.1 : (intensity == .moderate ? 0.04 : 0)
        case .rain: return intensity == .light ? 0.07 : (intensity == .moderate ? 0.14 : 0.22)
        case .storm: return 0.38
        }
    }

    var tintOpacity: Double {
        switch condition {
        case .sunny: return 0
        case .cloudy: return intensity == .light ? 0.14 : (intensity == .moderate ? 0.18 : 0.24)
        case .rain: return intensity == .light ? 0.16 : (intensity == .moderate ? 0.22 : 0.30)
        case .snow: return 0.22
        case .storm: return intensity == .heavy ? 0.5 : 0.4
        case .fog: return 0.2
        }
    }

    var stormLevel: WeatherIntensity {
        intensity == .heavy ? .heavy : .moderate
    }

    static func tint(for condition: WeatherCondition) -> Color {
        switch condition {
        case .sunny: return Color(hex: 0xffd98a)
        case .cloudy: return Color(hex: 0x8993a8)
        case .rain: return Color(hex: 0x30456b)
        case .snow: return Color(hex: 0xcfe8ff)
        case .storm: return Color(hex: 0x1b1442)
        case .fog: return Color(hex: 0xaab4c4)
        }
    }
}