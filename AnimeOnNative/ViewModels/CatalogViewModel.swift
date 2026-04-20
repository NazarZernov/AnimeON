import Foundation

@MainActor
final class CatalogViewModel: ObservableObject {
    @Published var state: LoadableState<[Anime]> = .idle
    @Published var filters = CatalogFilters()
    @Published private(set) var items: [Anime] = []
    @Published private(set) var hasNextPage = true
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var availableGenres: [String] = []
    @Published private(set) var totalCount = 0

    private let repository: AnimeRepositoryProtocol
    private let pageSize = 6
    private var searchTask: Task<Void, Never>?
    @Published private(set) var currentPage = 1

    init(repository: AnimeRepositoryProtocol) {
        self.repository = repository
    }

    func load(refresh: Bool = false) async {
        state = .loading
        currentPage = 1

        do {
            let response = try await repository.catalog(page: currentPage, pageSize: pageSize, filters: filters, refresh: refresh)
            items = response.items
            hasNextPage = response.hasNextPage
            totalCount = response.totalCount
            state = response.items.isEmpty ? .empty("По выбранным фильтрам ничего не найдено.") : .loaded(response.items)

            if availableGenres.isEmpty {
                let allItems = try await repository.catalog(page: 1, pageSize: 100, filters: CatalogFilters(), refresh: refresh)
                availableGenres = Array(Set(allItems.items.flatMap(\.genres))).sorted()
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func reloadForChangedFilters() async {
        await load()
    }

    func loadNextPageIfNeeded(currentItem: Anime) async {
        guard hasNextPage, !isLoadingNextPage, items.last == currentItem else {
            return
        }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            currentPage += 1
            let response = try await repository.catalog(page: currentPage, pageSize: pageSize, filters: filters, refresh: false)
            items.append(contentsOf: response.items)
            hasNextPage = response.hasNextPage
            totalCount = response.totalCount
            state = .loaded(items)
        } catch {
            hasNextPage = false
        }
    }

    func scheduleSearchRefresh() {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.reloadForChangedFilters()
        }
    }
}
