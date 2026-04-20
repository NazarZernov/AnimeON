import Foundation

private struct AuthPayload: Encodable {
    let email: String
    let password: String
}

private struct WatchlistPayload: Encodable {
    let animeID: Int
    let action: String
}

private struct ReactionRequest: Encodable {
    let animeID: Int
    let isLiked: Bool
}

private struct RatingRequest: Encodable {
    let animeID: Int
    let rating: Int
}

private struct AnimeOnCatalogResponse: Decodable {
    let items: [AnimeOnAnimeDTO]
    let page: Int
    let totalCount: Int
    let totalPages: Int

    private enum CodingKeys: String, CodingKey {
        case items
        case page
        case totalCount = "total_count"
        case totalPages = "total_pages"
    }
}

private struct AnimeOnSearchResponse: Decodable {
    let results: [AnimeOnAnimeDTO]
    let totalCount: Int

    private enum CodingKeys: String, CodingKey {
        case results
        case totalCount = "total_count"
    }
}

private struct AnimeOnAnimeDTO: Decodable {
    let id: String?
    let animePoster: String?
    let animeURL: String?
    let description: String?
    let poster: String?
    let rating: Double?
    let shikimoriID: String?
    let status: String?
    let title: String
    let originalTitle: String?
    let votesCount: Int?
    let year: Int?
    let kind: String?
    let materialData: AnimeOnMaterialData?
    let translations: [String: AnimeOnTranslation]?
    let episodeScreenshots: [String: [String]]?

    private enum CodingKeys: String, CodingKey {
        case id
        case animePoster = "anime_poster"
        case animeURL = "anime_url"
        case description
        case poster
        case rating
        case shikimoriID = "shikimori_id"
        case status
        case title
        case originalTitle = "title_orig"
        case votesCount = "votes_count"
        case year
        case kind
        case materialData = "material_data"
        case translations
        case episodeScreenshots = "episode_screenshots"
    }
}

private struct AnimeOnMaterialData: Decodable {
    let animeGenres: [String]
    let animeKind: String?
    let animeStatus: String?
    let animeStudios: [String]
    let animeTitle: String?
    let description: String?
    let animeDescription: String?
    let duration: Int?
    let episodesAired: Int?
    let episodesTotal: Int?
    let posterURL: String?
    let shikimoriRating: Double?
    let shikimoriVotes: Int?
    let titleEN: String?
    let year: Int?
    let airedAt: String?

    private enum CodingKeys: String, CodingKey {
        case animeGenres = "anime_genres"
        case animeKind = "anime_kind"
        case animeStatus = "anime_status"
        case animeStudios = "anime_studios"
        case animeTitle = "anime_title"
        case description
        case animeDescription = "anime_description"
        case duration
        case episodesAired = "episodes_aired"
        case episodesTotal = "episodes_total"
        case posterURL = "poster_url"
        case shikimoriRating = "shikimori_rating"
        case shikimoriVotes = "shikimori_votes"
        case titleEN = "title_en"
        case year
        case airedAt = "aired_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        animeGenres = try container.decodeIfPresent([String].self, forKey: .animeGenres) ?? []
        animeKind = try container.decodeIfPresent(String.self, forKey: .animeKind)
        animeStatus = try container.decodeIfPresent(String.self, forKey: .animeStatus)
        animeTitle = try container.decodeIfPresent(String.self, forKey: .animeTitle)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        animeDescription = try container.decodeIfPresent(String.self, forKey: .animeDescription)
        duration = try container.decodeIfPresent(Int.self, forKey: .duration)
        episodesAired = try container.decodeIfPresent(Int.self, forKey: .episodesAired)
        episodesTotal = try container.decodeIfPresent(Int.self, forKey: .episodesTotal)
        posterURL = try container.decodeIfPresent(String.self, forKey: .posterURL)
        shikimoriRating = try container.decodeIfPresent(Double.self, forKey: .shikimoriRating)
        shikimoriVotes = try container.decodeIfPresent(Int.self, forKey: .shikimoriVotes)
        titleEN = try container.decodeIfPresent(String.self, forKey: .titleEN)
        year = try container.decodeIfPresent(Int.self, forKey: .year)
        airedAt = try container.decodeIfPresent(String.self, forKey: .airedAt)

        if let studios = try container.decodeIfPresent([String].self, forKey: .animeStudios) {
            animeStudios = studios
        } else if let singleStudio = try container.decodeIfPresent(String.self, forKey: .animeStudios) {
            animeStudios = [singleStudio]
        } else {
            animeStudios = []
        }
    }
}

private struct AnimeOnTranslation: Decodable {
    let episodes: [String: AnimeOnTranslationEpisode]
    let isActive: Bool
    let season: Int?
    let type: String?

    private enum CodingKeys: String, CodingKey {
        case episodes
        case isActive = "is_active"
        case season
        case type
    }
}

private struct AnimeOnTranslationEpisode: Decodable {
    let link: String?
    let screenshots: [String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        link = try container.decodeIfPresent(String.self, forKey: .link)
        screenshots = try container.decodeIfPresent([String].self, forKey: .screenshots) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case link
        case screenshots
    }
}

final class RemoteAnimeService: AnimeServicing {
    private let client: NetworkClient
    private let siteRoot: URL

    init(baseURL: URL) {
        client = NetworkClient(baseURL: baseURL)
        siteRoot = URL(string: "/", relativeTo: baseURL)?.absoluteURL ?? URL(string: "https://animeon.su")!
    }

    func fetchHome() async throws -> HomePayload {
        async let popular = fetchCatalog(page: 1, pageSize: 12, filters: CatalogFilters(sort: .popular))
        async let rating = fetchCatalog(page: 1, pageSize: 12, filters: CatalogFilters(sort: .rating))
        async let ongoing = fetchCatalog(page: 1, pageSize: 12, filters: CatalogFilters(status: .ongoing, sort: .ongoing))
        async let recent = fetchCatalog(page: 1, pageSize: 12, filters: CatalogFilters(sort: .recentlyUpdated))

        let popularPage = try await popular
        let ratingPage = try await rating
        let ongoingPage = try await ongoing
        let recentPage = try await recent

        guard let featured = popularPage.items.first ?? ratingPage.items.first ?? ongoingPage.items.first ?? recentPage.items.first else {
            throw NetworkError.emptyBody
        }

        return HomePayload(
            featured: featured,
            popularOngoing: Array((ongoingPage.items.isEmpty ? popularPage.items : ongoingPage.items).prefix(8)),
            newEpisodes: Array((recentPage.items.isEmpty ? popularPage.items : recentPage.items).prefix(8)),
            popularAllTime: Array(popularPage.items.prefix(8)),
            topHundred: Array((ratingPage.items.isEmpty ? popularPage.items : ratingPage.items).prefix(10)),
            leaderboard: []
        )
    }

    func fetchCatalog(page: Int, pageSize: Int, filters: CatalogFilters) async throws -> CatalogResponse {
        let trimmedQuery = filters.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            let response: AnimeOnSearchResponse = try await client.send(
                APIRequest(
                    path: "/search",
                    method: .get,
                    queryItems: [URLQueryItem(name: "q", value: trimmedQuery)]
                ),
                as: AnimeOnSearchResponse.self
            )
            return makeCatalogResponse(
                from: response.results,
                page: page,
                requestedPageSize: pageSize,
                totalCount: response.totalCount,
                filters: filters,
                shouldSlicePage: true
            )
        }

        let response: AnimeOnCatalogResponse = try await client.send(
            APIRequest(
                path: "/anime",
                method: .get,
                queryItems: [URLQueryItem(name: "page", value: String(page))]
            ),
            as: AnimeOnCatalogResponse.self
        )
        return makeCatalogResponse(
            from: response.items,
            page: response.page,
            requestedPageSize: pageSize,
            totalCount: response.totalCount,
            filters: filters,
            shouldSlicePage: false
        )
    }

    func fetchAnime(id: Int) async throws -> Anime {
        let dto: AnimeOnAnimeDTO = try await client.send(APIRequest(path: "/anime/\(id)", method: .get), as: AnimeOnAnimeDTO.self)
        guard let anime = mapAnime(from: dto) else {
            throw NetworkError.invalidResponse
        }
        return anime
    }

    func fetchEpisodes(animeID: Int) async throws -> [Episode] {
        let dto: AnimeOnAnimeDTO = try await client.send(APIRequest(path: "/anime/\(animeID)", method: .get), as: AnimeOnAnimeDTO.self)
        return mapEpisodes(from: dto, animeID: animeID)
    }

    func search(query: String) async throws -> [Anime] {
        let response: AnimeOnSearchResponse = try await client.send(
            APIRequest(
                path: "/search",
                method: .get,
                queryItems: [URLQueryItem(name: "q", value: query.trimmingCharacters(in: .whitespacesAndNewlines))]
            ),
            as: AnimeOnSearchResponse.self
        )
        return sortAnimeList(response.results.compactMap(mapAnime(from:)), by: .popular)
    }

    func randomAnime() async throws -> Anime {
        let catalog = try await fetchCatalog(page: 1, pageSize: 48, filters: CatalogFilters(sort: .popular))
        guard let random = catalog.items.randomElement() else {
            throw NetworkError.emptyBody
        }
        return random
    }

    func fetchSchedule() async throws -> [ScheduleDay] {
        []
    }

    func fetchUpdates() async throws -> [UpdateItem] {
        let catalog = try await fetchCatalog(page: 1, pageSize: 8, filters: CatalogFilters(sort: .recentlyUpdated))
        return catalog.items.prefix(6).enumerated().map { index, anime in
            UpdateItem(
                id: anime.id * 100 + index,
                animeID: anime.id,
                animeTitle: anime.title,
                episodeNumber: anime.releasedEpisodes,
                summary: anime.genres.prefix(3).joined(separator: " • "),
                publishedAt: Calendar.current.date(byAdding: .hour, value: -index * 6, to: .now) ?? .now
            )
        }
    }

    func fetchNews() async throws -> [NewsItem] {
        []
    }

    func fetchPremiumPlans() async throws -> [PremiumPlan] {
        try await client.send(APIRequest(path: "/premium", method: .get), as: [PremiumPlan].self)
    }

    func login(email: String, password: String) async throws -> UserSession {
        try await client.send(
            APIRequest(
                path: "/auth/login",
                method: .post,
                body: AuthPayload(email: email, password: password)
            ),
            as: UserSession.self
        )
    }

    func fetchProfile() async throws -> UserProfile {
        try await client.send(APIRequest(path: "/user/profile", method: .get), as: UserProfile.self)
    }

    func updateWatchlist(animeID: Int, action: WatchlistAction) async throws {
        try await client.send(
            APIRequest(
                path: "/user/watchlist",
                method: .post,
                body: WatchlistPayload(animeID: animeID, action: action.rawValue)
            )
        )
    }

    func updateHistory(entry: WatchHistoryEntry) async throws {
        try await client.send(
            APIRequest(
                path: "/user/history",
                method: .post,
                body: entry
            )
        )
    }

    func updateProgress(_ payload: PlaybackProgressPayload) async throws {
        try await client.send(
            APIRequest(
                path: "/user/progress",
                method: .post,
                body: payload
            )
        )
    }

    func updateReaction(_ payload: AnimeReactionPayload) async throws {
        try await client.send(
            APIRequest(
                path: "/user/reactions",
                method: .post,
                body: ReactionRequest(animeID: payload.animeID, isLiked: payload.isLiked)
            )
        )
    }

    func updateRating(_ payload: AnimeRatingPayload) async throws {
        try await client.send(
            APIRequest(
                path: "/user/ratings",
                method: .post,
                body: RatingRequest(animeID: payload.animeID, rating: payload.rating)
            )
        )
    }

    func postStats(_ event: UserStatEvent) async throws {
        try await client.send(
            APIRequest(
                path: "/user/stats",
                method: .post,
                body: event
            )
        )
    }

    private func makeCatalogResponse(
        from items: [AnimeOnAnimeDTO],
        page: Int,
        requestedPageSize: Int,
        totalCount: Int,
        filters: CatalogFilters,
        shouldSlicePage: Bool
    ) -> CatalogResponse {
        var mapped = items.compactMap(mapAnime(from:))
        mapped = applyFilters(filters, to: mapped)
        mapped = sortAnimeList(mapped, by: filters.sort)

        if shouldSlicePage {
            let startIndex = max(0, (page - 1) * requestedPageSize)
            let endIndex = min(mapped.count, startIndex + requestedPageSize)
            mapped = startIndex < endIndex ? Array(mapped[startIndex..<endIndex]) : []
        }

        let effectivePageSize = max(requestedPageSize, mapped.count)
        let effectiveTotalCount = shouldSlicePage ? max(totalCount, mapped.count) : totalCount

        return CatalogResponse(
            items: mapped,
            page: page,
            pageSize: effectivePageSize,
            totalCount: effectiveTotalCount
        )
    }

    private func mapAnime(from dto: AnimeOnAnimeDTO) -> Anime? {
        let animeID = resolvedAnimeID(for: dto)
        guard animeID > 0 else { return nil }

        let genres = dto.materialData?.animeGenres ?? []
        let type = mapAnimeType(dto.kind ?? dto.materialData?.animeKind)
        let releasedEpisodes = max(dto.materialData?.episodesAired ?? 0, 0)
        let totalEpisodes = max(dto.materialData?.episodesTotal ?? releasedEpisodes, releasedEpisodes)
        let status = mapAnimeStatus(
            rawValue: dto.status ?? dto.materialData?.animeStatus,
            releasedEpisodes: releasedEpisodes,
            totalEpisodes: totalEpisodes
        )
        let year = dto.year ?? dto.materialData?.year ?? Calendar.current.component(.year, from: .now)
        let posterURL = absoluteURL(from: dto.poster)
            ?? absoluteURL(from: dto.animePoster)
            ?? absoluteURL(from: dto.materialData?.posterURL)
            ?? siteRoot
        let bannerURL = absoluteURL(from: dto.episodeScreenshots?["1"]?.first)
            ?? absoluteURL(from: dto.materialData?.posterURL)
            ?? absoluteURL(from: dto.animePoster)
            ?? posterURL
        let fullDescription = cleanedText(dto.description ?? dto.materialData?.description ?? dto.materialData?.animeDescription)
        let synopsis = shortSynopsis(from: fullDescription)
        let originalTitle = dto.originalTitle?.nilIfBlank
            ?? dto.materialData?.titleEN?.nilIfBlank
            ?? dto.title
        let studio = dto.materialData?.animeStudios.joined(separator: ", ").nilIfBlank ?? "AnimeOn"
        let rating = dto.rating ?? dto.materialData?.shikimoriRating ?? 0
        let ratingVotes = dto.votesCount ?? dto.materialData?.shikimoriVotes ?? 0
        let durationMinutes = max(dto.materialData?.duration ?? 24, 1)
        let subtitleParts = [
            type.localizedTitle,
            "\(year)",
            genres.prefix(2).joined(separator: " • ").nilIfBlank
        ].compactMap { $0?.nilIfBlank }

        return Anime(
            id: animeID,
            slug: dto.animeURL?.nilIfBlank ?? "anime-\(animeID)",
            title: cleanedText(dto.title),
            originalTitle: cleanedText(originalTitle),
            subtitle: subtitleParts.joined(separator: " • "),
            synopsis: synopsis,
            extendedSynopsis: fullDescription.nilIfBlank ?? synopsis,
            posterURL: posterURL,
            bannerURL: bannerURL,
            rating: rating,
            ratingVotes: ratingVotes,
            year: year,
            type: type,
            status: status,
            episodeDurationMinutes: durationMinutes,
            releasedEpisodes: releasedEpisodes,
            totalEpisodes: totalEpisodes,
            ageRating: inferredAgeRating(from: fullDescription),
            studio: studio,
            genres: genres,
            tags: genres,
            featuredQuote: firstSentence(in: fullDescription) ?? cleanedText(dto.title),
            viewsCount: ratingVotes,
            watchHours: max(1, (durationMinutes * max(releasedEpisodes, 1)) / 60),
            isPremiumOnlyQualityAvailable: false
        )
    }

    private func mapEpisodes(from dto: AnimeOnAnimeDTO, animeID: Int) -> [Episode] {
        let translations = dto.translations ?? [:]
        let episodeNumbers = translations.values
            .flatMap { $0.episodes.keys }
            .compactMap(Int.init)
            .sorted()

        let uniqueEpisodeNumbers = Array(Set(episodeNumbers)).sorted()
        let durationMinutes = max(dto.materialData?.duration ?? 24, 1)
        let airDate = parseDate(dto.materialData?.airedAt) ?? .now
        let fallbackThumbnail = absoluteURL(from: dto.poster)
            ?? absoluteURL(from: dto.animePoster)
            ?? siteRoot
        let fallbackSynopsis = shortSynopsis(from: cleanedText(dto.description ?? dto.materialData?.animeDescription))

        return uniqueEpisodeNumbers.compactMap { number in
            let playbackSources = translations
                .sorted { lhs, rhs in
                    if lhs.value.isActive != rhs.value.isActive {
                        return lhs.value.isActive && !rhs.value.isActive
                    }
                    return lhs.key.localizedCaseInsensitiveCompare(rhs.key) == .orderedAscending
                }
                .compactMap { translationName, translation -> PlaybackSource? in
                    guard
                        let payload = translation.episodes[String(number)],
                        let rawLink = payload.link,
                        let streamURL = absolutePlaybackURL(from: rawLink)
                    else {
                        return nil
                    }

                    let sourceID = "\(animeID)-\(number)-\(translationName)".replacingOccurrences(of: " ", with: "-")
                    let label = qualityLabel(from: streamURL)
                    let trackCode = translationName.lowercased().contains("суб") ? "ja" : "ru"

                    return PlaybackSource(
                        id: sourceID,
                        title: translationName,
                        kind: inferPlaybackSourceKind(from: streamURL),
                        streamURL: streamURL,
                        downloadURL: nil,
                        qualities: [
                            StreamQualityOption(id: "\(sourceID)-quality", label: label, url: streamURL)
                        ],
                        audioTracks: [
                            AudioTrack(id: "\(sourceID)-audio", title: translationName, languageCode: trackCode)
                        ]
                    )
                }

            guard let primarySource = playbackSources.first else {
                return nil
            }

            let screenshots = translations.values
                .compactMap { $0.episodes[String(number)]?.screenshots.first }
            let thumbnailURL = absoluteURL(from: screenshots.first)
                ?? absoluteURL(from: dto.episodeScreenshots?[String(number)]?.first)
                ?? fallbackThumbnail

            return Episode(
                id: animeID * 10_000 + number,
                animeID: animeID,
                number: number,
                title: "Эпизод \(number)",
                synopsis: fallbackSynopsis,
                durationMinutes: durationMinutes,
                airDate: airDate,
                thumbnailURL: thumbnailURL,
                streamURL: primarySource.streamURL,
                downloadURL: primarySource.streamURL,
                isReleased: true,
                playbackSources: playbackSources
            )
        }
    }

    private func applyFilters(_ filters: CatalogFilters, to items: [Anime]) -> [Anime] {
        items.filter { anime in
            let matchesGenres = filters.genres.isEmpty || !filters.genres.isDisjoint(with: Set(anime.genres))
            let matchesYear = filters.yearRange.contains(anime.year)
            let matchesType = filters.type == nil || anime.type == filters.type
            let matchesStatus = filters.status == nil || anime.status == filters.status
            let matchesRating = anime.rating >= filters.minimumRating
            let matchesQuery: Bool
            if filters.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                matchesQuery = true
            } else {
                let query = filters.searchText.lowercased()
                matchesQuery = anime.title.lowercased().contains(query)
                    || anime.originalTitle.lowercased().contains(query)
                    || anime.genres.joined(separator: " ").lowercased().contains(query)
            }

            return matchesGenres && matchesYear && matchesType && matchesStatus && matchesRating && matchesQuery
        }
    }

    private func sortAnimeList(_ items: [Anime], by sort: CatalogSort) -> [Anime] {
        switch sort {
        case .popular:
            return items.sorted { lhs, rhs in
                if lhs.ratingVotes != rhs.ratingVotes { return lhs.ratingVotes > rhs.ratingVotes }
                return lhs.rating > rhs.rating
            }
        case .rating:
            return items.sorted { lhs, rhs in
                if lhs.rating != rhs.rating { return lhs.rating > rhs.rating }
                return lhs.ratingVotes > rhs.ratingVotes
            }
        case .newest:
            return items.sorted { lhs, rhs in
                if lhs.year != rhs.year { return lhs.year > rhs.year }
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
        case .ongoing:
            return items.sorted { lhs, rhs in
                if lhs.status != rhs.status { return lhs.status == .ongoing }
                return lhs.rating > rhs.rating
            }
        case .recentlyUpdated:
            return items.sorted { lhs, rhs in
                if lhs.releasedEpisodes != rhs.releasedEpisodes { return lhs.releasedEpisodes > rhs.releasedEpisodes }
                if lhs.year != rhs.year { return lhs.year > rhs.year }
                return lhs.rating > rhs.rating
            }
        }
    }

    private func resolvedAnimeID(for dto: AnimeOnAnimeDTO) -> Int {
        if let shikimoriID = dto.shikimoriID, let value = Int(shikimoriID) {
            return value
        }

        if let slug = dto.animeURL, let suffix = slug.split(separator: "-").last, let value = Int(suffix) {
            return value
        }

        return Int(dto.id ?? "") ?? 0
    }

    private func mapAnimeType(_ rawValue: String?) -> AnimeType {
        let value = rawValue?.lowercased() ?? ""
        if value.contains("movie") {
            return .movie
        }
        if value.contains("ova") {
            return .ova
        }
        if value.contains("ona") {
            return .ona
        }
        if value.contains("special") {
            return .special
        }
        return .tv
    }

    private func mapAnimeStatus(rawValue: String?, releasedEpisodes: Int, totalEpisodes: Int) -> AnimeStatus {
        switch rawValue?.lowercased() {
        case "ongoing":
            return .ongoing
        case "released", "completed":
            return .released
        case "upcoming", "announced", "anons":
            return .upcoming
        default:
            if totalEpisodes == 0 && releasedEpisodes == 0 {
                return .upcoming
            }
            if totalEpisodes > 0 && releasedEpisodes < totalEpisodes {
                return .ongoing
            }
            return releasedEpisodes == 0 ? .upcoming : .released
        }
    }

    private func absoluteURL(from rawValue: String?) -> URL? {
        guard let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        if trimmed.hasPrefix("//") {
            return URL(string: "https:\(trimmed)")
        }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: trimmed, relativeTo: siteRoot)?.absoluteURL
    }

    private func absolutePlaybackURL(from rawValue: String) -> URL? {
        absoluteURL(from: rawValue)
    }

    private func inferPlaybackSourceKind(from url: URL) -> PlaybackSourceKind {
        url.pathExtension.lowercased() == "m3u8" ? .hls : .mp4
    }

    private func qualityLabel(from url: URL) -> String {
        if url.absoluteString.localizedCaseInsensitiveContains("1080") {
            return "1080p"
        }
        if url.absoluteString.localizedCaseInsensitiveContains("720") {
            return "720p"
        }
        if url.pathExtension.lowercased() == "m3u8" {
            return "Auto"
        }
        return "Source"
    }

    private func cleanedText(_ value: String?) -> String {
        guard let value else { return "" }
        return value
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func shortSynopsis(from value: String) -> String {
        let trimmed = cleanedText(value)
        guard trimmed.count > 220 else { return trimmed }
        return String(trimmed.prefix(217)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private func firstSentence(in value: String) -> String? {
        cleanedText(value)
            .split(separator: ".", maxSplits: 1)
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nilIfBlank
    }

    private func inferredAgeRating(from description: String) -> String {
        if description.contains("18+") {
            return "18+"
        }
        if description.contains("16+") {
            return "16+"
        }
        if description.contains("12+") {
            return "12+"
        }
        return "16+"
    }

    private func parseDate(_ rawValue: String?) -> Date? {
        guard let rawValue = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines), !rawValue.isEmpty else {
            return nil
        }

        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: rawValue) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = formatter.date(from: rawValue) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: rawValue)
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
