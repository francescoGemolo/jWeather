import Foundation

final class GeocodingService {
    private let session: URLSession

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10
        session = URLSession(configuration: configuration)
    }

    private struct Response: Decodable {
        struct Item: Decodable {
            let id: Int
            let name: String
            let latitude: Double
            let longitude: Double
            let country: String?
            let admin1: String?
            let timezone: String?
        }
        let results: [Item]?
    }

    func search(_ query: String) async throws -> [City] {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "6"),
            URLQueryItem(name: "language", value: WeatherMessages.geocodingLanguage),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components.url else { throw WeatherError.invalidData }
        let data = try await Networking.data(from: url, using: session)
        let decoded = try Networking.decode(Response.self, from: data)
        return (decoded.results ?? []).map {
            City(id: String($0.id), name: $0.name, country: $0.country, admin1: $0.admin1,
                 latitude: $0.latitude, longitude: $0.longitude, timezone: $0.timezone)
        }
    }
}