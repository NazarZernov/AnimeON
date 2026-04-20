import Foundation

struct UpdateItem: Identifiable, Codable, Hashable {
    let id: Int
    let animeID: Int
    let animeTitle: String
    let episodeNumber: Int
    let summary: String
    let publishedAt: Date
}

struct NewsItem: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let summary: String
    let body: String
    let imageURL: URL
    let publishedAt: Date
    let tag: String
}

struct PlayerLeaderboardEntry: Identifiable, Codable, Hashable {
    let id: Int
    let rank: Int
    let username: String
    let avatarURL: URL
    let isPremium: Bool
    let watchTimeLabel: String
    let tier: String
    let score: Int
}

struct PremiumPlan: Identifiable, Codable, Hashable {
    let id: Int
    let title: String
    let price: String
    let oldPrice: String
    let badge: String?
    let monthlyEquivalent: String
    let features: [String]
}
