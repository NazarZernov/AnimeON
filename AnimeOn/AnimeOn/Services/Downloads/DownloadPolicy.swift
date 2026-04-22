import Foundation

struct DownloadPolicy {
    var allowsCellular: Bool
    var maxConcurrentDownloads: Int
    var autoDeleteWatched: Bool

    static let `default` = DownloadPolicy(
        allowsCellular: false,
        maxConcurrentDownloads: 2,
        autoDeleteWatched: false
    )
}
