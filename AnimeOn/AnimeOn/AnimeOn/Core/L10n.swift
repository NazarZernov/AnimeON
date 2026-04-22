import Foundation

enum L10n {
    static func tr(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        let format = tr(key)
        return String(format: format, locale: Locale.current, arguments: arguments)
    }

    static func episode(_ number: Int) -> String {
        format("Episode %d", number)
    }

    static func episodeWithTitle(_ number: Int, _ title: String) -> String {
        format("Episode %1$d • %2$@", number, title)
    }

    static func episodeMinutesLeft(_ number: Int, _ minutes: Int) -> String {
        format("Episode %1$d • %2$d min left", number, minutes)
    }

    static func episodeWatched(_ number: Int, _ percent: Int) -> String {
        format("Episode %1$d • %2$d%% watched", number, percent)
    }

    static func episodeRuntime(_ number: Int, _ runtime: String) -> String {
        format("Episode %1$d • %2$@ runtime", number, runtime)
    }

    static func titlesInShelf(_ count: Int) -> String {
        format("%d titles in this shelf", count)
    }

    static func removeFrom(_ category: String) -> String {
        format("Remove from %@", category)
    }

    static func bytesOf(_ downloaded: String, _ total: String) -> String {
        format("%1$@ of %2$@", downloaded, total)
    }

    static func limit(_ value: String) -> String {
        format("Limit: %@", value)
    }

    static func markWatchedThreshold(_ percent: Int) -> String {
        format("Mark Watched Threshold: %d%%", percent)
    }

    static func startHour(_ hour: Int) -> String {
        format("Start Hour: %d:00", hour)
    }

    static func endHour(_ hour: Int) -> String {
        format("End Hour: %d:00", hour)
    }

    static func nextUpEpisode(_ number: Int) -> String {
        format("Next Up • Episode %d", number)
    }

    static func hoursShort(_ hours: Int) -> String {
        format("%d h", hours)
    }

    static func compactMinutes(_ minutes: Int) -> String {
        format("%d m", minutes)
    }

    static func dubs(_ count: Int) -> String {
        format("%d dub", count)
    }

    static func subtitles(_ count: Int) -> String {
        format("%d subs", count)
    }

    static func yearStatusStudio(_ year: Int, _ status: String, _ studio: String) -> String {
        format("%1$d • %2$@ • %3$@", year, status, studio)
    }

    static func originalYearStatus(_ originalTitle: String, _ year: Int, _ status: String) -> String {
        format("%1$@ • %2$d • %3$@", originalTitle, year, status)
    }

    static func episodeCountStatusStudio(_ episodeCount: Int, _ status: String, _ studio: String) -> String {
        format("%1$d episodes • %2$@ • %3$@", episodeCount, status, studio)
    }
}

extension String {
    var localized: String {
        L10n.tr(self)
    }
}
