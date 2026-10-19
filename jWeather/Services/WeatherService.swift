import Foundation

final class OpenMeteoService {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session = URLSession(configuration: configuration)
    }

    private struct Response: Decodable {
        struct Current: Decodable {
            let time: Int
            let temperature_2m: Double?
            let apparent_temperature: Double?
            let relative_humidity_2m: Double?
            let weather_code: Int?
            let wind_speed_10m: Double?
        }
        struct Hourly: Decodable {
            let time: [Int]
            let temperature_2m: [Double?]?
            let precipitation_probability: [Double?]?
        }
        struct Daily: Decodable {
            let temperature_2m_max: [Double?]?
            let temperature_2m_min: [Double?]?
            let uv_index_max: [Double?]?
            let sunrise: [Int?]?
            let sunset: [Int?]?
            let precipitation_probability_max: [Double?]?
        }
        let timezone: String?
        let current: Current
        let hourly: Hourly?
        let daily: Daily?
    }

    func fetch(for city: City) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(city.latitude)),
            URLQueryItem(name: "longitude", value: String(city.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,uv_index_max,sunrise,sunset,precipitation_probability_max"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "timeformat", value: "unixtime"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "forecast_days", value: "2")
        ]
        guard let url = components.url else { throw WeatherError.invalidData }
        let data = try await Networking.data(from: url, using: session)
        return try makeSnapshot(from: Networking.decode(Response.self, from: data), city: city)
    }

    private func makeSnapshot(from response: Response, city: City) throws -> WeatherSnapshot {
        guard let code = response.current.weather_code else { throw WeatherError.invalidData }

        func value(_ array: [Double?]?, _ index: Int) -> Double? {
            guard let array = array, index >= 0, index < array.count else { return nil }
            return array[index]
        }
        func rounded(_ number: Double?) -> Int? { number.map { Int($0.rounded()) } }

        let times = response.hourly?.time ?? []
        let now = response.current.time
        let start = times.firstIndex { $0 + 3600 > now } ?? 0
        var points: [HourlyPoint] = []
        if start < times.count {
            for index in start..<min(start + 24, times.count) {
                points.append(HourlyPoint(time: Date(timeIntervalSince1970: TimeInterval(times[index])),
                                          temperature: rounded(value(response.hourly?.temperature_2m, index)),
                                          precipitationChance: rounded(value(response.hourly?.precipitation_probability, index))))
            }
        }

        let currentRain = value(response.hourly?.precipitation_probability, start)
            ?? value(response.daily?.precipitation_probability_max, 0)

        var intervals: [SunInterval] = []
        var sunIsComplete = false
        if let rises = response.daily?.sunrise, let sets = response.daily?.sunset, !rises.isEmpty, rises.count == sets.count {
            sunIsComplete = true
            for index in 0..<rises.count {
                if let up = rises[index], let down = sets[index], down > up {
                    intervals.append(SunInterval(sunrise: Date(timeIntervalSince1970: TimeInterval(up)),
                                                 sunset: Date(timeIntervalSince1970: TimeInterval(down))))
                } else {
                    sunIsComplete = false
                }
            }
        }

        return WeatherSnapshot(
            cityID: city.id,
            fetchedAt: Date(),
            timeZoneID: response.timezone ?? city.timezone ?? TimeZone.current.identifier,
            weatherCode: code,
            temperature: rounded(response.current.temperature_2m),
            feelsLike: rounded(response.current.apparent_temperature),
            humidity: rounded(response.current.relative_humidity_2m),
            windKmh: rounded(response.current.wind_speed_10m),
            precipitationChance: rounded(currentRain),
            high: rounded(value(response.daily?.temperature_2m_max, 0)),
            low: rounded(value(response.daily?.temperature_2m_min, 0)),
            uvIndexMax: rounded(value(response.daily?.uv_index_max, 0)),
            hourly: points,
            sun: sunIsComplete ? intervals : nil
        )
    }
}