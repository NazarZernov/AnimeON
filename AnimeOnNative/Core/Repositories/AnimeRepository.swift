import Foundation

protocol AnimeRepositoryProtocol {
    func dashboard(refresh: Bool) async throws -> HomeDashboard
    func catalog(page: Int, pageSize: Int, filters: CatalogFilters, refresh: Bool) async throws -> CatalogResponse
    func anime(id: Int, refresh: Bool) async throws -> Anime
    func episodes(animeID: Int, refresh: Bool) async throws -> [Episode]
    func search(query: String) async throws -> [Anime]
    func schedule(refresh: Bool) async throws -> [ScheduleDay]
    func updates(refresh: Bool) async throws -> [UpdateItem]
    func news(refresh: Bool) async throws -> [NewsItem]
    func randomAnime(refresh: Bool) async throws -> Anime
    func login(email: String, password: String) async throws -> UserSession
    func profile(refresh: Bool) async throws -> UserProfile
    func setWatchlist(animeID: Int, included: Bool) async
    func setReaction(animeID: Int, isLiked: Bool) async
    func setRating(animeID: Int, rating: Int) async
    func recordHistory(_ entry: WatchHistoryEntry) async
    func recordProgress(_ payload: PlaybackProgressPayload) async
    func flushSyncQueue() async
}

@MainActor
final class AnimeRepository: AnimeRepositoryProtocol {
    private let service: any AnimeServicing
    private let cacheManager: CacheManager
    private let syncManager: OfflineSyncManager

    init(
        service: any AnimeServicing,
        cacheManager: CacheManager,
        syncManager: OfflineSyncManager
    ) {
        self.service = service
        self.cacheManager = cacheManager
        self.syncManager = syncManager
    }

    func dashboard(refresh: Bool = false) async throws -> HomeDashboard {
        let cacheKey = "dashboard"
        if !refresh, let cached: HomeDashboard = await cacheManager.value(forKey: cacheKey, as: HomeDashboard.self) {
            return cached
        }

        do {
            async let heroFeed = service.fetchHome()
            async let updates = service.fetchUpdates()
            async let news = service.fetchNews()
            async let schedule = service.fetchSchedule()
            async let random = service.randomAnime()

            let dashboard = try await HomeDashboard(
                heroFeed: heroFeed,
                updates: updates,
                news: news,
                schedule: schedule,
                randomPick: random
            )
            await cacheManager.store(dashboard, forKey: cacheKey)
            return dashboard
        } catch {
            if let cached: HomeDashboard = await cacheManager.value(forKey: cacheKey, as: HomeDashboard.self) {
                return cached
            }
            throw error
        }
    }

    func catalog(
        page: Int,
        pageSize: Int,
        filters: CatalogFilters,
        refresh: Bool = false
    ) async throws -> CatalogResponse {
        let key = catalogCacheKey(page: page, pageSize: pageSize, filters: filters)
        return try await loadValue(key: key, refresh: refresh) {
            try await service.fetchCatalog(page: page, pageSize: pageSize, filters: filters)
        }
    }

    func anime(id: Int, refresh: Bool = false) async throws -> Anime {
        try await loadValue(key: "anime-\(id)", refresh: refresh) {
            try await service.fetchAnime(id: id)
        }
    }

    func episodes(animeID: Int, refresh: Bool = false) async throws -> [Episode] {
        try await loadValue(key: "episodes-\(animeID)", refresh: refresh) {
            try await service.fetchEpisodes(animeID: animeID)
        }
    }

    func search(query: String) async throws -> [Anime] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return try await loadValue(key: "search-\(trimmed.lowercased())", refresh: false) {
            try await service.search(query: trimmed)
        }
    }

    func schedule(refresh: Bool = false) async throws -> [ScheduleDay] {
        try await loadValue(key: "schedule", refresh: refresh) {
            try await service.fetchSchedule()
        }
    }

    func updates(refresh: Bool = false) async throws -> [UpdateItem] {
        try await loadValue(key: "updates", refresh: refresh) {
            try await service.fetchUpdates()
        }
    }

    func news(refresh: Bool = false) async throws -> [NewsItem] {
        try await loadValue(key: "news", refresh: refresh) {
            try await service.fetchNews()
        }
    }

    func randomAnime(refresh: Bool = false) async throws -> Anime {
        try await loadValue(key: "random", refresh: refresh) {
            try await service.randomAnime()
        }
    }

    func login(email: String, password: String) async throws -> UserSession {
        let session = try await service.login(email: email, password: password)
        await cacheManager.store(session.profile, forKey: "profile")
        return session
    }

    func profile(refresh: Bool = false) async throws -> UserProfile {
        try await loadValue(key: "profile", refresh: refresh) {
            try await service.fetchProfile()
        }
    }

    func setWatchlist(animeID: Int, included: Bool) async {
        await mutateCachedProfile { profile in
            if included {
                if !profile.watchlistIDs.contains(animeID) {
                    profile.watchlistIDs.append(animeID)
                }
            } else {
                profile.watchlistIDs.removeAll { $0 == animeID }
            }
        }

        let mutation = WatchlistMutation(animeID: animeID, action: included ? .add : .remove)
        await syncManager.enqueueWatchlist(mutation)
    }

    func setReaction(animeID: Int, isLiked: Bool) async {
        await mutateCachedProfile { profile in
            if isLiked {
                if !profile.likedAnimeIDs.contains(animeID) {
                    profile.likedAnimeIDs.append(animeID)
                }
            } else {
                profile.likedAnimeIDs.removeAll { $0 == animeID }
            }
        }
        await syncManager.enqueueReaction(AnimeReactionPayload(animeID: animeID, isLiked: isLiked))
    }

    func setRating(animeID: Int, rating: Int) async {
        await mutateCachedProfile { profile in
            profile.ratings.removeAll { $0.animeID == animeID }
            profile.ratings.append(AnimeRatingRecord(animeID: animeID, rating: rating))
        }
        await syncManager.enqueueRating(AnimeRatingPayload(animeID: animeID, rating: rating))
    }

    func recordHistory(_ entry: WatchHistoryEntry) async {
        await mutateCachedProfile { profile in
            profile.history.removeAll { $0.episodeID == entry.episodeID }
            profile.history.insert(entry, at: 0)
        }
        await syncManager.enqueueHistory(entry)
    }

    func recordProgress(_ payload: PlaybackProgressPayload) async {
        await syncManager.enqueueProgress(payload)
    }

    func flushSyncQueue() async {
        await syncManager.flush()
    }

    private func loadValue<Value: Codable>(
        key: String,
        refresh: Bool,
        loader: () async throws -> Value
    ) async throws -> Value {
        if !refresh, let cached: Value = await cacheManager.value(forKey: key, as: Value.self) {
            return cached
        }

        do {
            let value = try await loader()
            await cacheManager.store(value, forKey: key)
            return value
        } catch {
            if let cached: Value = await cacheManager.value(forKey: key, as: Value.self) {
                return cached
            }
            throw error
        }
    }

    private func mutateCachedProfile(_ mutate: (inout UserProfile) -> Void) async {
        guard var cached: UserProfile = await cacheManager.value(forKey: "profile", as: UserProfile.self) else {
            return
        }

        mutate(&cached)
        await cacheManager.store(cached, forKey: "profile")
    }

    private func catalogCacheKey(page: Int, pageSize: Int, filters: CatalogFilters) -> String {
        let genres = filters.genres.sorted().joined(separator: ",")
        return [
            "catalog",
            "\(page)",
            "\(pageSize)",
            filters.searchText.lowercased(),
            genres,
            "\(filters.yearRange.lowerBound)",
            "\(filters.yearRange.upperBound)",
            filters.type?.rawValue ?? "all",
            filters.status?.rawValue ?? "all",
            String(format: "%.1f", filters.minimumRating),
            filters.sort.rawValue
        ].joined(separator: "|")
    }
}
