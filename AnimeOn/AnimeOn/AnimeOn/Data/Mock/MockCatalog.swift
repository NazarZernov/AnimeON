import Foundation

enum MockCatalog {
    static let fallbackAnime = Anime(
        id: "fallback",
        title: "AnimeOn Original",
        originalTitle: "AnimeOn Original",
        synopsis: "A fallback title used only for previews and placeholders.",
        year: 2026,
        format: .tv,
        episodeCount: 12,
        status: .airing,
        ageRating: "16+",
        averageRating: 8.9,
        studio: "Studio Native",
        posterURL: URL(string: "https://picsum.photos/seed/animeon-fallback/600/900"),
        backdropURL: URL(string: "https://picsum.photos/seed/animeon-fallback-backdrop/1600/900"),
        genres: [.action, .sciFi],
        tags: ["Native", "Premium"],
        seasons: [],
        relatedTitleIDs: []
    )

    static let sampleVideoURL = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")

    static let titles: [Anime] = [
        makeAnime(
            id: "solar-drift-404",
            title: "Solar Drift 404",
            originalTitle: "Solar Drift 404",
            synopsis: "A salvage pilot chases forbidden signals through a ring of ruined orbital stations while a vanished idol from an old broadcast keeps appearing in the static. Every rescue mission drags the crew closer to the blackout at the center of the system.",
            year: 2026,
            format: .tv,
            status: .airing,
            ageRating: "16+",
            rating: 9.2,
            studio: "Aster Frame",
            posterSeed: "solar-drift-poster",
            backdropSeed: "solar-drift-backdrop",
            genres: [.sciFi, .action, .mystery],
            tags: ["Space Opera", "Premium Dub", "Weekly Hit"],
            seasonTitles: ["Season 1"],
            episodesPerSeason: [12],
            related: ["last-orbit-refrain", "northern-signal"]
        ),
        makeAnime(
            id: "velvet-zero",
            title: "Velvet Zero",
            originalTitle: "Velvet Zero",
            synopsis: "In a city where memory can be edited like film, an elite courier carries sealed recollections for clients wealthy enough to erase regret. When a package contains her own forgotten childhood, every elegant routine begins to fracture.",
            year: 2025,
            format: .tv,
            status: .completed,
            ageRating: "18+",
            rating: 8.8,
            studio: "Nocturne Works",
            posterSeed: "velvet-zero-poster",
            backdropSeed: "velvet-zero-backdrop",
            genres: [.thriller, .drama, .mystery],
            tags: ["Cyber Noir", "Psychological", "Subtitled"],
            seasonTitles: ["Book I", "Book II"],
            episodesPerSeason: [10, 10],
            related: ["paper-cranes-midnight", "blue-hour-district"]
        ),
        makeAnime(
            id: "northern-signal",
            title: "Northern Signal",
            originalTitle: "Northern Signal",
            synopsis: "A small coastal town in winter begins receiving radio broadcasts from tomorrow. A young emergency operator can save lives by listening, but each rescue changes the next transmission in ways she cannot predict.",
            year: 2024,
            format: .tv,
            status: .completed,
            ageRating: "13+",
            rating: 8.6,
            studio: "Harborline",
            posterSeed: "northern-signal-poster",
            backdropSeed: "northern-signal-backdrop",
            genres: [.drama, .supernatural, .thriller],
            tags: ["Mystery Box", "Emotional", "Best in Class"],
            seasonTitles: ["Season 1"],
            episodesPerSeason: [13],
            related: ["solar-drift-404", "blue-hour-district"]
        ),
        makeAnime(
            id: "paper-cranes-midnight",
            title: "Paper Cranes at Midnight",
            originalTitle: "Paper Cranes at Midnight",
            synopsis: "An overworked pianist returns to her childhood district and discovers a tiny ramen bar where folded paper cranes can rewind one moment from a customer’s life. The miracle feels kind until people start choosing revenge instead of closure.",
            year: 2023,
            format: .tv,
            status: .completed,
            ageRating: "13+",
            rating: 8.4,
            studio: "Blue Ember",
            posterSeed: "paper-cranes-poster",
            backdropSeed: "paper-cranes-backdrop",
            genres: [.romance, .sliceOfLife, .supernatural],
            tags: ["Heartfelt", "Late Night", "Beautiful Score"],
            seasonTitles: ["Season 1"],
            episodesPerSeason: [12],
            related: ["velvet-zero", "blue-hour-district"]
        ),
        makeAnime(
            id: "last-orbit-refrain",
            title: "Last Orbit Refrain",
            originalTitle: "Last Orbit Refrain",
            synopsis: "A composer stranded on a failing generation ship writes music that stabilizes the vessel’s rogue AI for a few minutes at a time. The closer the ship drifts toward its final orbit, the more the AI begins composing back.",
            year: 2026,
            format: .movie,
            status: .completed,
            ageRating: "13+",
            rating: 9.0,
            studio: "Aster Frame",
            posterSeed: "last-orbit-poster",
            backdropSeed: "last-orbit-backdrop",
            genres: [.sciFi, .drama, .romance],
            tags: ["Movie", "Cinematic", "4K Master"],
            seasonTitles: ["Feature Film"],
            episodesPerSeason: [1],
            related: ["solar-drift-404", "velvet-zero"]
        ),
        makeAnime(
            id: "blue-hour-district",
            title: "The Archive of Quiet Constellations: Blue Hour District",
            originalTitle: "Blue Hour District",
            synopsis: "A municipal archivist is assigned to preserve a neighborhood scheduled for demolition, only to learn the residents can step between memories woven into their buildings at dusk. Saving the district may mean choosing which histories must disappear.",
            year: 2026,
            format: .tv,
            status: .airing,
            ageRating: "13+",
            rating: 8.7,
            studio: "Glass Harbor",
            posterSeed: "blue-hour-poster",
            backdropSeed: "blue-hour-backdrop",
            genres: [.drama, .fantasy, .sliceOfLife],
            tags: ["Long Title", "Beautiful Backgrounds", "Soft Sci-Fi"],
            seasonTitles: ["Season 1"],
            episodesPerSeason: [11],
            related: ["paper-cranes-midnight", "northern-signal"]
        ),
        makeAnime(
            id: "iron-bloom",
            title: "Iron Bloom",
            originalTitle: "Iron Bloom",
            synopsis: "A retired combat engineer opens a botanical repair shop for service androids, but the peaceful district becomes a frontline when abandoned war models begin waking beneath the city’s greenhouses.",
            year: 2025,
            format: .tv,
            status: .completed,
            ageRating: "16+",
            rating: 8.1,
            studio: "Sable Works",
            posterSeed: "iron-bloom-poster",
            backdropSeed: "iron-bloom-backdrop",
            genres: [.action, .fantasy, .drama],
            tags: ["Mechanical", "Underdog", "Strong Finish"],
            seasonTitles: ["Season 1"],
            episodesPerSeason: [12],
            related: ["solar-drift-404", "blue-hour-district"]
        )
    ]

    static let profile = UserProfile(
        id: "user.demo",
        nickname: "Ehm Prime",
        avatarSymbolName: "person.crop.circle.fill",
        levelTitle: "Collector",
        badges: ["Founding Member", "Night Watcher", "Curator"],
        preferredGenres: [.sciFi, .mystery, .drama],
        totalWatchedHours: 428,
        totalEpisodes: 962
    )

    static var homeContent: HomeContent {
        HomeContent(
            featured: titles[0],
            shelves: [
                HomeShelf(title: "Continue Watching", subtitle: "Pick up exactly where you left off.", style: .continueWatching, items: [titles[0], titles[2], titles[5]]),
                HomeShelf(title: "Trending Now", subtitle: "Most replayed this evening.", style: .wide, items: [titles[0], titles[1], titles[4], titles[6]]),
                HomeShelf(title: "New Episodes", subtitle: "Fresh drops for followed series.", style: .poster, items: [titles[5], titles[0], titles[6], titles[2]]),
                HomeShelf(title: "Because You Liked Space Dramas", subtitle: "Calm, high-concept picks with strong atmosphere.", style: .poster, items: [titles[4], titles[2], titles[1], titles[6]]),
                HomeShelf(title: "Top Picks", subtitle: "Elegant, high-rated titles worth a quiet night.", style: .wide, items: [titles[1], titles[3], titles[5], titles[4]])
            ]
        )
    }

    static let trendingSearches = [
        "slow-burn sci-fi",
        "romance with mystery",
        "best 2026 premieres",
        "beautiful background art",
        "premium dub"
    ]

    static let seedProgress: [PlaybackProgress] = [
        PlaybackProgress(episodeID: "solar-drift-404-s1-e4", animeID: "solar-drift-404", progress: 0.62, positionSeconds: 818, durationSeconds: 1320, lastUpdated: .now.addingTimeInterval(-3600)),
        PlaybackProgress(episodeID: "northern-signal-s1-e9", animeID: "northern-signal", progress: 0.38, positionSeconds: 480, durationSeconds: 1260, lastUpdated: .now.addingTimeInterval(-12_600)),
        PlaybackProgress(episodeID: "blue-hour-district-s1-e2", animeID: "blue-hour-district", progress: 0.88, positionSeconds: 1104, durationSeconds: 1260, lastUpdated: .now.addingTimeInterval(-86_400))
    ]

    static let seedLibraryEntries: [LibraryEntry] = [
        LibraryEntry(
            animeID: "solar-drift-404",
            categories: [.continueWatching, .watching, .favorites],
            lastEpisodeID: "solar-drift-404-s1-e4",
            progress: 0.62,
            lastPositionSeconds: 818,
            lastUpdated: .now.addingTimeInterval(-3600),
            isDownloaded: false
        ),
        LibraryEntry(
            animeID: "northern-signal",
            categories: [.continueWatching, .history],
            lastEpisodeID: "northern-signal-s1-e9",
            progress: 0.38,
            lastPositionSeconds: 480,
            lastUpdated: .now.addingTimeInterval(-12_600),
            isDownloaded: true
        ),
        LibraryEntry(
            animeID: "blue-hour-district",
            categories: [.watching, .planned],
            lastEpisodeID: "blue-hour-district-s1-e2",
            progress: 0.88,
            lastPositionSeconds: 1104,
            lastUpdated: .now.addingTimeInterval(-86_400),
            isDownloaded: false
        ),
        LibraryEntry(
            animeID: "last-orbit-refrain",
            categories: [.favorites, .history],
            lastEpisodeID: "last-orbit-refrain-s1-e1",
            progress: 1.0,
            lastPositionSeconds: 5940,
            lastUpdated: .now.addingTimeInterval(-432_000),
            isDownloaded: false
        ),
        LibraryEntry(
            animeID: "paper-cranes-midnight",
            categories: [.planned],
            lastEpisodeID: nil,
            progress: 0,
            lastPositionSeconds: 0,
            lastUpdated: .now.addingTimeInterval(-172_800),
            isDownloaded: false
        )
    ]

    static let seedAssets: [LocalMediaAsset] = [
        LocalMediaAsset(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") ?? UUID(),
            animeID: "northern-signal",
            episodeID: "northern-signal-s1-e9",
            localFileName: "northern-signal-s1-e9-demo",
            qualityLabel: "1080p",
            fileSizeInBytes: 1_102_000_000,
            createdAt: .now.addingTimeInterval(-86_400)
        )
    ]

    static let seedDownloads: [DownloadTaskModel] = [
        DownloadTaskModel(
            id: UUID(uuidString: "AAAAAAAA-1111-2222-3333-BBBBBBBBBBBB") ?? UUID(),
            animeID: "solar-drift-404",
            animeTitle: "Solar Drift 404",
            episodeID: "solar-drift-404-s1-e5",
            episodeNumber: 5,
            quality: .p1080,
            status: .downloading,
            progress: 0.46,
            estimatedSizeInBytes: 1_450_000_000,
            downloadedBytes: 667_000_000,
            createdAt: .now.addingTimeInterval(-1200),
            localFileName: nil,
            errorDescription: nil
        ),
        DownloadTaskModel(
            id: UUID(uuidString: "AAAAAAAA-1111-2222-3333-CCCCCCCCCCCC") ?? UUID(),
            animeID: "blue-hour-district",
            animeTitle: "The Archive of Quiet Constellations: Blue Hour District",
            episodeID: "blue-hour-district-s1-e3",
            episodeNumber: 3,
            quality: .p720,
            status: .queued,
            progress: 0,
            estimatedSizeInBytes: 870_000_000,
            downloadedBytes: 0,
            createdAt: .now.addingTimeInterval(-600),
            localFileName: nil,
            errorDescription: nil
        ),
        DownloadTaskModel(
            id: UUID(uuidString: "AAAAAAAA-1111-2222-3333-DDDDDDDDDDDD") ?? UUID(),
            animeID: "northern-signal",
            animeTitle: "Northern Signal",
            episodeID: "northern-signal-s1-e9",
            episodeNumber: 9,
            quality: .p1080,
            status: .completed,
            progress: 1.0,
            estimatedSizeInBytes: 1_102_000_000,
            downloadedBytes: 1_102_000_000,
            createdAt: .now.addingTimeInterval(-86_400),
            localFileName: "northern-signal-s1-e9-demo",
            errorDescription: nil
        )
    ]

    static let initialSchedule: [ScheduleEntry] = {
        let calendar = Calendar.current
        let animePairs: [(Anime, Int)] = [
            (titles[0], 5),
            (titles[5], 3),
            (titles[6], 8),
            (titles[2], 11),
            (titles[1], 19),
            (titles[3], 7)
        ]

        return animePairs.enumerated().compactMap { index, pair in
            let anime = pair.0
            let episodeNumber = pair.1
            guard let episode = anime.seasons.flatMap(\.episodes).first(where: { $0.number == episodeNumber }) else { return nil }
            let dayOffset = index < 2 ? 0 : index < 4 ? 1 : 4
            let releaseDate = calendar.date(byAdding: .hour, value: 18 + index, to: calendar.startOfDay(for: .now).addingTimeInterval(Double(dayOffset) * 86_400)) ?? .now
            return ScheduleEntry(
                anime: anime,
                episode: episode,
                releaseDate: releaseDate,
                isWatched: index == 4,
                notificationsEnabled: index != 2
            )
        }
    }()

    static func relatedTitles(for animeID: String) -> [Anime] {
        guard let anime = titles.first(where: { $0.id == animeID }) else { return [] }
        return titles.filter { anime.relatedTitleIDs.contains($0.id) }
    }

    static func anime(with id: String) -> Anime {
        titles.first(where: { $0.id == id }) ?? fallbackAnime
    }

    static func episode(for episodeID: String) -> Episode? {
        titles
            .flatMap(\.seasons)
            .flatMap(\.episodes)
            .first(where: { $0.id == episodeID })
    }

    private static func makeAnime(
        id: String,
        title: String,
        originalTitle: String,
        synopsis: String,
        year: Int,
        format: AnimeFormat,
        status: AnimeStatus,
        ageRating: String,
        rating: Double,
        studio: String,
        posterSeed: String,
        backdropSeed: String,
        genres: [AnimeGenre],
        tags: [String],
        seasonTitles: [String],
        episodesPerSeason: [Int],
        related: [String]
    ) -> Anime {
        let seasons = zip(seasonTitles.indices, seasonTitles).map { index, seasonTitle in
            let seasonNumber = index + 1
            let seasonID = "\(id)-s\(seasonNumber)"
            let episodeCount = episodesPerSeason[index]
            return AnimeSeason(
                id: seasonID,
                title: seasonTitle,
                number: seasonNumber,
                isCurrent: index == seasonTitles.count - 1,
                episodes: makeEpisodes(
                    animeID: id,
                    seasonID: seasonID,
                    count: episodeCount,
                    titleSeed: title
                )
            )
        }

        return Anime(
            id: id,
            title: title,
            originalTitle: originalTitle,
            synopsis: synopsis,
            year: year,
            format: format,
            episodeCount: episodesPerSeason.reduce(0, +),
            status: status,
            ageRating: ageRating,
            averageRating: rating,
            studio: studio,
            posterURL: URL(string: "https://picsum.photos/seed/\(posterSeed)/600/900"),
            backdropURL: URL(string: "https://picsum.photos/seed/\(backdropSeed)/1600/900"),
            genres: genres,
            tags: tags,
            seasons: seasons,
            relatedTitleIDs: related
        )
    }

    private static func makeEpisodes(
        animeID: String,
        seasonID: String,
        count: Int,
        titleSeed: String
    ) -> [Episode] {
        let seasonSuffix = seasonID.split(separator: "-").last.map(String.init) ?? "s1"
        let duration = count == 1 ? 99 : 22

        return (1...count).map { number in
            let episodeID = "\(animeID)-\(seasonSuffix)-e\(number)"
            let title: String
            if number == 1 {
                title = "Pilot Signal"
            } else if number == count {
                title = "Final Transmission"
            } else {
                title = "\(titleSeed) Episode \(number)"
            }

            let synopsis = "Episode \(number) deepens the atmosphere, character tension, and larger mystery while preserving a strong emotional through-line."
            let thumbnail = URL(string: "https://picsum.photos/seed/\(animeID)-ep-\(number)/800/450")
            let airDate = Date.now.addingTimeInterval(Double(-count + number) * 86_400 * 7)

            return Episode(
                id: episodeID,
                animeID: animeID,
                seasonID: seasonID,
                number: number,
                title: title,
                synopsis: synopsis,
                durationMinutes: duration,
                thumbnailURL: thumbnail,
                isNew: number >= max(1, count - 2),
                dubCount: Int.random(in: 1...4),
                subtitleCount: Int.random(in: 4...9),
                videoURL: sampleVideoURL,
                airDate: airDate
            )
        }
    }
}
