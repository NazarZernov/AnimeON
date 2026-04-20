import AVFoundation
import AVKit
import Foundation

@MainActor
final class PlayerManager: NSObject, ObservableObject {
    @Published private(set) var isPresented = false
    @Published private(set) var anime: Anime?
    @Published private(set) var episodes: [Episode] = []
    @Published private(set) var currentEpisode: Episode?
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var isBuffering = false
    @Published var playbackRate: Float = 1.0
    @Published var shouldAutoplayNext = true
    @Published var selectedSourceID: String?
    @Published var selectedQualityID: String?
    @Published var selectedAudioTrackID: String?

    let player = AVPlayer()

    private let repository: AnimeRepositoryProtocol
    private let downloadManager: DownloadManager
    private let playbackProgressStore: PlaybackProgressStore
    private var periodicTimeObserver: Any?
    private var finishObserver: NSObjectProtocol?
    private var lastSyncedBucket = -1

    #if os(iOS)
    @Published private(set) var isPictureInPictureAvailable = AVPictureInPictureController.isPictureInPictureSupported()
    private var pictureInPictureController: AVPictureInPictureController?
    #endif

    init(
        repository: AnimeRepositoryProtocol,
        downloadManager: DownloadManager,
        playbackProgressStore: PlaybackProgressStore
    ) {
        self.repository = repository
        self.downloadManager = downloadManager
        self.playbackProgressStore = playbackProgressStore
        super.init()
    }

    deinit {
        if let periodicTimeObserver {
            player.removeTimeObserver(periodicTimeObserver)
        }
        if let finishObserver {
            NotificationCenter.default.removeObserver(finishObserver)
        }
    }

    var selectedSource: PlaybackSource? {
        currentEpisode?.playbackSources.first(where: { $0.id == selectedSourceID }) ?? currentEpisode?.defaultSource
    }

    var availableSources: [PlaybackSource] {
        currentEpisode?.playbackSources ?? []
    }

    var availableQualities: [StreamQualityOption] {
        selectedSource?.qualities ?? []
    }

    var availableAudioTracks: [AudioTrack] {
        selectedSource?.audioTracks ?? []
    }

    func present(anime: Anime, episodes: [Episode], startAt episode: Episode? = nil) {
        self.anime = anime
        self.episodes = episodes
        currentEpisode = episode ?? episodes.first
        configureSelections(for: currentEpisode)
        isPresented = currentEpisode != nil

        Task {
            await loadCurrentEpisodeAndPlay()
        }
    }

    func dismiss() {
        Task { await persistCurrentProgress() }
        player.pause()
        isPresented = false
    }

    func playNextEpisode() {
        guard shouldAutoplayNext else {
            player.pause()
            isPlaying = false
            return
        }

        guard
            let currentEpisode,
            let currentIndex = episodes.firstIndex(of: currentEpisode),
            episodes.indices.contains(currentIndex + 1)
        else {
            dismiss()
            return
        }

        self.currentEpisode = episodes[currentIndex + 1]
        configureSelections(for: self.currentEpisode)
        Task {
            await loadCurrentEpisodeAndPlay()
        }
    }

    func selectEpisode(_ episode: Episode) {
        currentEpisode = episode
        configureSelections(for: currentEpisode)
        Task {
            await loadCurrentEpisodeAndPlay()
        }
    }

    func selectSource(_ source: PlaybackSource) {
        selectedSourceID = source.id
        selectedQualityID = source.qualities.first?.id
        selectedAudioTrackID = source.audioTracks.first?.id
        Task {
            await loadCurrentEpisodeAndPlay(resetProgress: false)
        }
    }

    func selectQuality(_ quality: StreamQualityOption) {
        selectedQualityID = quality.id
        Task {
            await loadCurrentEpisodeAndPlay(resetProgress: false)
        }
    }

    func selectAudioTrack(_ track: AudioTrack) {
        selectedAudioTrackID = track.id
    }

    func updatePlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player.rate = rate
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
        } else {
            player.play()
            player.rate = playbackRate
        }
        isPlaying.toggle()
    }

    func seek(by seconds: Double) {
        let target = max(0, currentTime + seconds)
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    func seek(to progress: Double) {
        guard duration > 0 else { return }
        let target = max(0, min(duration, duration * progress))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600))
    }

    func adjustVolume(by delta: Float) {
        player.volume = min(max(player.volume + delta, 0), 1)
    }

    func adjustBrightness(by delta: CGFloat) {
        #if os(iOS)
        UIScreen.main.brightness = min(max(UIScreen.main.brightness + delta, 0), 1)
        #endif
    }

    #if os(iOS)
    func configurePictureInPicture(with playerLayer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        pictureInPictureController = AVPictureInPictureController(playerLayer: playerLayer)
        pictureInPictureController?.delegate = self
    }

    func startPictureInPicture() {
        pictureInPictureController?.startPictureInPicture()
    }
    #endif

    private func configureSelections(for episode: Episode?) {
        let source = episode?.defaultSource
        selectedSourceID = source?.id
        selectedQualityID = source?.qualities.first?.id
        selectedAudioTrackID = source?.audioTracks.first?.id
    }

    private func resolvedPlaybackURL(for episode: Episode) -> URL {
        if let localURL = downloadManager.localURL(for: episode) {
            return localURL
        }

        if let qualityURL = selectedSource?.qualities.first(where: { $0.id == selectedQualityID })?.url {
            return qualityURL
        }

        return selectedSource?.streamURL ?? episode.streamURL
    }

    private func loadCurrentEpisodeAndPlay(resetProgress: Bool = false) async {
        guard let currentEpisode else { return }

        let item = AVPlayerItem(url: resolvedPlaybackURL(for: currentEpisode))
        player.replaceCurrentItem(with: item)
        isBuffering = true
        lastSyncedBucket = -1

        let savedProgress = resetProgress ? 0 : await playbackProgressStore.progress(for: currentEpisode.id)
        if savedProgress > 0 {
            await player.seek(to: CMTime(seconds: savedProgress, preferredTimescale: 600))
            currentTime = savedProgress
        } else {
            currentTime = 0
        }

        if let finishObserver {
            NotificationCenter.default.removeObserver(finishObserver)
        }

        finishObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let episode = self.currentEpisode {
                    await self.playbackProgressStore.clearProgress(for: episode.id)
                }
                self.playNextEpisode()
            }
        }

        installPeriodicProgressObserver()
        player.play()
        player.rate = playbackRate
        isPlaying = true

        let historyEntry = WatchHistoryEntry(
            id: currentEpisode.id,
            animeID: currentEpisode.animeID,
            episodeID: currentEpisode.id,
            progressSeconds: savedProgress,
            lastWatchedAt: .now
        )
        await repository.recordHistory(historyEntry)
    }

    private func installPeriodicProgressObserver() {
        if let periodicTimeObserver {
            player.removeTimeObserver(periodicTimeObserver)
        }

        periodicTimeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self, let episode = self.currentEpisode else { return }

                self.currentTime = max(0, time.seconds)
                let measuredDuration = self.player.currentItem?.duration.seconds ?? 0
                if measuredDuration.isFinite, measuredDuration > 0 {
                    self.duration = measuredDuration
                }

                self.isBuffering = self.player.timeControlStatus == .waitingToPlayAtSpecifiedRate
                self.isPlaying = self.player.timeControlStatus == .playing
                await self.playbackProgressStore.saveProgress(self.currentTime, for: episode.id)

                let syncBucket = Int(self.currentTime) / 15
                if syncBucket > self.lastSyncedBucket, self.currentTime > 1 {
                    self.lastSyncedBucket = syncBucket
                    await self.repository.recordProgress(
                        PlaybackProgressPayload(
                            animeID: episode.animeID,
                            episodeID: episode.id,
                            progressSeconds: self.currentTime,
                            durationSeconds: self.duration,
                            updatedAt: .now
                        )
                    )
                }
            }
        }
    }

    private func persistCurrentProgress() async {
        guard let episode = currentEpisode else { return }
        let seconds = max(player.currentTime().seconds, 0)
        await playbackProgressStore.saveProgress(seconds, for: episode.id)
        await repository.recordHistory(
            WatchHistoryEntry(
                id: episode.id,
                animeID: episode.animeID,
                episodeID: episode.id,
                progressSeconds: seconds,
                lastWatchedAt: .now
            )
        )
        await repository.recordProgress(
            PlaybackProgressPayload(
                animeID: episode.animeID,
                episodeID: episode.id,
                progressSeconds: seconds,
                durationSeconds: duration,
                updatedAt: .now
            )
        )
    }
}

#if os(iOS)
extension PlayerManager: AVPictureInPictureControllerDelegate {}
#endif

typealias PlayerCoordinator = PlayerManager
