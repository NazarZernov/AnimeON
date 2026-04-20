import Foundation

enum AnimeType: String, Codable, CaseIterable, Identifiable {
    case tv = "TV"
    case movie = "Movie"
    case ona = "ONA"
    case ova = "OVA"
    case special = "Special"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .tv: "TV Сериал"
        case .movie: "Фильм"
        case .ona: "ONA"
        case .ova: "OVA"
        case .special: "Спешл"
        }
    }
}

enum AnimeStatus: String, Codable, CaseIterable, Identifiable {
    case ongoing = "ongoing"
    case released = "released"
    case upcoming = "upcoming"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .ongoing: "Онгоинг"
        case .released: "Вышел"
        case .upcoming: "Анонс"
        }
    }
}

struct Anime: Identifiable, Codable, Hashable {
    let id: Int
    let slug: String
    let title: String
    let originalTitle: String
    let subtitle: String
    let synopsis: String
    let extendedSynopsis: String
    let posterURL: URL
    let bannerURL: URL
    let rating: Double
    let ratingVotes: Int
    let year: Int
    let type: AnimeType
    let status: AnimeStatus
    let episodeDurationMinutes: Int
    let releasedEpisodes: Int
    let totalEpisodes: Int
    let ageRating: String
    let studio: String
    let genres: [String]
    let tags: [String]
    let featuredQuote: String
    let viewsCount: Int
    let watchHours: Int
    let isPremiumOnlyQualityAvailable: Bool

    var progressText: String {
        "\(releasedEpisodes) / \(totalEpisodes)"
    }
}
