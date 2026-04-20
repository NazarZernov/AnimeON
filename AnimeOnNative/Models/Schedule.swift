import Foundation

struct ScheduleDay: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let shortWeekday: String
    let shortDateLabel: String
    let releases: [ScheduleRelease]

    init(id: UUID = UUID(), date: Date, shortWeekday: String, shortDateLabel: String, releases: [ScheduleRelease]) {
        self.id = id
        self.date = date
        self.shortWeekday = shortWeekday
        self.shortDateLabel = shortDateLabel
        self.releases = releases
    }
}

struct ScheduleRelease: Identifiable, Codable, Hashable {
    let id: Int
    let animeID: Int
    let animeTitle: String
    let rating: Double?
    let episodeNumber: Int
    let releaseTime: String
    let statusText: String
}
