import Foundation

struct AnimeRatingRecord: Identifiable, Codable, Hashable {
    let animeID: Int
    let rating: Int

    var id: Int { animeID }
}

struct WatchlistMutation: Codable, Hashable {
    let animeID: Int
    let action: WatchlistAction
}

struct PlaybackProgressPayload: Codable, Hashable {
    let animeID: Int
    let episodeID: Int
    let progressSeconds: Double
    let durationSeconds: Double
    let updatedAt: Date
}

struct AnimeReactionPayload: Codable, Hashable {
    let animeID: Int
    let isLiked: Bool
}

struct AnimeRatingPayload: Codable, Hashable {
    let animeID: Int
    let rating: Int
}

struct WatchHistoryEntry: Identifiable, Codable, Hashable {
    let id: Int
    let animeID: Int
    let episodeID: Int
    let progressSeconds: Double
    let lastWatchedAt: Date
}

struct UserProfile: Identifiable, Codable, Hashable {
    let id: Int
    let username: String
    let displayName: String
    let avatarURL: URL
    let isPremium: Bool
    let level: Int
    let watchHours: Int
    let streakDays: Int
    var watchlistIDs: [Int]
    var history: [WatchHistoryEntry]
    let badges: [String]
    var likedAnimeIDs: [Int]
    var ratings: [AnimeRatingRecord]

    private enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName
        case avatarURL
        case isPremium
        case level
        case watchHours
        case streakDays
        case watchlistIDs
        case history
        case badges
        case likedAnimeIDs
        case ratings
    }

    init(
        id: Int,
        username: String,
        displayName: String,
        avatarURL: URL,
        isPremium: Bool,
        level: Int,
        watchHours: Int,
        streakDays: Int,
        watchlistIDs: [Int],
        history: [WatchHistoryEntry],
        badges: [String],
        likedAnimeIDs: [Int] = [],
        ratings: [AnimeRatingRecord] = []
    ) {
        self.id = id
        self.username = username
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.isPremium = isPremium
        self.level = level
        self.watchHours = watchHours
        self.streakDays = streakDays
        self.watchlistIDs = watchlistIDs
        self.history = history
        self.badges = badges
        self.likedAnimeIDs = likedAnimeIDs
        self.ratings = ratings
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        username = try container.decode(String.self, forKey: .username)
        displayName = try container.decode(String.self, forKey: .displayName)
        avatarURL = try container.decode(URL.self, forKey: .avatarURL)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        level = try container.decode(Int.self, forKey: .level)
        watchHours = try container.decode(Int.self, forKey: .watchHours)
        streakDays = try container.decode(Int.self, forKey: .streakDays)
        watchlistIDs = try container.decode([Int].self, forKey: .watchlistIDs)
        history = try container.decode([WatchHistoryEntry].self, forKey: .history)
        badges = try container.decode([String].self, forKey: .badges)
        likedAnimeIDs = try container.decodeIfPresent([Int].self, forKey: .likedAnimeIDs) ?? []
        ratings = try container.decodeIfPresent([AnimeRatingRecord].self, forKey: .ratings) ?? []
    }

    var watchedEpisodesCount: Int {
        history.count
    }

    var activityCount: Int {
        watchedEpisodesCount + likedAnimeIDs.count + ratings.count
    }
}

struct UserSession: Codable, Hashable {
    let token: String
    let profile: UserProfile
}

enum WatchlistAction: String, Codable {
    case add
    case remove
}

struct UserStatEvent: Codable, Hashable {
    let name: String
    let value: Int
}
