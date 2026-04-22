import Foundation

struct PlaybackProgress: Identifiable, Codable, Hashable {
    var id: String { episodeID }
    let episodeID: String
    let animeID: String
    var progress: Double
    var positionSeconds: Double
    var durationSeconds: Double
    var lastUpdated: Date

    var isFinished: Bool { progress >= 0.92 }
}

struct LibraryEntry: Identifiable, Codable, Hashable {
    var id: String { animeID }
    let animeID: String
    var categories: [LibraryCategory]
    var lastEpisodeID: String?
    var progress: Double
    var lastPositionSeconds: Double
    var lastUpdated: Date
    var isDownloaded: Bool
}

struct LibraryItem: Identifiable, Hashable {
    var id: String { anime.id }
    let anime: Anime
    let entry: LibraryEntry
    let progress: PlaybackProgress?
}

struct LibrarySection: Identifiable, Hashable {
    var id: String { category.rawValue }
    let category: LibraryCategory
    let items: [LibraryItem]
}

struct UserProfile: Identifiable, Codable, Hashable {
    let id: String
    var nickname: String
    var avatarSymbolName: String
    var levelTitle: String
    var badges: [String]
    var preferredGenres: [AnimeGenre]
    var totalWatchedHours: Int
    var totalEpisodes: Int
}

struct ProfileStats: Hashable {
    let favoritesCount: Int
    let downloadedStorageText: String
    let continueWatchingCount: Int
}

enum SessionState: Equatable {
    case loading
    case signedOut
    case authenticated(UserProfile)
}

struct AuthSessionSnapshot: Codable, Equatable {
    var accessToken: String?
    var refreshToken: String?
    var cookieNames: [String]
    var expiresAt: Date?
}
