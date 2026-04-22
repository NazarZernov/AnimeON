import AVKit
import Combine
import Foundation

@MainActor
final class NativePlaybackEngine: NSObject, ObservableObject, PlaybackEngineProtocol {
    let player = AVPlayer()

    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: Double = 0
    @Published private(set) var duration: Double = 1
    @Published private(set) var rate: Double = 1

    private var timeObserverToken: Any?

    override init() {
        super.init()
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds.isFinite ? time.seconds : 0
                let durationValue = self.player.currentItem?.duration.seconds ?? 1
                self.duration = durationValue.isFinite && durationValue > 0 ? durationValue : 1
                self.isPlaying = self.player.rate > 0
                self.rate = Double(self.player.rate)
            }
        }
    }

    deinit {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
        }
    }

    func load(url: URL) {
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        currentTime = 0
        duration = 1
    }

    func play() {
        player.play()
        player.rate = Float(rate)
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func seek(by seconds: Double) {
        seek(to: max(currentTime + seconds, 0))
    }

    func seek(to seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
    }

    func setRate(_ rate: Double) {
        self.rate = rate
        if isPlaying {
            player.rate = Float(rate)
        }
    }
}
