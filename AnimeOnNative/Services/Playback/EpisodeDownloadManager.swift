import Foundation

enum DownloadStatus: String, Codable, Hashable {
    case queued
    case downloading
    case paused
    case completed
    case failed
}

struct DownloadItem: Identifiable, Codable, Hashable {
    let id: Int
    let episode: Episode
    var progress: Double
    var status: DownloadStatus
    var bytesWritten: Int64
    var totalBytes: Int64
    var localFileName: String?
    var resumeData: Data?
    var errorMessage: String?
    var updatedAt: Date

    var isFinished: Bool {
        status == .completed
    }
}

@MainActor
final class DownloadManager: NSObject, ObservableObject {
    @Published private(set) var downloadedEpisodeIDs: Set<Int> = []
    @Published private(set) var activeDownloads: Set<Int> = []
    @Published private(set) var downloads: [Int: DownloadItem] = [:]

    private let fileManager = FileManager.default
    private var taskToEpisodeID: [Int: Int] = [:]
    private var activeTasks: [Int: URLSessionDownloadTask] = [:]
    private var knownEpisodes: [Int: Episode] = [:]

    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.allowsExpensiveNetworkAccess = true
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    override init() {
        super.init()
        restorePersistedDownloads()
    }

    var orderedDownloads: [DownloadItem] {
        downloads.values.sorted { lhs, rhs in
            if lhs.isFinished != rhs.isFinished {
                return !lhs.isFinished
            }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    func item(for episodeID: Int) -> DownloadItem? {
        downloads[episodeID]
    }

    func progress(for episodeID: Int) -> Double {
        downloads[episodeID]?.progress ?? 0
    }

    func downloadEpisode(_ episode: Episode) async throws {
        knownEpisodes[episode.id] = episode

        if isDownloaded(episode) {
            return
        }

        if let existing = downloads[episode.id], existing.status == .paused {
            resumeDownload(for: episode)
            return
        }

        let task = session.downloadTask(with: episode.preferredDownloadURL)
        taskToEpisodeID[task.taskIdentifier] = episode.id
        activeTasks[episode.id] = task
        activeDownloads.insert(episode.id)
        downloads[episode.id] = DownloadItem(
            id: episode.id,
            episode: episode,
            progress: 0,
            status: .queued,
            bytesWritten: 0,
            totalBytes: 0,
            localFileName: nil,
            resumeData: nil,
            errorMessage: nil,
            updatedAt: .now
        )
        persistDownloads()
        task.resume()
    }

    func pauseDownload(_ episodeID: Int) {
        guard let task = activeTasks[episodeID] else { return }

        task.cancel(byProducingResumeData: { [weak self] resumeDataOrNil in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.activeTasks.removeValue(forKey: episodeID)
                self.activeDownloads.remove(episodeID)
                self.taskToEpisodeID.removeValue(forKey: task.taskIdentifier)
                guard var item = self.downloads[episodeID] else { return }
                item.status = .paused
                item.resumeData = resumeDataOrNil
                item.updatedAt = .now
                self.downloads[episodeID] = item
                self.persistDownloads()
            }
        })
    }

    func resumeDownload(for episode: Episode) {
        knownEpisodes[episode.id] = episode

        if let resumeData = downloads[episode.id]?.resumeData {
            let task = session.downloadTask(withResumeData: resumeData)
            taskToEpisodeID[task.taskIdentifier] = episode.id
            activeTasks[episode.id] = task
            activeDownloads.insert(episode.id)
            updateStatus(for: episode.id, status: .downloading, resumeData: nil)
            task.resume()
            return
        }

        Task {
            try? await downloadEpisode(episode)
        }
    }

    func removeDownloadedEpisode(_ episodeID: Int) {
        activeTasks[episodeID]?.cancel()
        activeTasks.removeValue(forKey: episodeID)
        activeDownloads.remove(episodeID)
        downloadedEpisodeIDs.remove(episodeID)

        if let item = downloads[episodeID], let localFileName = item.localFileName {
            try? fileManager.removeItem(at: downloadsFolderURL().appendingPathComponent(localFileName))
        }

        downloads.removeValue(forKey: episodeID)
        persistDownloads()
    }

    func localURL(for episode: Episode) -> URL? {
        guard let item = downloads[episode.id], let localFileName = item.localFileName else {
            return nil
        }

        let url = downloadsFolderURL().appendingPathComponent(localFileName)
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        downloadedEpisodeIDs.insert(episode.id)
        return url
    }

    func isDownloaded(_ episode: Episode) -> Bool {
        localURL(for: episode) != nil
    }

    private func restorePersistedDownloads() {
        guard
            let data = try? Data(contentsOf: metadataURL()),
            let restored = try? JSONDecoder.downloadDecoder.decode([DownloadItem].self, from: data)
        else {
            return
        }

        downloads = Dictionary(uniqueKeysWithValues: restored.map { ($0.id, $0) })
        downloadedEpisodeIDs = Set(
            restored.compactMap { item in
                guard item.status == .completed, let localFileName = item.localFileName else {
                    return nil
                }
                let url = downloadsFolderURL().appendingPathComponent(localFileName)
                return fileManager.fileExists(atPath: url.path) ? item.id : nil
            }
        )
    }

    private func updateStatus(
        for episodeID: Int,
        status: DownloadStatus,
        progress: Double? = nil,
        bytesWritten: Int64? = nil,
        totalBytes: Int64? = nil,
        localFileName: String? = nil,
        resumeData: Data? = nil,
        errorMessage: String? = nil
    ) {
        guard var item = downloads[episodeID] else { return }
        item.status = status
        if let progress { item.progress = progress }
        if let bytesWritten { item.bytesWritten = bytesWritten }
        if let totalBytes { item.totalBytes = totalBytes }
        if let localFileName { item.localFileName = localFileName }
        if let resumeData { item.resumeData = resumeData }
        if let errorMessage { item.errorMessage = errorMessage }
        item.updatedAt = .now
        downloads[episodeID] = item
        persistDownloads()
    }

    private func destinationURL(for episode: Episode) -> URL {
        let ext = episode.preferredDownloadURL.pathExtension.isEmpty ? "mp4" : episode.preferredDownloadURL.pathExtension
        return downloadsFolderURL().appendingPathComponent("episode-\(episode.id).\(ext)")
    }

    private func downloadsFolderURL() -> URL {
        let appSupport = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory

        let folderURL = appSupport
            .appendingPathComponent("AnimeOnNative", isDirectory: true)
            .appendingPathComponent("Downloads", isDirectory: true)

        if !fileManager.fileExists(atPath: folderURL.path) {
            try? fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }

        return folderURL
    }

    private func metadataURL() -> URL {
        downloadsFolderURL().appendingPathComponent("downloads.json")
    }

    private func persistDownloads() {
        let items = downloads.values.sorted { $0.updatedAt > $1.updatedAt }
        guard let data = try? JSONEncoder.downloadEncoder.encode(items) else { return }
        try? data.write(to: metadataURL(), options: [.atomic])
    }
}

extension DownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        Task { @MainActor [weak self] in
            guard
                let self,
                let episodeID = self.taskToEpisodeID[downloadTask.taskIdentifier]
            else { return }

            let total = max(totalBytesExpectedToWrite, 1)
            let progress = Double(totalBytesWritten) / Double(total)
            self.updateStatus(
                for: episodeID,
                status: .downloading,
                progress: progress,
                bytesWritten: totalBytesWritten,
                totalBytes: totalBytesExpectedToWrite
            )
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        Task { @MainActor [weak self] in
            guard
                let self,
                let episodeID = self.taskToEpisodeID[downloadTask.taskIdentifier],
                let episode = self.knownEpisodes[episodeID]
            else { return }

            let destination = self.destinationURL(for: episode)
            let localFileName = destination.lastPathComponent

            try? self.fileManager.removeItem(at: destination)
            do {
                try self.fileManager.moveItem(at: location, to: destination)
                self.downloadedEpisodeIDs.insert(episodeID)
                self.activeDownloads.remove(episodeID)
                self.activeTasks.removeValue(forKey: episodeID)
                self.taskToEpisodeID.removeValue(forKey: downloadTask.taskIdentifier)
                self.updateStatus(
                    for: episodeID,
                    status: .completed,
                    progress: 1,
                    bytesWritten: self.downloads[episodeID]?.bytesWritten ?? 0,
                    totalBytes: self.downloads[episodeID]?.totalBytes ?? 0,
                    localFileName: localFileName
                )
                if var item = self.downloads[episodeID] {
                    item.resumeData = nil
                    self.downloads[episodeID] = item
                    self.persistDownloads()
                }
            } catch {
                self.updateStatus(for: episodeID, status: .failed, errorMessage: error.localizedDescription)
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }

        Task { @MainActor [weak self] in
            guard
                let self,
                let episodeID = self.taskToEpisodeID[task.taskIdentifier]
            else { return }

            let nsError = error as NSError
            if nsError.code == NSURLErrorCancelled {
                self.taskToEpisodeID.removeValue(forKey: task.taskIdentifier)
                return
            }

            self.activeDownloads.remove(episodeID)
            self.activeTasks.removeValue(forKey: episodeID)
            self.taskToEpisodeID.removeValue(forKey: task.taskIdentifier)
            self.updateStatus(for: episodeID, status: .failed, errorMessage: error.localizedDescription)
        }
    }
}

private extension JSONDecoder {
    static let downloadDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

private extension JSONEncoder {
    static let downloadEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

typealias EpisodeDownloadManager = DownloadManager
