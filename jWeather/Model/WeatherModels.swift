import Foundation

struct City: Codable, Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let country: String?
    let admin1: String?
    let latitude: Double
    let longitude: Double
    let timezone: String?

    var subtitle: String {
        [admin1, country].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
    }

    func isSame(as other: City) -> Bool {
        if id == other.id { return true }
        return name.caseInsensitiveCompare(other.name) == .orderedSame
            && abs(latitude - other.latitude) < 0.1
            && abs(longitude - other.longitude) < 0.1
    }
}

struct HourlyPoint: Codable, Equatable, Identifiable {
    let time: Date
    let temperature: Int?
    let precipitationChance: Int?
    var id: Date { time }
}

struct SunInterval: Codable, Equatable {
    let sunrise: Date
    let sunset: Date
}

struct WeatherSnapshot: Codable, Equatable {
    let cityID: String
    let fetchedAt: Date
    let timeZoneID: String
    let weatherCode: Int
    let temperature: Int?
    let feelsLike: Int?
    let humidity: Int?
    let windKmh: Int?
    let precipitationChance: Int?
    let high: Int?
    let low: Int?
    let uvIndexMax: Int?
    let hourly: [HourlyPoint]
    let sun: [SunInterval]?

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .current }
}

enum WeatherError: Error, Equatable {
    case offline
    case server
    case invalidData
}

enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(WeatherError)
}