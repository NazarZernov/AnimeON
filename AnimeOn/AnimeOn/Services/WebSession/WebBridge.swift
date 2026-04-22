import Foundation
import WebKit

protocol WebSessionBridgeProtocol {
    func attachCookies(to configuration: WKWebViewConfiguration)
    func snapshot() async -> AuthSessionSnapshot
}

protocol FutureWebPlaybackBridgeProtocol {
    func resolvePlaybackURL(for episode: Episode) async throws -> URL?
}

final class WebPlaybackBridge: FutureWebPlaybackBridgeProtocol {
    func resolvePlaybackURL(for episode: Episode) async throws -> URL? {
        episode.videoURL
    }
}
