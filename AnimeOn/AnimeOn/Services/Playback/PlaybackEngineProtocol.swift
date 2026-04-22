import AVKit
import Foundation

@MainActor
protocol PlaybackEngineProtocol: AnyObject {
    var player: AVPlayer { get }
    var isPlaying: Bool { get }
    var currentTime: Double { get }
    var duration: Double { get }
    var rate: Double { get }
    func load(url: URL)
    func play()
    func pause()
    func seek(by seconds: Double)
    func seek(to seconds: Double)
    func setRate(_ rate: Double)
}
