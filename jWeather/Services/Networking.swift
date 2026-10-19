import Foundation

enum Networking {
    private static let connectivityErrors: Set<URLError.Code> = [
        .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotFindHost,
        .cannotConnectToHost, .dnsLookupFailed, .dataNotAllowed, .internationalRoamingOff
    ]

    static func data(from url: URL, using session: URLSession) async throws -> Data {
        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw WeatherError.server
            }
            return data
        } catch let error as WeatherError {
            throw error
        } catch let error as URLError {
            if error.code == .cancelled { throw CancellationError() }
            throw connectivityErrors.contains(error.code) ? WeatherError.offline : WeatherError.server
        } catch {
            throw WeatherError.server
        }
    }

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw WeatherError.invalidData
        }
    }
}