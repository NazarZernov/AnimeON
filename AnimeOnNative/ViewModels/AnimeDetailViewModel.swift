import Foundation

@MainActor
final class AnimeDetailViewModel: ObservableObject {
    @Published var anime: Anime
    @Published var episodesState: LoadableState<[Episode]> = .idle
    @Published var isInWatchlist = false
    @Published var isLiked = false
    @Published var selectedRating = 0
    @Published var isBusy = false
    @Published var toastMessage: String?

    private let repository: AnimeRepositoryProtocol

    init(anime: Anime, repository: AnimeRepositoryProtocol) {
        self.anime = anime
        self.repository = repository
    }

    func load(refresh: Bool = false) async {
        episodesState = .loading

        do {
            async let animeDetails = repository.anime(id: anime.id, refresh: refresh)
            async let episodes = repository.episodes(animeID: anime.id, refresh: refresh)
            async let profile = try? repository.profile(refresh: false)
            self.anime = try await animeDetails
            let loadedEpisodes = try await episodes
            episodesState = loadedEpisodes.isEmpty ? .empty("Для этого тайтла пока нет доступных серий.") : .loaded(loadedEpisodes)
            if let profile = await profile {
                isInWatchlist = profile.watchlistIDs.contains(anime.id)
                isLiked = profile.likedAnimeIDs.contains(anime.id)
                selectedRating = profile.ratings.first(where: { $0.animeID == anime.id })?.rating ?? 0
            }
        } catch {
            episodesState = .failed(error.localizedDescription)
        }
    }

    func toggleWatchlist() async {
        isBusy = true
        defer { isBusy = false }

        await repository.setWatchlist(animeID: anime.id, included: !isInWatchlist)
        isInWatchlist.toggle()
        toastMessage = isInWatchlist ? "Добавлено в watchlist" : "Удалено из watchlist"
    }

    func toggleLike() async {
        await repository.setReaction(animeID: anime.id, isLiked: !isLiked)
        isLiked.toggle()
        toastMessage = isLiked ? "Лайк сохранён" : "Лайк удалён"
    }

    func updateRating(_ rating: Int) async {
        await repository.setRating(animeID: anime.id, rating: rating)
        selectedRating = rating
        toastMessage = "Оценка \(rating)/10 сохранена"
    }
}
