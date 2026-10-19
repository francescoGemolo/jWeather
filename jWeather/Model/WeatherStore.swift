import SwiftUI
import AppKit
import Combine

final class WeatherStore: ObservableObject {
    enum ActiveSheet: Equatable { case hourly, cities, test }
    enum RefreshTrigger { case manual, ifStale, scheduled }
    private enum LineUpdate { case keepIfValid, caption, greeting, chatter }

    @Published private(set) var snapshot: WeatherSnapshot? {
        didSet { updateDayPhase() }
    }
    @Published private(set) var loadState: LoadState = .idle
    @Published private(set) var mascotLine = ""
    @Published private(set) var dayPhase: DayPhase = .day
    @Published private(set) var simulation: SimulationState?
    @Published var activeSheet: ActiveSheet?
    @Published var useFahrenheit: Bool {
        didSet { UserDefaults.standard.set(useFahrenheit, forKey: Self.fahrenheitKey) }
    }

    let cityManager: CityManager

    private static let fahrenheitKey = "units.fahrenheit"
    private static let staleAfter: TimeInterval = 600
    private static let autoRefreshInterval: TimeInterval = 900
    private static let minimumGap: TimeInterval = 30
    private static let phaseCheckInterval: TimeInterval = 30
    private static let maxRetryDelay: TimeInterval = 300

    private let service = OpenMeteoService()
    private let cache = SnapshotCache()
    private var task: Task<Void, Never>?
    private var retryTask: Task<Void, Never>?
    private var retryCount = 0
    private var lastAttempt = Date.distantPast
    private var timers: [Timer] = []
    private var bag = Set<AnyCancellable>()
    private lazy var timeFormatter = makeFormatter(WeatherMessages.timeFormat)
    private lazy var dateFormatter = makeFormatter(WeatherMessages.dateFormat)

    init() {
        let manager = CityManager()
        cityManager = manager
        useFahrenheit = UserDefaults.standard.bool(forKey: Self.fahrenheitKey)

        snapshot = cache.load(cityID: manager.selectedID)
        dayPhase = DayPhase.phase(at: Date(), sun: snapshot?.sun, coordinate: coordinate)
        updateLine(.caption)

        manager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &bag)
        NSWorkspace.shared.notificationCenter
            .publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                self?.updateDayPhase()
                self?.refresh(.ifStale)
            }
            .store(in: &bag)

        let refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.autoRefreshInterval, repeats: true) { [weak self] _ in
            self?.refresh(.scheduled)
        }
        refreshTimer.tolerance = 30
        let phaseTimer = Timer.scheduledTimer(withTimeInterval: Self.phaseCheckInterval, repeats: true) { [weak self] _ in
            self?.updateDayPhase()
        }
        phaseTimer.tolerance = 5
        timers = [refreshTimer, phaseTimer]

        refresh(.scheduled)
    }

    deinit {
        timers.forEach { $0.invalidate() }
    }

    var condition: WeatherCondition {
        snapshot.map { WeatherCondition(weatherCode: $0.weatherCode) } ?? .sunny
    }

    var intensity: WeatherIntensity {
        snapshot.map { WeatherIntensity(weatherCode: $0.weatherCode) } ?? .moderate
    }

    var scene: SkyScene {
        SkyScene(condition: condition, intensity: intensity, isNight: dayPhase == .night)
    }

    var timeZone: TimeZone {
        if let snapshot = snapshot { return snapshot.timeZone }
        if let id = cityManager.selected.timezone, let zone = TimeZone(identifier: id) { return zone }
        return .current
    }

    var coordinate: (latitude: Double, longitude: Double) {
        let city = cityManager.selected
        return (city.latitude, city.longitude)
    }

    var accent: Color { condition.accent(for: dayPhase) }
    var mascotAssetName: String { condition.mascotAsset(for: dayPhase) }
    var menuSymbolName: String { condition.symbolName(for: dayPhase) }
    var cityName: String { cityManager.selected.name }

    func updateDayPhase() {
        let phase = DayPhase.phase(at: Date(), sun: snapshot?.sun, coordinate: coordinate)
        guard phase != dayPhase else { return }
        dayPhase = phase
        updateLine(.keepIfValid)
    }

    var conditionTitle: String {
        if snapshot != nil { return condition.label }
        if case .failed = loadState { return WeatherMessages.noDataTitle }
        return WeatherMessages.loadingTitle
    }

    var captionText: String {
        guard snapshot != nil else {
            if case .failed(let error) = loadState { return WeatherMessages.errorMessage(error) }
            return WeatherMessages.loadingMessage
        }
        return mascotLine
    }

    var headerSubtitle: String {
        if case .failed(let error) = loadState, let snapshot = snapshot {
            let prefix = error == .offline ? WeatherMessages.offlinePrefix : WeatherMessages.outdatedPrefix
            return "\(prefix) · \(timeString(snapshot.fetchedAt))"
        }
        if simulation != nil { return "\(WeatherMessages.simulatedPrefix) · \(dateString())" }
        return "\(WeatherMessages.todayPrefix), \(dateString())"
    }

    var temperature: Int? { snapshot?.temperature }
    var feelsLike: Int? { snapshot?.feelsLike }
    var humidity: Int? { snapshot?.humidity }
    var windKmh: Int? { snapshot?.windKmh }
    var low: Int? { snapshot?.low }
    var high: Int? { snapshot?.high }
    var uvIndex: Int? { snapshot?.uvIndexMax }
    var rainChance: Int? { snapshot?.precipitationChance }

    var hourlyPoints: [HourlyPoint] {
        let now = Date()
        return Array((snapshot?.hourly ?? []).filter { $0.time.addingTimeInterval(3600) > now }.prefix(6))
    }

    var sunsetText: String {
        guard let sun = snapshot?.sun, let last = sun.last else { return WeatherMessages.missingValue }
        let now = Date()
        let next = sun.first(where: { $0.sunset > now }) ?? last
        return timeString(next.sunset)
    }

    var menuBarTemperature: String { tempText(temperature) }

    func displayTemp(_ celsius: Int) -> Int {
        useFahrenheit ? Int((Double(celsius) * 9 / 5 + 32).rounded()) : celsius
    }

    func tempText(_ celsius: Int?) -> String {
        celsius.map { "\(displayTemp($0))°" } ?? WeatherMessages.missingValue
    }

    func windText(_ kmh: Int?) -> String {
        guard let kmh = kmh else { return WeatherMessages.missingValue }
        return useFahrenheit ? "\(Int((Double(kmh) * 0.621).rounded())) \(WeatherMessages.windUnitImperial)"
                             : "\(kmh) \(WeatherMessages.windUnitMetric)"
    }

    func percentText(_ value: Int?) -> String { value.map { "\($0)%" } ?? WeatherMessages.missingValue }
    func plainText(_ value: Int?) -> String { value.map { "\($0)" } ?? WeatherMessages.missingValue }

    func timeString(_ date: Date) -> String {
        timeFormatter.timeZone = timeZone
        return timeFormatter.string(from: date)
    }

    private func dateString() -> String {
        dateFormatter.timeZone = timeZone
        return dateFormatter.string(from: Date())
    }

    private func makeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: WeatherMessages.dateLocale)
        formatter.dateFormat = format
        return formatter
    }

    func selectCity(_ city: City) {
        guard cityManager.contains(city), city.id != cityManager.selectedID else { return }
        cityManager.select(city.id)
        activateSelectedCity()
    }

    func selectAdjacentCity(_ delta: Int) {
        let cities = cityManager.cities
        guard cities.count > 1, let index = cities.firstIndex(where: { $0.id == cityManager.selectedID }) else { return }
        selectCity(cities[(index + delta + cities.count) % cities.count])
    }

    func addCity(_ city: City) {
        if let existing = cityManager.existing(matching: city) {
            selectCity(existing)
            return
        }
        guard cityManager.add(city) else { return }
        selectCity(city)
    }

    func removeCity(_ city: City) {
        let wasSelected = city.id == cityManager.selectedID
        cityManager.remove(city)
        cache.remove(cityID: city.id)
        if wasSelected { activateSelectedCity() }
    }

    private func activateSelectedCity() {
        task?.cancel()
        cancelRetry()
        snapshot = simulation == nil ? cache.load(cityID: cityManager.selectedID) : nil
        loadState = .idle
        lastAttempt = .distantPast
        updateDayPhase()
        updateLine(.caption)
        refresh(.scheduled)
    }

    func setSimulation(_ state: SimulationState?) {
        simulation = state
        if state == nil {
            snapshot = cache.load(cityID: cityManager.selectedID)
            loadState = .idle
            lastAttempt = .distantPast
            updateLine(.keepIfValid)
        }
        refresh(.manual)
    }

    func toggleTestTools() {
        activeSheet = activeSheet == .test ? nil : .test
    }

    private func applySimulation(_ state: SimulationState) {
        task?.cancel()
        cancelRetry()
        switch state.network {
        case .online:
            snapshot = Simulator.snapshot(for: cityManager.selected, state: state)
            loadState = .loaded
            updateLine(.keepIfValid)
        case .offline:
            loadState = .failed(.offline)
        case .error:
            loadState = .failed(.server)
        }
    }

    func refresh(_ trigger: RefreshTrigger) {
        if let state = simulation {
            if trigger != .ifStale { applySimulation(state) }
            return
        }
        let now = Date()
        switch trigger {
        case .manual:
            task?.cancel()
            cancelRetry()
        case .ifStale:
            guard loadState != .loading, now.timeIntervalSince(lastAttempt) >= Self.minimumGap else { return }
            if let snapshot = snapshot, now.timeIntervalSince(snapshot.fetchedAt) < Self.staleAfter { return }
        case .scheduled:
            guard loadState != .loading, now.timeIntervalSince(lastAttempt) >= Self.minimumGap else { return }
        }

        let city = cityManager.selected
        lastAttempt = now
        loadState = .loading
        task = Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                let fresh = try await self.service.fetch(for: city)
                guard !Task.isCancelled, self.cityManager.selected.id == city.id else { return }
                self.cache.save(fresh)
                self.cancelRetry()
                self.snapshot = fresh
                self.loadState = .loaded
                self.updateLine(.keepIfValid)
            } catch {
                guard !Task.isCancelled, self.cityManager.selected.id == city.id else { return }
                if error is CancellationError {
                    self.loadState = .idle
                    return
                }
                self.loadState = .failed((error as? WeatherError) ?? .server)
                self.scheduleRetry()
            }
        }
    }

    private func scheduleRetry() {
        retryTask?.cancel()
        retryCount += 1
        let delay = min(Self.maxRetryDelay, 30.0 * pow(2.0, Double(retryCount - 1)))
        retryTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled, let self = self else { return }
            self.refresh(.scheduled)
        }
    }

    private func cancelRetry() {
        retryTask?.cancel()
        retryTask = nil
        retryCount = 0
    }

    func popoverDidOpen() {
        updateDayPhase()
        refresh(.ifStale)
        updateLine(.greeting)
    }

    func mascotTapped() { updateLine(.chatter) }

    private func updateLine(_ update: LineUpdate) {
        let context = messageContext()
        switch update {
        case .keepIfValid:
            if !MessageComposer.isFitting(mascotLine, in: context) {
                mascotLine = MessageComposer.caption(context, avoiding: mascotLine)
            }
        case .caption:
            mascotLine = MessageComposer.caption(context, avoiding: mascotLine)
        case .greeting:
            if Int.random(in: 0..<10) < WeatherMessages.greetingChanceOutOf10 {
                mascotLine = MessageComposer.greeting(hour: context.hour, isDay: context.isDay, avoiding: mascotLine)
            } else {
                mascotLine = MessageComposer.caption(context, avoiding: mascotLine)
            }
        case .chatter:
            mascotLine = MessageComposer.chatter(avoiding: mascotLine)
        }
    }

    private func messageContext() -> MessageContext {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return MessageContext(condition: condition,
                              temperature: snapshot?.temperature,
                              windKmh: snapshot?.windKmh,
                              uvIndex: snapshot?.uvIndexMax,
                              isDay: dayPhase == .day,
                              hour: calendar.component(.hour, from: Date()))
    }
}