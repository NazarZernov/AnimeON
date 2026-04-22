import Foundation

struct AnimeSearchFilters: Hashable {
    var genre: AnimeGenre?
    var year: Int?
    var status: AnimeStatus?
    var type: AnimeFormat?
    var minimumRating: Double?
    var studio: String?
    var supportsDub: Bool?
    var supportsSubtitles: Bool?

    static let `default` = AnimeSearchFilters()

    var isActive: Bool {
        genre != nil || year != nil || status != nil || type != nil || minimumRating != nil || studio != nil || supportsDub != nil || supportsSubtitles != nil
    }
}

struct PlayerContext: Equatable {
    let anime: Anime
    let episode: Episode
}

struct PlayerTrackOptions: Hashable {
    let audioOptions: [String]
    let subtitleOptions: [String]
    let qualityOptions: [String]
}

struct ShareableItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let url: URL
}
