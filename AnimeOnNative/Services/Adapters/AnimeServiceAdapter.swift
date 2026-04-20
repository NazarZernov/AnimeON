import Foundation

final class AnimeServiceAdapter: AnimeServicing {
    private let mode: DataSourceMode
    private let mockService: MockAnimeService
    private let remoteService: RemoteAnimeService?

    init(configuration: AppConfiguration) {
        mode = configuration.dataSourceMode
        mockService = MockAnimeService()

        switch configuration.dataSourceMode {
        case .mock:
            remoteService = nil
        case let .remote(baseURL), let .hybrid(baseURL):
            remoteService = RemoteAnimeService(baseURL: baseURL)
        }
    }

    func fetchHome() async throws -> HomePayload {
        try await execute(
            remote: { try await remoteService?.fetchHome() },
            mock: { try await mockService.fetchHome() }
        )
    }

    func fetchCatalog(page: Int, pageSize: Int, filters: CatalogFilters) async throws -> CatalogResponse {
        try await execute(
            remote: { try await remoteService?.fetchCatalog(page: page, pageSize: pageSize, filters: filters) },
            mock: { try await mockService.fetchCatalog(page: page, pageSize: pageSize, filters: filters) }
        )
    }

    func fetchAnime(id: Int) async throws -> Anime {
        try await execute(
            remote: { try await remoteService?.fetchAnime(id: id) },
            mock: { try await mockService.fetchAnime(id: id) }
        )
    }

    func fetchEpisodes(animeID: Int) async throws -> [Episode] {
        try await execute(
            remote: { try await remoteService?.fetchEpisodes(animeID: animeID) },
            mock: { try await mockService.fetchEpisodes(animeID: animeID) }
        )
    }

    func search(query: String) async throws -> [Anime] {
        try await execute(
            remote: { try await remoteService?.search(query: query) },
            mock: { try await mockService.search(query: query) }
        )
    }

    func randomAnime() async throws -> Anime {
        try await execute(
            remote: { try await remoteService?.randomAnime() },
            mock: { try await mockService.randomAnime() }
        )
    }

    func fetchSchedule() async throws -> [ScheduleDay] {
        try await execute(
            remote: { try await remoteService?.fetchSchedule() },
            mock: { try await mockService.fetchSchedule() }
        )
    }

    func fetchUpdates() async throws -> [UpdateItem] {
        try await execute(
            remote: { try await remoteService?.fetchUpdates() },
            mock: { try await mockService.fetchUpdates() }
        )
    }

    func fetchNews() async throws -> [NewsItem] {
        try await execute(
            remote: { try await remoteService?.fetchNews() },
            mock: { try await mockService.fetchNews() }
        )
    }

    func fetchPremiumPlans() async throws -> [PremiumPlan] {
        try await execute(
            remote: { try await remoteService?.fetchPremiumPlans() },
            mock: { try await mockService.fetchPremiumPlans() }
        )
    }

    func login(email: String, password: String) async throws -> UserSession {
        try await execute(
            remote: { try await remoteService?.login(email: email, password: password) },
            mock: { try await mockService.login(email: email, password: password) }
        )
    }

    func fetchProfile() async throws -> UserProfile {
        try await execute(
            remote: { try await remoteService?.fetchProfile() },
            mock: { try await mockService.fetchProfile() }
        )
    }

    func updateWatchlist(animeID: Int, action: WatchlistAction) async throws {
        _ = try await execute(
            remote: { try await remoteService?.updateWatchlist(animeID: animeID, action: action); return true },
            mock: { try await mockService.updateWatchlist(animeID: animeID, action: action); return true }
        )
    }

    func updateHistory(entry: WatchHistoryEntry) async throws {
        _ = try await execute(
            remote: { try await remoteService?.updateHistory(entry: entry); return true },
            mock: { try await mockService.updateHistory(entry: entry); return true }
        )
    }

    func updateProgress(_ payload: PlaybackProgressPayload) async throws {
        _ = try await execute(
            remote: { try await remoteService?.updateProgress(payload); return true },
            mock: { try await mockService.updateProgress(payload); return true }
        )
    }

    func updateReaction(_ payload: AnimeReactionPayload) async throws {
        _ = try await execute(
            remote: { try await remoteService?.updateReaction(payload); return true },
            mock: { try await mockService.updateReaction(payload); return true }
        )
    }

    func updateRating(_ payload: AnimeRatingPayload) async throws {
        _ = try await execute(
            remote: { try await remoteService?.updateRating(payload); return true },
            mock: { try await mockService.updateRating(payload); return true }
        )
    }

    func postStats(_ event: UserStatEvent) async throws {
        _ = try await execute(
            remote: { try await remoteService?.postStats(event); return true },
            mock: { try await mockService.postStats(event); return true }
        )
    }

    private func execute<T>(
        remote: () async throws -> T?,
        mock: () async throws -> T
    ) async throws -> T {
        switch mode {
        case .mock:
            return try await mock()
        case .remote:
            if let value = try await remote() {
                return value
            }
            throw NetworkError.invalidResponse
        case .hybrid:
            do {
                if let value = try await remote() {
                    return value
                }
                return try await mock()
            } catch {
                return try await mock()
            }
        }
    }
}
