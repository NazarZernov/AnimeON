import Combine
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published private(set) var sessionState: SessionState = .loading

    private let sessionRepository: any SessionRepository

    init(sessionRepository: any SessionRepository) {
        self.sessionRepository = sessionRepository
        Task {
            await restore()
        }
    }

    func restore() async {
        do {
            sessionState = try await sessionRepository.restoreSession()
        } catch {
            sessionState = .signedOut
        }
    }

    func signInMock() {
        sessionState = .authenticated(MockCatalog.profile)
    }

    func updatePreferredGenres(_ genres: [AnimeGenre]) {
        guard case .authenticated(var profile) = sessionState else { return }
        profile.preferredGenres = genres
        sessionState = .authenticated(profile)
    }

    func signOut() {
        sessionState = .signedOut
        Task {
            try? await sessionRepository.saveSessionSnapshot(nil)
        }
    }
}
