import Combine
import Foundation
import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    let settingsStore: SettingsStore
    let recentSearchStore: RecentSearchStore
    let sessionStore: SessionStore
    let themeManager: ThemeManager
    let apiClient: APIClientProtocol
    let homeRepository: any HomeRepository
    let searchRepository: any SearchRepository
    let animeRepository: any AnimeRepository
    let scheduleRepository: any ScheduleRepository
    let libraryRepository: any LibraryRepository
    let playbackRepository: any PlaybackRepository
    let downloadRepository: any DownloadRepository
    let sessionRepository: any SessionRepository
    let profileRepository: any ProfileRepository
    let downloadManager: DownloadManager
    let playbackCoordinator: PlaybackCoordinator
    let handoffManager: HandoffManager
    let universalLinkRouter: UniversalLinkRouter
    let siriShortcutsManager: SiriShortcutsManager
    let widgetProvider: WidgetDataProvider
    let iCloudSyncService: ICloudSyncService
    let appIconManager: AppIconManager

    init(
        settingsStore: SettingsStore,
        recentSearchStore: RecentSearchStore,
        sessionStore: SessionStore,
        themeManager: ThemeManager,
        apiClient: APIClientProtocol,
        homeRepository: any HomeRepository,
        searchRepository: any SearchRepository,
        animeRepository: any AnimeRepository,
        scheduleRepository: any ScheduleRepository,
        libraryRepository: any LibraryRepository,
        playbackRepository: any PlaybackRepository,
        downloadRepository: any DownloadRepository,
        sessionRepository: any SessionRepository,
        profileRepository: any ProfileRepository,
        downloadManager: DownloadManager,
        playbackCoordinator: PlaybackCoordinator,
        handoffManager: HandoffManager,
        universalLinkRouter: UniversalLinkRouter,
        siriShortcutsManager: SiriShortcutsManager,
        widgetProvider: WidgetDataProvider,
        iCloudSyncService: ICloudSyncService,
        appIconManager: AppIconManager
    ) {
        self.settingsStore = settingsStore
        self.recentSearchStore = recentSearchStore
        self.sessionStore = sessionStore
        self.themeManager = themeManager
        self.apiClient = apiClient
        self.homeRepository = homeRepository
        self.searchRepository = searchRepository
        self.animeRepository = animeRepository
        self.scheduleRepository = scheduleRepository
        self.libraryRepository = libraryRepository
        self.playbackRepository = playbackRepository
        self.downloadRepository = downloadRepository
        self.sessionRepository = sessionRepository
        self.profileRepository = profileRepository
        self.downloadManager = downloadManager
        self.playbackCoordinator = playbackCoordinator
        self.handoffManager = handoffManager
        self.universalLinkRouter = universalLinkRouter
        self.siriShortcutsManager = siriShortcutsManager
        self.widgetProvider = widgetProvider
        self.iCloudSyncService = iCloudSyncService
        self.appIconManager = appIconManager
    }

    static var live: AppContainer {
        let settingsStore = SettingsStore()
        let recentSearchStore = RecentSearchStore()
        let apiClient = APIClient(settingsStore: settingsStore)
        let libraryRepository = MockLibraryRepository()
        let playbackRepository = MockPlaybackRepository()
        let downloadRepository = MockDownloadRepository()
        let sessionRepository = MockSessionRepository()
        let sessionStore = SessionStore(sessionRepository: sessionRepository)
        let themeManager = ThemeManager(settingsStore: settingsStore)
        let fileStore = LocalFileStore()
        let nativePlaybackEngine = NativePlaybackEngine()
        let downloadManager = DownloadManager(
            repository: downloadRepository,
            libraryRepository: libraryRepository,
            fileStore: fileStore
        )
        let playbackCoordinator = PlaybackCoordinator(
            engine: nativePlaybackEngine,
            playbackRepository: playbackRepository,
            animeRepository: MockAnimeRepository(),
            libraryRepository: libraryRepository
        )

        return AppContainer(
            settingsStore: settingsStore,
            recentSearchStore: recentSearchStore,
            sessionStore: sessionStore,
            themeManager: themeManager,
            apiClient: apiClient,
            homeRepository: MockHomeRepository(),
            searchRepository: MockSearchRepository(),
            animeRepository: playbackCoordinator.animeRepository,
            scheduleRepository: MockScheduleRepository(),
            libraryRepository: libraryRepository,
            playbackRepository: playbackRepository,
            downloadRepository: downloadRepository,
            sessionRepository: sessionRepository,
            profileRepository: MockProfileRepository(),
            downloadManager: downloadManager,
            playbackCoordinator: playbackCoordinator,
            handoffManager: HandoffManager(),
            universalLinkRouter: UniversalLinkRouter(),
            siriShortcutsManager: SiriShortcutsManager(),
            widgetProvider: WidgetDataProvider(),
            iCloudSyncService: ICloudSyncService(),
            appIconManager: AppIconManager()
        )
    }
}
