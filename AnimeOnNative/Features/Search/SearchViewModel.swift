import Foundation

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = "" {
        didSet { scheduleSearch() }
    }
    @Published var state: LoadableState<[Anime]> = .empty("Начните вводить название, жанр или оригинальный тайтл.")
    @Published private(set) var recentQueries: [String] = []

    private let repository: AnimeRepositoryProtocol
    private let storageKey = "animeon.search.recent"
    private var searchTask: Task<Void, Never>?

    init(repository: AnimeRepositoryProtocol) {
        self.repository = repository
        recentQueries = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
    }

    func rerun() async {
        await performSearch()
    }

    func useQuery(_ query: String) {
        self.query = query
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 320_000_000)
            guard !Task.isCancelled else { return }
            await self?.performSearch()
        }
    }

    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .empty("Начните вводить название, жанр или оригинальный тайтл.")
            return
        }

        guard trimmed.count >= 2 else {
            state = .empty("Введите хотя бы 2 символа для поиска.")
            return
        }

        state = .loading
        do {
            let results = try await repository.search(query: trimmed)
            if results.isEmpty {
                state = .empty("Ничего не найдено. Попробуйте другое название или жанр.")
            } else {
                state = .loaded(results)
                remember(query: trimmed)
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func remember(query: String) {
        recentQueries.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        recentQueries.insert(query, at: 0)
        recentQueries = Array(recentQueries.prefix(8))
        UserDefaults.standard.set(recentQueries, forKey: storageKey)
    }
}
