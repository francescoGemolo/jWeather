import SwiftUI

final class CitySearchModel: ObservableObject {
    enum Status { case idle, searching, results, empty, failed }

    @Published var query = "" { didSet { scheduleSearch() } }
    @Published private(set) var results: [City] = []
    @Published private(set) var status: Status = .idle

    private let service = GeocodingService()
    private var task: Task<Void, Never>?

    private func scheduleSearch() {
        task?.cancel()
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.count >= 2 else {
            results = []
            status = .idle
            return
        }
        status = .searching
        task = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard let self = self, !Task.isCancelled else { return }
            do {
                let found = try await self.service.search(text)
                guard !Task.isCancelled else { return }
                self.results = found
                self.status = found.isEmpty ? .empty : .results
            } catch {
                guard !Task.isCancelled, !(error is CancellationError) else { return }
                self.results = []
                self.status = .failed
            }
        }
    }
}

struct CitiesSheet: View {
    @Environment(\.palette) private var palette
    @ObservedObject var store: WeatherStore
    @StateObject private var search = CitySearchModel()
    @FocusState private var searchFocused: Bool

    var body: some View {
        let accent = store.accent
        let isSearching = !search.query.trimmingCharacters(in: .whitespaces).isEmpty

        VStack(spacing: 0) {
            SheetHandle(store: store)

            Text(WeatherMessages.citiesTitle)
                .font(Theme.font(11, .medium))
                .tracking(0.4)
                .foregroundStyle(palette.mute)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 10)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.mute)
                TextField(WeatherMessages.searchPlaceholder, text: $search.query)
                    .textFieldStyle(.plain)
                    .font(Theme.font(13))
                    .focused($searchFocused)
                if isSearching {
                    Button { search.query = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(palette.mute)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(WeatherMessages.clearSearch)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 32)
            .chipBackground(Capsule())
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    if isSearching { resultRows(accent: accent) } else { savedRows(accent: accent) }
                }
            }
            .frame(height: 176)
        }
        .sheetChrome(store: store, dragToClose: false)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { searchFocused = true }
        }
    }

    @ViewBuilder
    private func savedRows(accent: Color) -> some View {
        ForEach(store.cityManager.cities) { city in
            let isSelected = city.id == store.cityManager.selectedID
            let isDefault = city.id == store.cityManager.defaultID
            HStack(spacing: 10) {
                Button {
                    store.selectCity(city)
                    store.activeSheet = nil
                } label: {
                    cityLabel(city, isSelected: isSelected, accent: accent)
                }
                .buttonStyle(.plain)

                Button { store.cityManager.setDefault(city) } label: {
                    Image(systemName: isDefault ? "star.fill" : "star")
                        .font(.system(size: 13))
                        .foregroundStyle(isDefault ? accent : palette.mute)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isDefault ? WeatherMessages.isDefaultCity : WeatherMessages.setDefaultCity)

                if store.cityManager.cities.count > 1 {
                    Button { store.removeCity(city) } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(palette.mute)
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(WeatherMessages.removeCity)
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func cityLabel(_ city: City, isSelected: Bool, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(city.name)
                .font(Theme.font(14, isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? accent : palette.foreground)
                .lineLimit(1)
            if !city.subtitle.isEmpty {
                Text(city.subtitle)
                    .font(Theme.font(11))
                    .foregroundStyle(palette.mute)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private func resultRows(accent: Color) -> some View {
        switch search.status {
        case .idle:
            hint(WeatherMessages.searchHint)
        case .searching:
            hint(WeatherMessages.searching)
        case .empty:
            hint(WeatherMessages.noResults)
        case .failed:
            hint(WeatherMessages.searchFailed)
        case .results:
            if store.cityManager.isFull { hint(WeatherMessages.citiesFull) }
            ForEach(search.results) { city in
                let saved = store.cityManager.contains(city)
                Button {
                    store.addCity(city)
                    store.activeSheet = nil
                } label: {
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(city.name)
                                .font(Theme.font(14))
                                .foregroundStyle(palette.foreground)
                                .lineLimit(1)
                            if !city.subtitle.isEmpty {
                                Text(city.subtitle)
                                    .font(Theme.font(11))
                                    .foregroundStyle(palette.mute)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 4)
                        Image(systemName: saved ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(saved ? palette.mute : accent)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!saved && store.cityManager.isFull)
                .accessibilityLabel(saved ? WeatherMessages.alreadySaved : WeatherMessages.addCity)
            }
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text)
            .font(Theme.font(12))
            .foregroundStyle(palette.mute)
            .frame(maxWidth: .infinity, minHeight: 60)
    }
}