import Foundation

enum CatalogSort: String, CaseIterable, Codable, Identifiable {
    case popular = "popular"
    case rating = "rating"
    case newest = "newest"
    case ongoing = "ongoing"
    case recentlyUpdated = "recentlyUpdated"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .popular: "Популярные"
        case .rating: "По рейтингу"
        case .newest: "По году"
        case .ongoing: "Онгоинги"
        case .recentlyUpdated: "Новые серии"
        }
    }
}

struct CatalogFilters: Codable, Hashable {
    static let minimumYear = 1980
    static var currentYear: Int {
        Calendar.current.component(.year, from: .now)
    }

    var searchText: String
    var genres: Set<String>
    var yearRange: ClosedRange<Int>
    var type: AnimeType?
    var status: AnimeStatus?
    var minimumRating: Double
    var sort: CatalogSort

    init(
        searchText: String = "",
        genres: Set<String> = [],
        yearRange: ClosedRange<Int> = CatalogFilters.minimumYear...CatalogFilters.currentYear,
        type: AnimeType? = nil,
        status: AnimeStatus? = nil,
        minimumRating: Double = 0,
        sort: CatalogSort = .popular
    ) {
        self.searchText = searchText
        self.genres = genres
        self.yearRange = yearRange
        self.type = type
        self.status = status
        self.minimumRating = minimumRating
        self.sort = sort
    }

    var yearSummary: String {
        "\(yearRange.lowerBound) - \(yearRange.upperBound)"
    }
}

struct CatalogResponse: Codable, Hashable {
    let items: [Anime]
    let page: Int
    let pageSize: Int
    let totalCount: Int

    var hasNextPage: Bool {
        page * pageSize < totalCount
    }
}
