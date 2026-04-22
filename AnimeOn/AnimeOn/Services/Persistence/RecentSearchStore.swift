import Combine
import Foundation

@MainActor
final class RecentSearchStore: ObservableObject {
    @Published private(set) var items: [String]

    private let defaults: UserDefaults
    private let key = "animeon.recentSearches"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.items = defaults.stringArray(forKey: key) ?? []
    }

    func save(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        items.insert(trimmed, at: 0)
        items = Array(items.prefix(8))
        persist()
    }

    func clear() {
        items.removeAll()
        persist()
    }

    private func persist() {
        defaults.set(items, forKey: key)
    }
}
