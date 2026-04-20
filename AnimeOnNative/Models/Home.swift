import Foundation

struct HomePayload: Codable, Hashable {
    let featured: Anime
    let popularOngoing: [Anime]
    let newEpisodes: [Anime]
    let popularAllTime: [Anime]
    let topHundred: [Anime]
    let leaderboard: [PlayerLeaderboardEntry]
}

struct HomeDashboard: Codable, Hashable {
    let heroFeed: HomePayload
    let updates: [UpdateItem]
    let news: [NewsItem]
    let schedule: [ScheduleDay]
    let randomPick: Anime
}
