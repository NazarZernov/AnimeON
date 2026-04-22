import Foundation
import WebKit

final class WebSessionManager: WebSessionBridgeProtocol {
    private let cookieStore: CookieSessionStore

    init(cookieStore: CookieSessionStore = InMemoryCookieSessionStore()) {
        self.cookieStore = cookieStore
    }

    func attachCookies(to configuration: WKWebViewConfiguration) {
        let cookies = cookieStore.loadCookies()
        let store = configuration.websiteDataStore.httpCookieStore
        for cookie in cookies {
            store.setCookie(cookie)
        }
    }

    func snapshot() async -> AuthSessionSnapshot {
        AuthSessionSnapshot(
            accessToken: nil,
            refreshToken: nil,
            cookieNames: cookieStore.loadCookies().map(\.name),
            expiresAt: nil
        )
    }
}
