import Foundation

protocol AnimeServicing {
    func fetchHome() async throws -> HomePayload
    func fetchCatalog(page: Int, pageSize: Int, filters: CatalogFilters) async throws -> CatalogResponse
    func fetchAnime(id: Int) async throws -> Anime
    func fetchEpisodes(animeID: Int) async throws -> [Episode]
    func search(query: String) async throws -> [Anime]
    func randomAnime() async throws -> Anime
    func fetchSchedule() async throws -> [ScheduleDay]
    func fetchUpdates() async throws -> [UpdateItem]
    func fetchNews() async throws -> [NewsItem]
    func fetchPremiumPlans() async throws -> [PremiumPlan]
    func login(email: String, password: String) async throws -> UserSession
    func fetchProfile() async throws -> UserProfile
    func updateWatchlist(animeID: Int, action: WatchlistAction) async throws
    func updateHistory(entry: WatchHistoryEntry) async throws
    func updateProgress(_ payload: PlaybackProgressPayload) async throws
    func updateReaction(_ payload: AnimeReactionPayload) async throws
    func updateRating(_ payload: AnimeRatingPayload) async throws
    func postStats(_ event: UserStatEvent) async throws
}
