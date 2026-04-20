import Foundation

actor PlaybackProgressStore {
    private let defaults = UserDefaults.standard
    private let key = "animeon.playback.progress"

    func progress(for episodeID: Int) -> Double {
        let allProgress = defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
        return allProgress[String(episodeID)] ?? 0
    }

    func saveProgress(_ seconds: Double, for episodeID: Int) {
        var allProgress = defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
        allProgress[String(episodeID)] = seconds
        defaults.set(allProgress, forKey: key)
    }

    func clearProgress(for episodeID: Int) {
        var allProgress = defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
        allProgress.removeValue(forKey: String(episodeID))
        defaults.set(allProgress, forKey: key)
    }
}
