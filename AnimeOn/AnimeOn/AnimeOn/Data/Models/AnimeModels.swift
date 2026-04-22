import Foundation

enum AnimeGenre: String, Codable, CaseIterable, Identifiable, Hashable {
    case action
    case adventure
    case comedy
    case drama
    case fantasy
    case mystery
    case romance
    case sciFi = "sci_fi"
    case sliceOfLife = "slice_of_life"
    case sports
    case thriller
    case supernatural

    var id: String { rawValue }

    var title: String {
        switch self {
        case .action: L10n.tr("Action")
        case .adventure: L10n.tr("Adventure")
        case .comedy: L10n.tr("Comedy")
        case .drama: L10n.tr("Drama")
        case .fantasy: L10n.tr("Fantasy")
        case .mystery: L10n.tr("Mystery")
        case .romance: L10n.tr("Romance")
        case .sciFi: L10n.tr("Sci-Fi")
        case .sliceOfLife: L10n.tr("Slice of Life")
        case .sports: L10n.tr("Sports")
        case .thriller: L10n.tr("Thriller")
        case .supernatural: L10n.tr("Supernatural")
        }
    }
}

enum AnimeFormat: String, Codable, CaseIterable, Hashable {
    case tv = "TV"
    case movie = "Movie"
    case ona = "ONA"
    case ova = "OVA"
    case special = "Special"

    var title: String {
        switch self {
        case .tv: L10n.tr("TV")
        case .movie: L10n.tr("Movie")
        case .ona: L10n.tr("ONA")
        case .ova: L10n.tr("OVA")
        case .special: L10n.tr("Special")
        }
    }
}

enum AnimeStatus: String, Codable, CaseIterable, Hashable {
    case airing = "Airing"
    case completed = "Completed"
    case upcoming = "Upcoming"
    case hiatus = "Hiatus"

    var title: String {
        switch self {
        case .airing: L10n.tr("Airing")
        case .completed: L10n.tr("Completed")
        case .upcoming: L10n.tr("Upcoming")
        case .hiatus: L10n.tr("Hiatus")
        }
    }
}

enum LibraryCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case continueWatching
    case watching
    case favorites
    case planned
    case history
    case downloaded

    var id: String { rawValue }

    var title: String {
        switch self {
        case .continueWatching: L10n.tr("Continue Watching")
        case .watching: L10n.tr("Watching")
        case .favorites: L10n.tr("Favorites")
        case .planned: L10n.tr("Watch Later")
        case .history: L10n.tr("History")
        case .downloaded: L10n.tr("Downloaded")
        }
    }

    var icon: String {
        switch self {
        case .continueWatching: "play.circle.fill"
        case .watching: "eye.fill"
        case .favorites: "heart.fill"
        case .planned: "bookmark.fill"
        case .history: "clock.fill"
        case .downloaded: "arrow.down.circle.fill"
        }
    }
}

struct Anime: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let originalTitle: String
    let synopsis: String
    let year: Int
    let format: AnimeFormat
    let episodeCount: Int
    let status: AnimeStatus
    let ageRating: String
    let averageRating: Double
    let studio: String
    let posterURL: URL?
    let backdropURL: URL?
    let genres: [AnimeGenre]
    let tags: [String]
    let seasons: [AnimeSeason]
    let relatedTitleIDs: [String]
}

struct AnimeSeason: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let number: Int
    let isCurrent: Bool
    let episodes: [Episode]
}

struct Episode: Identifiable, Codable, Hashable {
    let id: String
    let animeID: String
    let seasonID: String
    let number: Int
    let title: String
    let synopsis: String
    let durationMinutes: Int
    let thumbnailURL: URL?
    let isNew: Bool
    let dubCount: Int
    let subtitleCount: Int
    let videoURL: URL?
    let airDate: Date
}

struct HomeShelf: Identifiable, Hashable {
    enum Style: Hashable {
        case poster
        case wide
        case continueWatching
    }

    let id = UUID()
    let title: String
    let subtitle: String?
    let style: Style
    let items: [Anime]
}

struct HomeContent: Hashable {
    let featured: Anime
    let shelves: [HomeShelf]
}

struct SearchDiscoveryContent: Hashable {
    let trendingQueries: [String]
    let featuredGenres: [AnimeGenre]
    let spotlightTitles: [Anime]
}

struct ScheduleEntry: Identifiable, Hashable {
    let id = UUID()
    let anime: Anime
    let episode: Episode
    let releaseDate: Date
    let isWatched: Bool
    var notificationsEnabled: Bool
}
