import Foundation

protocol CookieSessionStore {
    func saveCookies(_ cookies: [HTTPCookie])
    func loadCookies() -> [HTTPCookie]
}

final class InMemoryCookieSessionStore: CookieSessionStore {
    private var cookies: [HTTPCookie] = []

    func saveCookies(_ cookies: [HTTPCookie]) {
        self.cookies = cookies
    }

    func loadCookies() -> [HTTPCookie] {
        cookies
    }
}
