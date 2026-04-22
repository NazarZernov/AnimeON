import Foundation

enum DownloadStatus: String, Codable, CaseIterable, Hashable {
    case queued
    case downloading
    case paused
    case completed
    case failed

    var title: String {
        switch self {
        case .queued: L10n.tr("Queued")
        case .downloading: L10n.tr("Downloading")
        case .paused: L10n.tr("Paused")
        case .completed: L10n.tr("Completed")
        case .failed: L10n.tr("Failed")
        }
    }
}

struct DownloadTaskModel: Identifiable, Codable, Hashable {
    let id: UUID
    let animeID: String
    let animeTitle: String
    let episodeID: String
    let episodeNumber: Int
    let quality: DownloadQualityPreference
    var status: DownloadStatus
    var progress: Double
    var estimatedSizeInBytes: Int64
    var downloadedBytes: Int64
    var createdAt: Date
    var localFileName: String?
    var errorDescription: String?
}

struct LocalMediaAsset: Identifiable, Codable, Hashable {
    let id: UUID
    let animeID: String
    let episodeID: String
    let localFileName: String
    let qualityLabel: String
    let fileSizeInBytes: Int64
    let createdAt: Date
}

struct DownloadStorageSummary: Hashable {
    let usedText: String
    let remainingText: String
    let usageProgress: Double
}
