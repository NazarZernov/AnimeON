import Foundation

final class LocalFileStore {
    private let fileManager = FileManager.default

    var downloadsDirectory: URL {
        let base = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let url = base.appendingPathComponent("AnimeOnDownloads", isDirectory: true)
        if !fileManager.fileExists(atPath: url.path) {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url
    }

    func placeholderFileName(for episodeID: String) -> String {
        "\(episodeID)-demo.asset"
    }

    func registerPlaceholderAsset(named fileName: String) {
        let fileURL = downloadsDirectory.appendingPathComponent(fileName)
        if !fileManager.fileExists(atPath: fileURL.path) {
            let content = Data("AnimeOn demo asset placeholder".utf8)
            try? content.write(to: fileURL)
        }
    }

    func url(for asset: LocalMediaAsset) -> URL {
        let fileURL = downloadsDirectory.appendingPathComponent(asset.localFileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return Bundle.main.url(forResource: "Demo_Video", withExtension: "mkv") ?? fileURL
    }

    func formattedByteCount(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
