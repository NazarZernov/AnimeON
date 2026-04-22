import Combine
import Foundation

@MainActor
final class DownloadManager: ObservableObject {
    @Published private(set) var tasks: [DownloadTaskModel] = []
    @Published private(set) var assets: [LocalMediaAsset] = []

    private let repository: any DownloadRepository
    private let libraryRepository: any LibraryRepository
    private let fileStore: LocalFileStore
    private var workers: [UUID: Task<Void, Never>] = [:]

    init(
        repository: any DownloadRepository,
        libraryRepository: any LibraryRepository,
        fileStore: LocalFileStore
    ) {
        self.repository = repository
        self.libraryRepository = libraryRepository
        self.fileStore = fileStore
        Task {
            await restore()
        }
    }

    func restore() async {
        do {
            tasks = try await repository.fetchTasks()
            assets = try await repository.fetchAssets()
            for task in tasks where task.status == .downloading {
                startWorker(for: task.id)
            }
        } catch {
            tasks = []
            assets = []
        }
    }

    func enqueue(anime: Anime, episode: Episode, quality: DownloadQualityPreference) {
        let newTask = DownloadTaskModel(
            id: UUID(),
            animeID: anime.id,
            animeTitle: anime.title,
            episodeID: episode.id,
            episodeNumber: episode.number,
            quality: quality,
            status: .queued,
            progress: 0,
            estimatedSizeInBytes: quality == .p1080 ? 1_250_000_000 : 860_000_000,
            downloadedBytes: 0,
            createdAt: .now,
            localFileName: nil,
            errorDescription: nil
        )
        tasks.insert(newTask, at: 0)
        persist()
        resume(taskID: newTask.id)
    }

    func pause(taskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].status = .paused
        workers[taskID]?.cancel()
        workers[taskID] = nil
        persist()
    }

    func resume(taskID: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        tasks[index].status = .downloading
        persist()
        startWorker(for: taskID)
    }

    func cancel(taskID: UUID) {
        workers[taskID]?.cancel()
        workers[taskID] = nil
        tasks.removeAll { $0.id == taskID }
        persist()
    }

    func clearCompletedMetadata() {
        tasks.removeAll { $0.status == .completed }
        persist()
    }

    func removeAllFailed() {
        tasks.removeAll { $0.status == .failed }
        persist()
    }

    func asset(for episodeID: String) -> LocalMediaAsset? {
        assets.first(where: { $0.episodeID == episodeID })
    }

    func storageSummary(limit: StorageLimitPreset) -> DownloadStorageSummary {
        let usedBytes = assets.reduce(0) { $0 + $1.fileSizeInBytes }
        let capBytes: Int64 = switch limit {
        case .gb5: 5_000_000_000
        case .gb15: 15_000_000_000
        case .gb30: 30_000_000_000
        case .unlimited: max(usedBytes + 1_000_000_000, 50_000_000_000)
        }

        let remaining = max(capBytes - usedBytes, 0)
        return DownloadStorageSummary(
            usedText: fileStore.formattedByteCount(usedBytes),
            remainingText: limit == .unlimited ? L10n.tr("Flexible") : fileStore.formattedByteCount(remaining),
            usageProgress: min(Double(usedBytes) / Double(max(capBytes, 1)), 1)
        )
    }

    private func startWorker(for taskID: UUID) {
        workers[taskID]?.cancel()
        workers[taskID] = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled,
                  let index = self.tasks.firstIndex(where: { $0.id == taskID }),
                  self.tasks[index].status == .downloading,
                  self.tasks[index].progress < 1 {
                try? await Task.sleep(for: .milliseconds(650))
                guard let liveIndex = self.tasks.firstIndex(where: { $0.id == taskID }) else { return }
                self.tasks[liveIndex].progress = min(self.tasks[liveIndex].progress + Double.random(in: 0.06...0.14), 1)
                self.tasks[liveIndex].downloadedBytes = Int64(Double(self.tasks[liveIndex].estimatedSizeInBytes) * self.tasks[liveIndex].progress)

                if self.tasks[liveIndex].progress >= 1 {
                    await self.complete(taskID: taskID)
                    return
                }
                self.persist()
            }
        }
    }

    private func complete(taskID: UUID) async {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return }
        let fileName = fileStore.placeholderFileName(for: tasks[index].episodeID)
        fileStore.registerPlaceholderAsset(named: fileName)
        tasks[index].status = .completed
        tasks[index].progress = 1
        tasks[index].downloadedBytes = tasks[index].estimatedSizeInBytes
        tasks[index].localFileName = fileName

        let asset = LocalMediaAsset(
            id: UUID(),
            animeID: tasks[index].animeID,
            episodeID: tasks[index].episodeID,
            localFileName: fileName,
            qualityLabel: tasks[index].quality.title,
            fileSizeInBytes: tasks[index].estimatedSizeInBytes,
            createdAt: .now
        )

        if !assets.contains(where: { $0.episodeID == asset.episodeID }) {
            assets.insert(asset, at: 0)
        }
        try? await libraryRepository.markDownloaded(animeID: tasks[index].animeID, downloaded: true)
        persist()
        workers[taskID] = nil
    }

    private func persist() {
        let currentTasks = tasks
        let currentAssets = assets
        Task {
            try? await repository.saveTasks(currentTasks)
            try? await repository.saveAssets(currentAssets)
        }
    }
}
