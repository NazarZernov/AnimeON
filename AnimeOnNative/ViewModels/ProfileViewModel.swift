import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profileState: LoadableState<UserProfile> = .idle
    @Published var email = "premium@animeon.su"
    @Published var password = "animeon"
    @Published var isAuthenticated = false
    @Published var authError: String?
    @Published private(set) var watchlistPreview: [Anime] = []
    @Published private(set) var historyPreview: [Anime] = []

    private let repository: AnimeRepositoryProtocol

    init(repository: AnimeRepositoryProtocol) {
        self.repository = repository
    }

    func login() async {
        authError = nil

        do {
            _ = try await repository.login(email: email, password: password)
            isAuthenticated = true
            await loadProfile()
        } catch {
            authError = error.localizedDescription
        }
    }

    func loadProfile() async {
        guard isAuthenticated else {
            profileState = .idle
            return
        }

        profileState = .loading
        do {
            let profile = try await repository.profile(refresh: true)
            profileState = .loaded(profile)
            watchlistPreview = await loadAnimeList(ids: Array(profile.watchlistIDs.prefix(8)))
            historyPreview = await loadAnimeList(ids: uniqueHistoryIDs(from: profile))
        } catch {
            profileState = .failed(error.localizedDescription)
        }
    }

    private func loadAnimeList(ids: [Int]) async -> [Anime] {
        var result: [Anime] = []

        for id in ids {
            if let anime = try? await repository.anime(id: id, refresh: false) {
                result.append(anime)
            }
        }

        return result
    }

    private func uniqueHistoryIDs(from profile: UserProfile) -> [Int] {
        var seen = Set<Int>()
        var ids: [Int] = []

        for entry in profile.history {
            if seen.insert(entry.animeID).inserted {
                ids.append(entry.animeID)
            }
            if ids.count == 6 {
                break
            }
        }

        return ids
    }
}
