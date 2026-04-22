import Foundation

struct MockHomeRepository: HomeRepository {
    func fetchHomeContent() async throws -> HomeContent {
        try await Task.sleep(for: .milliseconds(350))
        return MockCatalog.homeContent
    }
}

struct MockSearchRepository: SearchRepository {
    func fetchDiscovery() async throws -> SearchDiscoveryContent {
        SearchDiscoveryContent(
            trendingQueries: MockCatalog.trendingSearches,
            featuredGenres: [.sciFi, .drama, .fantasy, .thriller, .romance, .sliceOfLife],
            spotlightTitles: Array(MockCatalog.titles.prefix(4))
        )
    }

    func search(query: String, filters: AnimeSearchFilters) async throws -> [Anime] {
        let lowered = query.lowercased()

        return MockCatalog.titles.filter { anime in
            let matchesQuery = lowered.isEmpty || anime.title.lowercased().contains(lowered) || anime.originalTitle.lowercased().contains(lowered) || anime.tags.joined(separator: " ").lowercased().contains(lowered)
            let matchesGenre = filters.genre == nil || anime.genres.contains(filters.genre!)
            let matchesYear = filters.year == nil || anime.year == filters.year
            let matchesStatus = filters.status == nil || anime.status == filters.status
            let matchesType = filters.type == nil || anime.format == filters.type
            let matchesRating = filters.minimumRating == nil || anime.averageRating >= (filters.minimumRating ?? 0)
            let matchesStudio = filters.studio == nil || anime.studio.localizedCaseInsensitiveContains(filters.studio ?? "")
            let matchesDub = filters.supportsDub == nil || (filters.supportsDub == false || anime.seasons.flatMap(\.episodes).contains { $0.dubCount > 0 })
            let matchesSubtitles = filters.supportsSubtitles == nil || (filters.supportsSubtitles == false || anime.seasons.flatMap(\.episodes).contains { $0.subtitleCount > 0 })

            return matchesQuery && matchesGenre && matchesYear && matchesStatus && matchesType && matchesRating && matchesStudio && matchesDub && matchesSubtitles
        }
    }
}

struct MockAnimeRepository: AnimeRepository {
    func fetchAnime(id: String) async throws -> Anime {
        MockCatalog.anime(with: id)
    }

    func fetchRelatedTitles(for animeID: String) async throws -> [Anime] {
        MockCatalog.relatedTitles(for: animeID)
    }
}

@MainActor
final class MockScheduleRepository: ScheduleRepository {
    private var entries = MockCatalog.initialSchedule

    func fetchSchedule() async throws -> [ScheduleEntry] {
        entries.sorted(by: { $0.releaseDate < $1.releaseDate })
    }

    func updateNotificationsEnabled(for animeID: String, enabled: Bool) async throws {
        guard let index = entries.firstIndex(where: { $0.anime.id == animeID }) else { return }
        entries[index].notificationsEnabled = enabled
    }
}

@MainActor
final class MockLibraryRepository: LibraryRepository {
    private let defaults: UserDefaults
    private let key = "animeon.libraryEntries"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetchLibrarySections() async throws -> [LibrarySection] {
        let entries = loadEntries()

        return LibraryCategory.allCases.map { category in
            let items = entries
                .filter { $0.categories.contains(category) }
                .sorted(by: { $0.lastUpdated > $1.lastUpdated })
                .map { entry in
                    LibraryItem(
                        anime: MockCatalog.anime(with: entry.animeID),
                        entry: entry,
                        progress: entry.lastEpisodeID.map {
                            PlaybackProgress(
                                episodeID: $0,
                                animeID: entry.animeID,
                                progress: entry.progress,
                                positionSeconds: entry.lastPositionSeconds,
                                durationSeconds: max(entry.lastPositionSeconds / max(entry.progress, 0.01), 1),
                                lastUpdated: entry.lastUpdated
                            )
                        }
                    )
                }
            return LibrarySection(category: category, items: items)
        }
    }

    func fetchEntry(for animeID: String) async throws -> LibraryEntry? {
        loadEntries().first(where: { $0.animeID == animeID })
    }

    func updateCategory(_ category: LibraryCategory, animeID: String, isIncluded: Bool) async throws {
        var entries = loadEntries()
        if let index = entries.firstIndex(where: { $0.animeID == animeID }) {
            if isIncluded {
                if !entries[index].categories.contains(category) {
                    entries[index].categories.append(category)
                }
            } else {
                entries[index].categories.removeAll { $0 == category }
            }
            entries[index].lastUpdated = .now
        } else if isIncluded {
            entries.append(
                LibraryEntry(
                    animeID: animeID,
                    categories: [category],
                    lastEpisodeID: nil,
                    progress: 0,
                    lastPositionSeconds: 0,
                    lastUpdated: .now,
                    isDownloaded: false
                )
            )
        }
        persist(entries)
    }

    func markDownloaded(animeID: String, downloaded: Bool) async throws {
        var entries = loadEntries()
        if let index = entries.firstIndex(where: { $0.animeID == animeID }) {
            entries[index].isDownloaded = downloaded
            if downloaded, !entries[index].categories.contains(.downloaded) {
                entries[index].categories.append(.downloaded)
            }
            if !downloaded {
                entries[index].categories.removeAll { $0 == .downloaded }
            }
            entries[index].lastUpdated = .now
        } else {
            entries.append(
                LibraryEntry(
                    animeID: animeID,
                    categories: downloaded ? [.downloaded] : [],
                    lastEpisodeID: nil,
                    progress: 0,
                    lastPositionSeconds: 0,
                    lastUpdated: .now,
                    isDownloaded: downloaded
                )
            )
        }
        persist(entries)
    }

    func updatePlaybackProgress(_ progress: PlaybackProgress) async throws {
        var entries = loadEntries()
        if let index = entries.firstIndex(where: { $0.animeID == progress.animeID }) {
            entries[index].progress = progress.progress
            entries[index].lastEpisodeID = progress.episodeID
            entries[index].lastPositionSeconds = progress.positionSeconds
            entries[index].lastUpdated = progress.lastUpdated
            if !entries[index].categories.contains(.continueWatching), !progress.isFinished {
                entries[index].categories.append(.continueWatching)
            }
            if progress.isFinished {
                entries[index].categories.removeAll { $0 == .continueWatching }
                if !entries[index].categories.contains(.history) {
                    entries[index].categories.append(.history)
                }
            }
        } else {
            entries.append(
                LibraryEntry(
                    animeID: progress.animeID,
                    categories: progress.isFinished ? [.history] : [.continueWatching, .watching],
                    lastEpisodeID: progress.episodeID,
                    progress: progress.progress,
                    lastPositionSeconds: progress.positionSeconds,
                    lastUpdated: progress.lastUpdated,
                    isDownloaded: false
                )
            )
        }
        persist(entries)
    }

    private func loadEntries() -> [LibraryEntry] {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([LibraryEntry].self, from: data) {
            return decoded
        }
        persist(MockCatalog.seedLibraryEntries)
        return MockCatalog.seedLibraryEntries
    }

    private func persist(_ entries: [LibraryEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key)
    }
}

@MainActor
final class MockPlaybackRepository: PlaybackRepository {
    private let defaults: UserDefaults
    private let key = "animeon.playbackProgress"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetchProgress(for episodeID: String) async throws -> PlaybackProgress? {
        loadProgress().first(where: { $0.episodeID == episodeID })
    }

    func fetchRecentProgress() async throws -> [PlaybackProgress] {
        loadProgress().sorted(by: { $0.lastUpdated > $1.lastUpdated })
    }

    func saveProgress(_ progress: PlaybackProgress) async throws {
        var items = loadProgress()
        if let index = items.firstIndex(where: { $0.episodeID == progress.episodeID }) {
            items[index] = progress
        } else {
            items.append(progress)
        }
        persist(items)
    }

    private func loadProgress() -> [PlaybackProgress] {
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode([PlaybackProgress].self, from: data) {
            return decoded
        }
        persist(MockCatalog.seedProgress)
        return MockCatalog.seedProgress
    }

    private func persist(_ progress: [PlaybackProgress]) {
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: key)
    }
}

@MainActor
final class MockDownloadRepository: DownloadRepository {
    private let defaults: UserDefaults
    private let tasksKey = "animeon.downloadTasks"
    private let assetsKey = "animeon.downloadAssets"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func fetchTasks() async throws -> [DownloadTaskModel] {
        if let data = defaults.data(forKey: tasksKey),
           let decoded = try? JSONDecoder().decode([DownloadTaskModel].self, from: data) {
            return decoded
        }
        try await saveTasks(MockCatalog.seedDownloads)
        return MockCatalog.seedDownloads
    }

    func saveTasks(_ tasks: [DownloadTaskModel]) async throws {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        defaults.set(data, forKey: tasksKey)
    }

    func fetchAssets() async throws -> [LocalMediaAsset] {
        if let data = defaults.data(forKey: assetsKey),
           let decoded = try? JSONDecoder().decode([LocalMediaAsset].self, from: data) {
            return decoded
        }
        try await saveAssets(MockCatalog.seedAssets)
        return MockCatalog.seedAssets
    }

    func saveAssets(_ assets: [LocalMediaAsset]) async throws {
        guard let data = try? JSONEncoder().encode(assets) else { return }
        defaults.set(data, forKey: assetsKey)
    }
}

struct MockSessionRepository: SessionRepository {
    func restoreSession() async throws -> SessionState {
        .authenticated(MockCatalog.profile)
    }

    func saveSessionSnapshot(_ snapshot: AuthSessionSnapshot?) async throws { }
}

struct MockProfileRepository: ProfileRepository {
    func fetchProfile() async throws -> UserProfile {
        MockCatalog.profile
    }
}
