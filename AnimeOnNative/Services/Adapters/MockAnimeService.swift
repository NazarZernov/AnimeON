import Foundation

private struct MockStore {
    var anime: [Anime]
    var episodes: [Episode]
    var schedule: [ScheduleDay]
    var updates: [UpdateItem]
    var news: [NewsItem]
    var leaderboard: [PlayerLeaderboardEntry]
    var premiumPlans: [PremiumPlan]
    var profile: UserProfile

    init(
        anime: [Anime],
        episodes: [Episode],
        schedule: [ScheduleDay],
        updates: [UpdateItem],
        news: [NewsItem],
        leaderboard: [PlayerLeaderboardEntry],
        premiumPlans: [PremiumPlan],
        profile: UserProfile
    ) {
        self.anime = anime
        self.episodes = episodes
        self.schedule = schedule
        self.updates = updates
        self.news = news
        self.leaderboard = leaderboard
        self.premiumPlans = premiumPlans
        self.profile = profile
    }

    init(bundle: Bundle = .main) throws {
        anime = try MockBundleLoader.load("anime_catalog.json", bundle: bundle)
        episodes = try MockBundleLoader.load("episodes.json", bundle: bundle)
        schedule = try MockBundleLoader.load("schedule.json", bundle: bundle)
        updates = try MockBundleLoader.load("updates.json", bundle: bundle)
        news = try MockBundleLoader.load("news.json", bundle: bundle)
        leaderboard = try MockBundleLoader.load("leaderboard.json", bundle: bundle)
        premiumPlans = try MockBundleLoader.load("premium_plans.json", bundle: bundle)
        profile = try MockBundleLoader.load("profile.json", bundle: bundle)
    }
}

final class MockAnimeService: AnimeServicing {
    private var store: MockStore
    private let latencyNanoseconds: UInt64

    init(bundle: Bundle = .main, latencyNanoseconds: UInt64 = 180_000_000) {
        self.latencyNanoseconds = latencyNanoseconds
        do {
            store = try MockStore(bundle: bundle)
        } catch {
            store = MockStore(
                anime: [],
                episodes: [],
                schedule: [],
                updates: [],
                news: [],
                leaderboard: [],
                premiumPlans: [],
                profile: UserProfile(
                    id: 0,
                    username: "guest",
                    displayName: "Guest",
                    avatarURL: URL(string: "https://i.pravatar.cc/200?img=1")!,
                    isPremium: false,
                    level: 1,
                    watchHours: 0,
                    streakDays: 0,
                    watchlistIDs: [],
                    history: [],
                    badges: []
                )
            )
        }
    }

    func fetchHome() async throws -> HomePayload {
        try await simulateLatency()

        let featured = sortedAnime(by: .popular).first ?? store.anime.first
        guard let featured else {
            throw MockBundleLoaderError.fileNotFound("anime_catalog.json")
        }

        return HomePayload(
            featured: featured,
            popularOngoing: Array(sortedAnime(by: .ongoing).prefix(8)),
            newEpisodes: Array(sortedAnime(by: .recentlyUpdated).prefix(8)),
            popularAllTime: Array(sortedAnime(by: .popular).prefix(8)),
            topHundred: Array(sortedAnime(by: .rating).prefix(10)),
            leaderboard: Array(store.leaderboard.prefix(5))
        )
    }

    func fetchCatalog(page: Int, pageSize: Int, filters: CatalogFilters) async throws -> CatalogResponse {
        try await simulateLatency()
        let filtered = filteredAnime(using: filters)
        let offset = max((page - 1) * pageSize, 0)
        let paged = Array(filtered.dropFirst(offset).prefix(pageSize))
        return CatalogResponse(items: paged, page: page, pageSize: pageSize, totalCount: filtered.count)
    }

    func fetchAnime(id: Int) async throws -> Anime {
        try await simulateLatency()
        guard let anime = store.anime.first(where: { $0.id == id }) else {
            throw NSError(domain: "MockAnimeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Тайтл не найден"])
        }
        return anime
    }

    func fetchEpisodes(animeID: Int) async throws -> [Episode] {
        try await simulateLatency()
        return store.episodes
            .filter { $0.animeID == animeID }
            .sorted { $0.number < $1.number }
    }

    func search(query: String) async throws -> [Anime] {
        try await simulateLatency()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Array(sortedAnime(by: .popular).prefix(8))
        }

        return store.anime.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
            || $0.originalTitle.localizedCaseInsensitiveContains(trimmed)
            || $0.genres.contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
        }
    }

    func randomAnime() async throws -> Anime {
        try await simulateLatency()
        guard let random = store.anime.randomElement() else {
            throw NSError(domain: "MockAnimeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Каталог пуст"])
        }
        return random
    }

    func fetchSchedule() async throws -> [ScheduleDay] {
        try await simulateLatency()
        return store.schedule.sorted { $0.date < $1.date }
    }

    func fetchUpdates() async throws -> [UpdateItem] {
        try await simulateLatency()
        return store.updates.sorted { $0.publishedAt > $1.publishedAt }
    }

    func fetchNews() async throws -> [NewsItem] {
        try await simulateLatency()
        return store.news.sorted { $0.publishedAt > $1.publishedAt }
    }

    func fetchPremiumPlans() async throws -> [PremiumPlan] {
        try await simulateLatency()
        return store.premiumPlans
    }

    func login(email: String, password: String) async throws -> UserSession {
        try await simulateLatency()

        guard !email.isEmpty, !password.isEmpty else {
            throw NSError(domain: "MockAnimeService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Введите email и пароль"])
        }

        return UserSession(token: "mock-session-token", profile: store.profile)
    }

    func fetchProfile() async throws -> UserProfile {
        try await simulateLatency()
        return store.profile
    }

    func updateWatchlist(animeID: Int, action: WatchlistAction) async throws {
        try await simulateLatency()

        switch action {
        case .add:
            if !store.profile.watchlistIDs.contains(animeID) {
                store.profile.watchlistIDs.append(animeID)
            }
        case .remove:
            store.profile.watchlistIDs.removeAll { $0 == animeID }
        }
    }

    func updateHistory(entry: WatchHistoryEntry) async throws {
        try await simulateLatency()
        store.profile.history.removeAll { $0.episodeID == entry.episodeID }
        store.profile.history.insert(entry, at: 0)
    }

    func updateProgress(_ payload: PlaybackProgressPayload) async throws {
        try await simulateLatency()
        let historyEntry = WatchHistoryEntry(
            id: payload.episodeID,
            animeID: payload.animeID,
            episodeID: payload.episodeID,
            progressSeconds: payload.progressSeconds,
            lastWatchedAt: payload.updatedAt
        )
        try await updateHistory(entry: historyEntry)
    }

    func updateReaction(_ payload: AnimeReactionPayload) async throws {
        try await simulateLatency()
        if payload.isLiked {
            if !store.profile.likedAnimeIDs.contains(payload.animeID) {
                store.profile.likedAnimeIDs.append(payload.animeID)
            }
        } else {
            store.profile.likedAnimeIDs.removeAll { $0 == payload.animeID }
        }
    }

    func updateRating(_ payload: AnimeRatingPayload) async throws {
        try await simulateLatency()
        store.profile.ratings.removeAll { $0.animeID == payload.animeID }
        store.profile.ratings.append(AnimeRatingRecord(animeID: payload.animeID, rating: payload.rating))
    }

    func postStats(_ event: UserStatEvent) async throws {
        try await simulateLatency()
        if event.name == "episode_watched" {
            store.profile = UserProfile(
                id: store.profile.id,
                username: store.profile.username,
                displayName: store.profile.displayName,
                avatarURL: store.profile.avatarURL,
                isPremium: store.profile.isPremium,
                level: store.profile.level,
                watchHours: store.profile.watchHours + event.value,
                streakDays: store.profile.streakDays,
                watchlistIDs: store.profile.watchlistIDs,
                history: store.profile.history,
                badges: store.profile.badges,
                likedAnimeIDs: store.profile.likedAnimeIDs,
                ratings: store.profile.ratings
            )
        }
    }

    private func filteredAnime(using filters: CatalogFilters) -> [Anime] {
        var result = store.anime

        let trimmedQuery = filters.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(trimmedQuery)
                || $0.originalTitle.localizedCaseInsensitiveContains(trimmedQuery)
            }
        }

        if !filters.genres.isEmpty {
            result = result.filter { anime in
                !filters.genres.isDisjoint(with: Set(anime.genres))
            }
        }

        result = result.filter { filters.yearRange.contains($0.year) }

        if let type = filters.type {
            result = result.filter { $0.type == type }
        }

        if let status = filters.status {
            result = result.filter { $0.status == status }
        }

        result = result.filter { $0.rating >= filters.minimumRating }

        return sort(result, by: filters.sort)
    }

    private func sortedAnime(by sortKind: CatalogSort) -> [Anime] {
        sort(store.anime, by: sortKind)
    }

    private func sort(_ items: [Anime], by sortKind: CatalogSort) -> [Anime] {
        switch sortKind {
        case .popular:
            return items.sorted { $0.viewsCount > $1.viewsCount }
        case .rating:
            return items.sorted { $0.rating > $1.rating }
        case .newest:
            return items.sorted { $0.year > $1.year }
        case .ongoing:
            return items.sorted {
                ($0.status == .ongoing ? 1 : 0, $0.viewsCount) > ($1.status == .ongoing ? 1 : 0, $1.viewsCount)
            }
        case .recentlyUpdated:
            return items.sorted { ($0.releasedEpisodes, $0.viewsCount) > ($1.releasedEpisodes, $1.viewsCount) }
        }
    }

    private func simulateLatency() async throws {
        try await Task.sleep(nanoseconds: latencyNanoseconds)
    }
}
