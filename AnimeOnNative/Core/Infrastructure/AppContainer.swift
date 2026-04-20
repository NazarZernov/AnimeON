import Foundation
import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    @Published var selectedSection: AppSection = .home

    let cacheManager: CacheManager
    let downloadManager: DownloadManager
    let playbackProgressStore = PlaybackProgressStore()
    let syncManager: OfflineSyncManager
    let repository: AnimeRepository
    let imagePipeline: ImagePipeline
    let animeService: any AnimeServicing
    let playerManager: PlayerManager

    init(configuration: AppConfiguration = .current) {
        let serviceAdapter = AnimeServiceAdapter(configuration: configuration)
        animeService = serviceAdapter
        cacheManager = CacheManager(namespace: "animeon.cache")
        downloadManager = DownloadManager()
        syncManager = OfflineSyncManager(service: serviceAdapter)
        repository = AnimeRepository(
            service: serviceAdapter,
            cacheManager: cacheManager,
            syncManager: syncManager
        )
        imagePipeline = ImagePipeline(cacheManager: cacheManager)
        playerManager = PlayerManager(
            repository: repository,
            downloadManager: downloadManager,
            playbackProgressStore: playbackProgressStore
        )
        syncManager.start()
    }

    func handleScenePhase(_ phase: ScenePhase) {
        guard phase == .active else { return }
        Task {
            await syncManager.flush()
        }
    }
}
