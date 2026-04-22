import Foundation
import SwiftUI

enum ThemeMode: String, Codable, CaseIterable, Identifiable {
    case system
    case dark
    case light

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: L10n.tr("System")
        case .dark: L10n.tr("Dark")
        case .light: L10n.tr("Light")
        }
    }
}

enum ThemePreset: String, Codable, CaseIterable, Identifiable {
    case classicDark
    case midnightOLED
    case softGraphite
    case neonViolet
    case warmCinema

    var id: String { rawValue }

    var title: String {
        switch self {
        case .classicDark: L10n.tr("Classic Dark")
        case .midnightOLED: L10n.tr("Midnight OLED")
        case .softGraphite: L10n.tr("Soft Graphite")
        case .neonViolet: L10n.tr("Neon Violet")
        case .warmCinema: L10n.tr("Warm Cinema")
        }
    }

    var description: String {
        switch self {
        case .classicDark: L10n.tr("Balanced premium contrast with Apple TV-inspired depth.")
        case .midnightOLED: L10n.tr("Deeper blacks and stronger cinematic separation.")
        case .softGraphite: L10n.tr("Low-glare dark surfaces with softened shadows.")
        case .neonViolet: L10n.tr("Sharper highlights and bolder violet emphasis.")
        case .warmCinema: L10n.tr("Warmer highlights for a late-night theater mood.")
        }
    }
}

enum AccentColorOption: String, Codable, CaseIterable, Identifiable {
    case violet
    case electricBlue
    case rose
    case amber
    case mint

    var id: String { rawValue }

    var title: String {
        switch self {
        case .violet: L10n.tr("Violet")
        case .electricBlue: L10n.tr("Electric Blue")
        case .rose: L10n.tr("Rose")
        case .amber: L10n.tr("Amber")
        case .mint: L10n.tr("Mint")
        }
    }

    nonisolated var color: Color {
        switch self {
        case .violet: Color(hex: 0x8B5CF6)
        case .electricBlue: Color(hex: 0x3B82F6)
        case .rose: Color(hex: 0xF472B6)
        case .amber: Color(hex: 0xF59E0B)
        case .mint: Color(hex: 0x34D399)
        }
    }
}

enum CardDensity: String, Codable, CaseIterable, Identifiable {
    case compact
    case balanced
    case spacious

    var id: String { rawValue }
    var title: String {
        switch self {
        case .compact: L10n.tr("Compact")
        case .balanced: L10n.tr("Balanced")
        case .spacious: L10n.tr("Spacious")
        }
    }
}

enum PlaybackQualityPreference: String, Codable, CaseIterable, Identifiable {
    case auto
    case dataSaver
    case p720
    case p1080
    case bestAvailable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: L10n.tr("Auto")
        case .dataSaver: L10n.tr("Data Saver")
        case .p720: "720p"
        case .p1080: "1080p"
        case .bestAvailable: L10n.tr("Best Available")
        }
    }
}

enum PlaybackSpeedPreset: String, Codable, CaseIterable, Identifiable {
    case x0_75 = "0.75x"
    case x1_0 = "1.0x"
    case x1_25 = "1.25x"
    case x1_5 = "1.5x"
    case x2_0 = "2.0x"

    var id: String { rawValue }
    var value: Double {
        switch self {
        case .x0_75: 0.75
        case .x1_0: 1.0
        case .x1_25: 1.25
        case .x1_5: 1.5
        case .x2_0: 2.0
        }
    }
}

enum AudioLanguagePreference: String, Codable, CaseIterable, Identifiable {
    case original
    case englishDub
    case japanese
    case russianDub

    var id: String { rawValue }

    var title: String {
        switch self {
        case .original: L10n.tr("Original")
        case .englishDub: L10n.tr("English Dub")
        case .japanese: L10n.tr("Japanese")
        case .russianDub: L10n.tr("Russian Dub")
        }
    }
}

enum SubtitlePreference: String, Codable, CaseIterable, Identifiable {
    case auto
    case english
    case russian
    case off

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: L10n.tr("Auto")
        case .english: L10n.tr("English")
        case .russian: L10n.tr("Russian")
        case .off: L10n.tr("Off")
        }
    }
}

enum DownloadQualityPreference: String, Codable, CaseIterable, Identifiable {
    case auto
    case dataSaver
    case p720
    case p1080

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: L10n.tr("Auto")
        case .dataSaver: L10n.tr("Data Saver")
        case .p720: "720p"
        case .p1080: "1080p"
        }
    }
}

enum StorageLimitPreset: String, Codable, CaseIterable, Identifiable {
    case gb5
    case gb15
    case gb30
    case unlimited

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gb5: "5 GB"
        case .gb15: "15 GB"
        case .gb30: "30 GB"
        case .unlimited: L10n.tr("Unlimited")
        }
    }
}

enum DataSourceMode: String, Codable, CaseIterable, Identifiable {
    case mock
    case stagingAPI
    case productionAPI
    case webSessionBridge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mock: L10n.tr("Mock")
        case .stagingAPI: L10n.tr("Staging API")
        case .productionAPI: L10n.tr("Production API")
        case .webSessionBridge: L10n.tr("Web Session Bridge")
        }
    }
}

enum PlaybackStylePreference: String, Codable, CaseIterable, Identifiable {
    case seamless
    case cinematic
    case focused

    var id: String { rawValue }
    var title: String {
        switch self {
        case .seamless: L10n.tr("Seamless")
        case .cinematic: L10n.tr("Cinematic")
        case .focused: L10n.tr("Focused")
        }
    }
}

struct QuietHours: Codable, Hashable {
    var enabled: Bool
    var startHour: Int
    var endHour: Int
}

struct AppearanceSettings: Codable, Hashable {
    var themeMode: ThemeMode
    var preset: ThemePreset
    var accentColor: AccentColorOption
    var cardDensity: CardDensity
    var reduceTransparency: Bool
    var reduceMotion: Bool
    var posterCornerRadius: Double
    var animatedBackgroundsEnabled: Bool
}

struct PlaybackSettings: Codable, Hashable {
    var playbackStyle: PlaybackStylePreference
    var defaultQuality: PlaybackQualityPreference
    var preferredAudioLanguage: AudioLanguagePreference
    var preferredSubtitles: SubtitlePreference
    var autoPlayNextEpisode: Bool
    var autoFullscreenOnPlay: Bool
    var skipIntroVisible: Bool
    var rememberPlaybackSpeed: Bool
    var defaultPlaybackSpeed: PlaybackSpeedPreset
    var resumeFromLastPosition: Bool
    var markWatchedThreshold: Double
}

struct DownloadSettings: Codable, Hashable {
    var wifiOnly: Bool
    var smartDownloadNextEpisode: Bool
    var autoDeleteWatched: Bool
    var preferredQuality: DownloadQualityPreference
    var storageLimit: StorageLimitPreset
    var showFileSizes: Bool
    var askBeforeCellularUsage: Bool
    var destinationLabel: String
}

struct NotificationSettings: Codable, Hashable {
    var newEpisodeAlerts: Bool
    var continueWatchingReminders: Bool
    var weeklyDigestEnabled: Bool
    var favoriteTitlesUpdates: Bool
    var quietHours: QuietHours
}

struct AppleEcosystemSettings: Codable, Hashable {
    var handoffReady: Bool
    var airPlayPreferred: Bool
    var pictureInPictureEnabled: Bool
    var sharePlayReady: Bool
    var siriShortcutsReady: Bool
    var widgetsReady: Bool
    var liveActivitiesReady: Bool
    var iCloudSyncReady: Bool
    var universalLinksReady: Bool
}

struct AdvancedSettings: Codable, Hashable {
    var dataSourceMode: DataSourceMode
    var baseURL: String
    var enableRequestLogging: Bool
    var hasCompletedOnboarding: Bool
}

struct AppSettings: Codable, Hashable {
    var appearance: AppearanceSettings
    var playback: PlaybackSettings
    var downloads: DownloadSettings
    var notifications: NotificationSettings
    var ecosystem: AppleEcosystemSettings
    var advanced: AdvancedSettings

    static let `default` = AppSettings(
        appearance: AppearanceSettings(
            themeMode: .dark,
            preset: .classicDark,
            accentColor: .violet,
            cardDensity: .balanced,
            reduceTransparency: false,
            reduceMotion: false,
            posterCornerRadius: 26,
            animatedBackgroundsEnabled: true
        ),
        playback: PlaybackSettings(
            playbackStyle: .cinematic,
            defaultQuality: .bestAvailable,
            preferredAudioLanguage: .original,
            preferredSubtitles: .english,
            autoPlayNextEpisode: true,
            autoFullscreenOnPlay: true,
            skipIntroVisible: true,
            rememberPlaybackSpeed: true,
            defaultPlaybackSpeed: .x1_0,
            resumeFromLastPosition: true,
            markWatchedThreshold: 0.92
        ),
        downloads: DownloadSettings(
            wifiOnly: true,
            smartDownloadNextEpisode: false,
            autoDeleteWatched: false,
            preferredQuality: .p1080,
            storageLimit: .gb15,
            showFileSizes: true,
            askBeforeCellularUsage: true,
            destinationLabel: L10n.tr("On My iPhone")
        ),
        notifications: NotificationSettings(
            newEpisodeAlerts: true,
            continueWatchingReminders: false,
            weeklyDigestEnabled: false,
            favoriteTitlesUpdates: true,
            quietHours: QuietHours(enabled: false, startHour: 23, endHour: 8)
        ),
        ecosystem: AppleEcosystemSettings(
            handoffReady: true,
            airPlayPreferred: true,
            pictureInPictureEnabled: true,
            sharePlayReady: false,
            siriShortcutsReady: false,
            widgetsReady: false,
            liveActivitiesReady: false,
            iCloudSyncReady: false,
            universalLinksReady: true
        ),
        advanced: AdvancedSettings(
            dataSourceMode: .mock,
            baseURL: "https://api.animeon.local",
            enableRequestLogging: true,
            hasCompletedOnboarding: false
        )
    )
}
