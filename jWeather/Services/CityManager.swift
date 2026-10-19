import Foundation

final class CityManager: ObservableObject {
    static let maxCities = 8

    static let defaultCities = [
        City(id: "seed-viterbo", name: "Viterbo", country: "Italia", admin1: "Lazio",
             latitude: 42.4207, longitude: 12.1077, timezone: "Europe/Rome"),
        City(id: "seed-ferrara", name: "Ferrara", country: "Italia", admin1: "Emilia-Romagna",
             latitude: 44.8375, longitude: 11.6189, timezone: "Europe/Rome")
    ]

    private static let citiesKey = "cities.v1"
    private static let defaultKey = "cities.defaultID.v1"

    @Published private(set) var cities: [City]
    @Published private(set) var selectedID: String
    @Published private(set) var defaultID: String

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        var loaded: [City] = []
        if let data = defaults.data(forKey: Self.citiesKey),
           let decoded = try? JSONDecoder().decode([City].self, from: data) {
            loaded = decoded
        }
        if loaded.isEmpty { loaded = Self.defaultCities }
        let savedDefault = defaults.string(forKey: Self.defaultKey)
        let defaultCity = loaded.first(where: { $0.id == savedDefault }) ?? loaded[0]
        cities = loaded
        defaultID = defaultCity.id
        selectedID = defaultCity.id
    }

    var selected: City { cities.first(where: { $0.id == selectedID }) ?? cities[0] }
    var isFull: Bool { cities.count >= Self.maxCities }

    func existing(matching city: City) -> City? { cities.first(where: { $0.isSame(as: city) }) }
    func contains(_ city: City) -> Bool { existing(matching: city) != nil }

    @discardableResult
    func add(_ city: City) -> Bool {
        guard !contains(city), !isFull else { return false }
        cities.append(city)
        save()
        return true
    }

    func select(_ cityID: String) {
        guard cities.contains(where: { $0.id == cityID }) else { return }
        selectedID = cityID
    }

    func setDefault(_ city: City) {
        guard cities.contains(where: { $0.id == city.id }) else { return }
        defaultID = city.id
        save()
    }

    func remove(_ city: City) {
        guard cities.count > 1 else { return }
        cities.removeAll(where: { $0.id == city.id })
        if defaultID == city.id { defaultID = cities[0].id }
        if selectedID == city.id { selectedID = defaultID }
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(cities) { defaults.set(data, forKey: Self.citiesKey) }
        defaults.set(defaultID, forKey: Self.defaultKey)
    }
}