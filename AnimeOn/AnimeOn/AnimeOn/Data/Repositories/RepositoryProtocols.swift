import Foundation

protocol HomeRepository {
    func fetchHomeContent() async throws -> HomeContent
}

protocol SearchRepository {
    func fetchDiscovery() async throws -> SearchDiscoveryContent
    func search(query: String, filters: AnimeSearchFilters) async throws -> [Anime]
}

protocol AnimeRepository {
    func fetchAnime(id: String) async throws -> Anime
    func fetchRelatedTitles(for animeID: String) async throws -> [Anime]
}

protocol ScheduleRepository {
    func fetchSchedule() async throws -> [ScheduleEntry]
    func updateNotificationsEnabled(for animeID: String, enabled: Bool) async throws
}

protocol LibraryRepository {
    func fetchLibrarySections() async throws -> [LibrarySection]
    func fetchEntry(for animeID: String) async throws -> LibraryEntry?
    func updateCategory(_ category: LibraryCategory, animeID: String, isIncluded: Bool) async throws
    func markDownloaded(animeID: String, downloaded: Bool) async throws
    func updatePlaybackProgress(_ progress: PlaybackProgress) async throws
}

protocol PlaybackRepository {
    func fetchProgress(for episodeID: String) async throws -> PlaybackProgress?
    func fetchRecentProgress() async throws -> [PlaybackProgress]
    func saveProgress(_ progress: PlaybackProgress) async throws
}

protocol DownloadRepository {
    func fetchTasks() async throws -> [DownloadTaskModel]
    func saveTasks(_ tasks: [DownloadTaskModel]) async throws
    func fetchAssets() async throws -> [LocalMediaAsset]
    func saveAssets(_ assets: [LocalMediaAsset]) async throws
}

protocol SessionRepository {
    func restoreSession() async throws -> SessionState
    func saveSessionSnapshot(_ snapshot: AuthSessionSnapshot?) async throws
}

protocol ProfileRepository {
    func fetchProfile() async throws -> UserProfile
}
