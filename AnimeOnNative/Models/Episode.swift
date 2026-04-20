import Foundation

enum PlaybackSourceKind: String, Codable, Hashable {
    case mp4
    case hls
}

struct StreamQualityOption: Identifiable, Codable, Hashable {
    let id: String
    let label: String
    let url: URL
}

struct AudioTrack: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let languageCode: String
}

struct PlaybackSource: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let kind: PlaybackSourceKind
    let streamURL: URL
    let downloadURL: URL?
    let qualities: [StreamQualityOption]
    let audioTracks: [AudioTrack]
}

struct Episode: Identifiable, Codable, Hashable {
    let id: Int
    let animeID: Int
    let number: Int
    let title: String
    let synopsis: String
    let durationMinutes: Int
    let airDate: Date
    let thumbnailURL: URL
    let streamURL: URL
    let downloadURL: URL
    let isReleased: Bool
    let playbackSources: [PlaybackSource]

    private enum CodingKeys: String, CodingKey {
        case id
        case animeID
        case number
        case title
        case synopsis
        case durationMinutes
        case airDate
        case thumbnailURL
        case streamURL
        case downloadURL
        case isReleased
        case playbackSources
    }

    init(
        id: Int,
        animeID: Int,
        number: Int,
        title: String,
        synopsis: String,
        durationMinutes: Int,
        airDate: Date,
        thumbnailURL: URL,
        streamURL: URL,
        downloadURL: URL,
        isReleased: Bool,
        playbackSources: [PlaybackSource]
    ) {
        self.id = id
        self.animeID = animeID
        self.number = number
        self.title = title
        self.synopsis = synopsis
        self.durationMinutes = durationMinutes
        self.airDate = airDate
        self.thumbnailURL = thumbnailURL
        self.streamURL = streamURL
        self.downloadURL = downloadURL
        self.isReleased = isReleased
        self.playbackSources = playbackSources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        animeID = try container.decode(Int.self, forKey: .animeID)
        number = try container.decode(Int.self, forKey: .number)
        title = try container.decode(String.self, forKey: .title)
        synopsis = try container.decode(String.self, forKey: .synopsis)
        durationMinutes = try container.decode(Int.self, forKey: .durationMinutes)
        airDate = try container.decode(Date.self, forKey: .airDate)
        thumbnailURL = try container.decode(URL.self, forKey: .thumbnailURL)
        streamURL = try container.decode(URL.self, forKey: .streamURL)
        downloadURL = try container.decode(URL.self, forKey: .downloadURL)
        isReleased = try container.decode(Bool.self, forKey: .isReleased)

        let decodedSources = try container.decodeIfPresent([PlaybackSource].self, forKey: .playbackSources)
        if let decodedSources, !decodedSources.isEmpty {
            playbackSources = decodedSources
        } else {
            let sourceKind: PlaybackSourceKind = streamURL.pathExtension.lowercased() == "m3u8" ? .hls : .mp4
            let qualityLabel = sourceKind == .hls ? "Auto" : "1080p"
            playbackSources = [
                PlaybackSource(
                    id: "default-\(id)",
                    title: "Основной источник",
                    kind: sourceKind,
                    streamURL: streamURL,
                    downloadURL: downloadURL,
                    qualities: [
                        StreamQualityOption(id: "default", label: qualityLabel, url: streamURL)
                    ],
                    audioTracks: [
                        AudioTrack(id: "ru-default", title: "Русская озвучка", languageCode: "ru")
                    ]
                )
            ]
        }
    }

    var defaultSource: PlaybackSource {
        playbackSources.first
        ?? PlaybackSource(
            id: "fallback-\(id)",
            title: "Источник",
            kind: streamURL.pathExtension.lowercased() == "m3u8" ? .hls : .mp4,
            streamURL: streamURL,
            downloadURL: downloadURL,
            qualities: [StreamQualityOption(id: "default", label: "Auto", url: streamURL)],
            audioTracks: [AudioTrack(id: "ru-default", title: "Русская озвучка", languageCode: "ru")]
        )
    }

    var preferredDownloadURL: URL {
        defaultSource.downloadURL ?? downloadURL
    }
}
