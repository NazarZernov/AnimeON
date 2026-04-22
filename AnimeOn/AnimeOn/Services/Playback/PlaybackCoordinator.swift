import Combine
import Foundation

@MainActor
final class PlaybackCoordinator: ObservableObject {
    @Published private(set) var currentContext: PlayerContext?
    @Published var isPresentingPlayer = false

    let engine: NativePlaybackEngine
    let animeRepository: any AnimeRepository

    private let playbackRepository: any PlaybackRepository
    private let libraryRepository: any LibraryRepository

    init(
        engine: NativePlaybackEngine,
        playbackRepository: any PlaybackRepository,
        animeRepository: any AnimeRepository,
        libraryRepository: any LibraryRepository
    ) {
        self.engine = engine
        self.playbackRepository = playbackRepository
        self.animeRepository = animeRepository
        self.libraryRepository = libraryRepository
    }

    var trackOptions: PlayerTrackOptions {
        PlayerTrackOptions(
            audioOptions: ["Original", "English Dub", "Russian Dub"],
            subtitleOptions: ["Off", "English", "Russian"],
            qualityOptions: ["Auto", "720p", "1080p"]
        )
    }

    func startPlayback(anime: Anime, episode: Episode, preferredURL: URL? = nil, autoPresent: Bool = true) {
        currentContext = PlayerContext(anime: anime, episode: episode)
        if let url = preferredURL ?? episode.videoURL {
            engine.load(url: url)
            engine.play()
        }
        if autoPresent {
            isPresentingPlayer = true
        }
    }

    func dismissPlayer() {
        isPresentingPlayer = false
    }

    func closePlayback() {
        saveProgressSnapshot()
        engine.pause()
        currentContext = nil
        isPresentingPlayer = false
    }

    func togglePlayback() {
        engine.isPlaying ? engine.pause() : engine.play()
    }

    func skip(by seconds: Double) {
        engine.seek(by: seconds)
    }

    func selectRate(_ rate: Double) {
        engine.setRate(rate)
    }

    func nextEpisode() -> Episode? {
        guard let context = currentContext else { return nil }
        let episodes = context.anime.seasons.flatMap(\.episodes)
        guard let index = episodes.firstIndex(where: { $0.id == context.episode.id }), index + 1 < episodes.count else {
            return nil
        }
        return episodes[index + 1]
    }

    func playNextEpisode() {
        guard let current = currentContext,
              let nextEpisode = nextEpisode() else { return }
        startPlayback(anime: current.anime, episode: nextEpisode)
    }

    func saveProgressSnapshot() {
        guard let context = currentContext else { return }
        let progress = PlaybackProgress(
            episodeID: context.episode.id,
            animeID: context.anime.id,
            progress: min(max(engine.currentTime / max(engine.duration, 1), 0), 1),
            positionSeconds: engine.currentTime,
            durationSeconds: engine.duration,
            lastUpdated: .now
        )
        Task {
            try? await playbackRepository.saveProgress(progress)
            try? await libraryRepository.updatePlaybackProgress(progress)
        }
    }
}
