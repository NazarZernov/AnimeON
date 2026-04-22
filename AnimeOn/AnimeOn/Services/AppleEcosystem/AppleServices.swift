import Foundation
import SwiftUI

final class HandoffManager {
    func handoffActivity(for anime: Anime) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "com.animeon.native.anime")
        activity.title = anime.title
        activity.userInfo = ["animeID": anime.id]
        return activity
    }
}

final class UniversalLinkRouter {
    func route(url: URL) -> AppRoute? {
        guard url.host?.contains("animeon") == true else { return nil }
        let components = url.pathComponents.filter { $0 != "/" }
        guard let first = components.first, first == "anime", components.count > 1 else { return nil }
        return .anime(components[1])
    }
}

final class SiriShortcutsManager {
    func suggestedShortcutTitle(for anime: Anime) -> String {
        "Continue \(anime.title)"
    }
}

final class WidgetDataProvider {
    func featuredTitle() -> Anime {
        MockCatalog.titles.first ?? MockCatalog.fallbackAnime
    }
}

final class ICloudSyncService {
    func statusText(enabled: Bool) -> String {
        enabled ? "Ready to sync when cloud storage is connected." : "Disabled"
    }
}

final class AppIconManager {
    func availableIcons() -> [String] {
        ["Default"]
    }
}
