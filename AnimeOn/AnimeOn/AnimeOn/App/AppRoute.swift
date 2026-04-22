import Foundation

enum AppRoute: Hashable {
    case anime(String)
    case settings
    case downloads
    case signIn
    case signUp
}

enum AppTab: Hashable {
    case home
    case search
    case schedule
    case library
    case profile
}
