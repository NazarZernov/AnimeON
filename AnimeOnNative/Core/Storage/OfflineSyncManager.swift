import Foundation

struct SyncActionPayload: Codable, Hashable {
    enum Kind: String, Codable, Hashable {
        case history
        case progress
        case watchlist
        case reaction
        case rating
    }

    let kind: Kind
    let historyEntry: WatchHistoryEntry?
    let progressPayload: PlaybackProgressPayload?
    let watchlistMutation: WatchlistMutation?
    let reactionPayload: AnimeReactionPayload?
    let ratingPayload: AnimeRatingPayload?

    static func history(_ entry: WatchHistoryEntry) -> SyncActionPayload {
        SyncActionPayload(
            kind: .history,
            historyEntry: entry,
            progressPayload: nil,
            watchlistMutation: nil,
            reactionPayload: nil,
            ratingPayload: nil
        )
    }

    static func progress(_ payload: PlaybackProgressPayload) -> SyncActionPayload {
        SyncActionPayload(
            kind: .progress,
            historyEntry: nil,
            progressPayload: payload,
            watchlistMutation: nil,
            reactionPayload: nil,
            ratingPayload: nil
        )
    }

    static func watchlist(_ mutation: WatchlistMutation) -> SyncActionPayload {
        SyncActionPayload(
            kind: .watchlist,
            historyEntry: nil,
            progressPayload: nil,
            watchlistMutation: mutation,
            reactionPayload: nil,
            ratingPayload: nil
        )
    }

    static func reaction(_ payload: AnimeReactionPayload) -> SyncActionPayload {
        SyncActionPayload(
            kind: .reaction,
            historyEntry: nil,
            progressPayload: nil,
            watchlistMutation: nil,
            reactionPayload: payload,
            ratingPayload: nil
        )
    }

    static func rating(_ payload: AnimeRatingPayload) -> SyncActionPayload {
        SyncActionPayload(
            kind: .rating,
            historyEntry: nil,
            progressPayload: nil,
            watchlistMutation: nil,
            reactionPayload: nil,
            ratingPayload: payload
        )
    }
}

struct PendingSyncJob: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    var retryCount: Int
    var nextAttemptAt: Date?
    let action: SyncActionPayload

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        retryCount: Int = 0,
        nextAttemptAt: Date? = nil,
        action: SyncActionPayload
    ) {
        self.id = id
        self.createdAt = createdAt
        self.retryCount = retryCount
        self.nextAttemptAt = nextAttemptAt
        self.action = action
    }
}

@MainActor
final class OfflineSyncManager: ObservableObject {
    @Published private(set) var pendingJobs: [PendingSyncJob] = []

    private let service: any AnimeServicing
    private let storeURL: URL
    private let fileManager = FileManager.default
    private var isFlushing = false
    private var backgroundTask: Task<Void, Never>?

    init(service: any AnimeServicing) {
        self.service = service

        let appSupport = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory

        let queueDirectory = appSupport
            .appendingPathComponent("AnimeOnNative", isDirectory: true)
            .appendingPathComponent("Sync", isDirectory: true)

        if !fileManager.fileExists(atPath: queueDirectory.path) {
            try? fileManager.createDirectory(at: queueDirectory, withIntermediateDirectories: true)
        }

        storeURL = queueDirectory.appendingPathComponent("pending-jobs.json")
        pendingJobs = Self.loadPersistedJobs(from: storeURL)
    }

    deinit {
        backgroundTask?.cancel()
    }

    var pendingCount: Int {
        pendingJobs.count
    }

    func start() {
        guard backgroundTask == nil else { return }
        backgroundTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await self?.flush()
            }
        }
    }

    func enqueueHistory(_ entry: WatchHistoryEntry) async {
        await enqueue(.history(entry))
    }

    func enqueueProgress(_ payload: PlaybackProgressPayload) async {
        await enqueue(.progress(payload))
    }

    func enqueueWatchlist(_ mutation: WatchlistMutation) async {
        await enqueue(.watchlist(mutation))
    }

    func enqueueReaction(_ payload: AnimeReactionPayload) async {
        await enqueue(.reaction(payload))
    }

    func enqueueRating(_ payload: AnimeRatingPayload) async {
        await enqueue(.rating(payload))
    }

    func flush() async {
        guard !isFlushing, !pendingJobs.isEmpty else {
            return
        }

        isFlushing = true
        defer { isFlushing = false }

        let now = Date()
        var remaining: [PendingSyncJob] = []

        for var job in pendingJobs.sorted(by: { $0.createdAt < $1.createdAt }) {
            if let nextAttemptAt = job.nextAttemptAt, nextAttemptAt > now {
                remaining.append(job)
                continue
            }

            do {
                try await perform(job.action)
            } catch {
                job.retryCount += 1
                let backoff = min(pow(2, Double(job.retryCount)) * 5, 300)
                job.nextAttemptAt = Date().addingTimeInterval(backoff)
                remaining.append(job)
            }
        }

        pendingJobs = remaining
        persist()
    }

    private func enqueue(_ action: SyncActionPayload) async {
        merge(action)
        persist()
        await flush()
    }

    private func merge(_ action: SyncActionPayload) {
        switch action.kind {
        case .progress:
            pendingJobs.removeAll {
                $0.action.kind == .progress && $0.action.progressPayload?.episodeID == action.progressPayload?.episodeID
            }
        case .watchlist:
            pendingJobs.removeAll {
                $0.action.kind == .watchlist && $0.action.watchlistMutation?.animeID == action.watchlistMutation?.animeID
            }
        case .reaction:
            pendingJobs.removeAll {
                $0.action.kind == .reaction && $0.action.reactionPayload?.animeID == action.reactionPayload?.animeID
            }
        case .rating:
            pendingJobs.removeAll {
                $0.action.kind == .rating && $0.action.ratingPayload?.animeID == action.ratingPayload?.animeID
            }
        case .history:
            break
        }

        pendingJobs.append(PendingSyncJob(action: action))
    }

    private func perform(_ action: SyncActionPayload) async throws {
        switch action.kind {
        case .history:
            if let entry = action.historyEntry {
                try await service.updateHistory(entry: entry)
            }
        case .progress:
            if let payload = action.progressPayload {
                try await service.updateProgress(payload)
            }
        case .watchlist:
            if let mutation = action.watchlistMutation {
                try await service.updateWatchlist(animeID: mutation.animeID, action: mutation.action)
            }
        case .reaction:
            if let payload = action.reactionPayload {
                try await service.updateReaction(payload)
            }
        case .rating:
            if let payload = action.ratingPayload {
                try await service.updateRating(payload)
            }
        }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(pendingJobs) else { return }
        try? data.write(to: storeURL, options: [.atomic])
    }

    private static func loadPersistedJobs(from storeURL: URL) -> [PendingSyncJob] {
        guard let data = try? Data(contentsOf: storeURL) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([PendingSyncJob].self, from: data)) ?? []
    }
}
