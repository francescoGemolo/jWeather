import Foundation

struct SnapshotCache {
    private let key = "weather.snapshots.v1"

    func load(cityID: String) -> WeatherSnapshot? { all()[cityID] }

    func save(_ snapshot: WeatherSnapshot) {
        var dictionary = all()
        dictionary[snapshot.cityID] = snapshot
        write(dictionary)
    }

    func remove(cityID: String) {
        var dictionary = all()
        dictionary[cityID] = nil
        write(dictionary)
    }

    private func all() -> [String: WeatherSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: WeatherSnapshot].self, from: data) else { return [:] }
        return decoded
    }

    private func write(_ dictionary: [String: WeatherSnapshot]) {
        if let data = try? JSONEncoder().encode(dictionary) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}