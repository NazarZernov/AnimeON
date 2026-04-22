import SwiftUI

private enum SettingsDestination: Hashable {
    case appearance
    case playback
    case downloads
    case notifications
    case ecosystem
    case advanced
}

struct SettingsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var downloadManager: DownloadManager
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics.forWidth(proxy.size.width, theme: theme)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                    VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
                        Text("Settings")
                            .font(theme.typography.display)
                            .foregroundStyle(theme.palette.textPrimary)
                        Text("Tune appearance, playback feel, downloads, and Apple ecosystem behavior without breaking the cinematic flow.")
                            .font(theme.typography.subheadline)
                            .foregroundStyle(theme.palette.textSecondary)
                    }

                    GlassCard(padding: 18, cornerRadius: theme.radii.xLarge) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AnimeOn Native")
                                .font(theme.typography.hero)
                                .foregroundStyle(theme.palette.textPrimary)
                            Text("Refine look, playback feel, offline policy, and future platform integrations.")
                                .font(theme.typography.subheadline)
                                .foregroundStyle(theme.palette.textSecondary)

                            HStack(spacing: 8) {
                                MetadataPill(settingsStore.settings.appearance.preset.title, icon: "paintpalette.fill", highlighted: true)
                                MetadataPill(settingsStore.settings.advanced.dataSourceMode.title, icon: "network")
                            }
                        }
                    }

                    VStack(spacing: 10) {
                        settingsLink("Appearance", subtitle: "Theme, accents, density, and motion", value: settingsStore.settings.appearance.preset.title, icon: "wand.and.stars", tint: theme.palette.accent, destination: .appearance)
                        settingsLink("Playback", subtitle: "Quality, language, speed, and thresholds", value: settingsStore.settings.playback.defaultQuality.title, icon: "play.rectangle.fill", tint: theme.palette.positive, destination: .playback)
                        settingsLink("Downloads", subtitle: "Offline quality, storage, cache, and cellular policy", value: downloadManager.storageSummary(limit: settingsStore.settings.downloads.storageLimit).usedText, icon: "arrow.down.circle.fill", tint: theme.palette.warning, destination: .downloads)
                        settingsLink("Notifications", subtitle: "Episode alerts, reminders, and quiet hours", value: settingsStore.settings.notifications.newEpisodeAlerts ? "Enabled" : "Off", icon: "bell.badge.fill", tint: .orange.opacity(0.85), destination: .notifications)
                        settingsLink("Apple Ecosystem", subtitle: "PiP, Handoff, AirPlay, widgets, and links", value: settingsStore.settings.ecosystem.pictureInPictureEnabled ? "PiP On" : "Ready", icon: "apple.logo", tint: .white.opacity(0.82), destination: .ecosystem)
                        settingsLink("Advanced", subtitle: "Data source switching, diagnostics, and reset tools", value: settingsStore.settings.advanced.dataSourceMode.title, icon: "gearshape.2.fill", tint: .white.opacity(0.82), destination: .advanced)
                    }
                }
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, theme.spacing.small)
                .padding(.bottom, 120 + proxy.safeAreaInsets.bottom)
            }
        }
        .themedBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: SettingsDestination.self) { destination in
            switch destination {
            case .appearance: AppearanceSettingsView()
            case .playback: PlaybackSettingsView()
            case .downloads: DownloadSettingsView()
            case .notifications: NotificationSettingsView()
            case .ecosystem: AppleEcosystemSettingsView()
            case .advanced: AdvancedSettingsView()
            }
        }
    }

    private func settingsLink(
        _ title: String,
        subtitle: String,
        value: String,
        icon: String,
        tint: Color,
        destination: SettingsDestination
    ) -> some View {
        NavigationLink(value: destination) {
            SettingsRowShell(icon: icon, title: title, subtitle: subtitle, tint: tint) {
                HStack(spacing: 8) {
                    Text(value.localized)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textTertiary)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(theme.palette.textTertiary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct AppearanceSettingsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SettingsSectionContainer(title: "Theme Mode", subtitle: "System-driven or pinned for late-night viewing") {
                    Picker("Theme Mode", selection: settingsStore.binding(for: \AppearanceSettings.themeMode)) {
                        ForEach(ThemeMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                SettingsSectionContainer(title: "Style Presets", subtitle: "Curated visual personalities for the entire app") {
                    ForEach(ThemePreset.allCases) { preset in
                        ThemePickerRow(
                            preset: preset,
                            selectedPreset: settingsStore.settings.appearance.preset,
                            accent: settingsStore.settings.appearance.accentColor.color
                        ) {
                            settingsStore.settings.appearance.preset = preset
                        }
                    }
                }

                SettingsSectionContainer(title: "Accent + Layout", subtitle: "Precision tuning for surfaces and motion") {
                    Picker("Card Density", selection: settingsStore.binding(for: \AppearanceSettings.cardDensity)) {
                        ForEach(CardDensity.allCases) { density in
                            Text(density.title).tag(density)
                        }
                    }

                    Toggle("Reduce Transparency", isOn: settingsStore.binding(for: \AppearanceSettings.reduceTransparency))
                    Toggle("Reduce Motion", isOn: settingsStore.binding(for: \AppearanceSettings.reduceMotion))
                    Toggle("Animated Backgrounds", isOn: settingsStore.binding(for: \AppearanceSettings.animatedBackgroundsEnabled))

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Poster Corner Radius")
                            .foregroundStyle(theme.palette.textPrimary)
                        Slider(value: settingsStore.binding(for: \AppearanceSettings.posterCornerRadius), in: 12...34, step: 1)
                            .tint(theme.palette.accent)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Accent Color")
                            .foregroundStyle(theme.palette.textPrimary)
                        HStack(spacing: 10) {
                            ForEach(AccentColorOption.allCases) { accent in
                                Button {
                                    settingsStore.settings.appearance.accentColor = accent
                                } label: {
                                    Circle()
                                        .fill(accent.color)
                                        .frame(width: 28, height: 28)
                                        .overlay(
                                            Circle()
                                                .stroke(settingsStore.settings.appearance.accentColor == accent ? Color.white : .clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(theme.spacing.large)
        }
        .themedBackground()
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .pickerStyle(.menu)
        .tint(theme.palette.accent)
    }
}

private struct PlaybackSettingsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SettingsSectionContainer(title: "Playback Defaults", subtitle: "Personalize launch behavior and stream quality") {
                    Picker("Playback Style", selection: settingsStore.binding(for: \PlaybackSettings.playbackStyle)) {
                        ForEach(PlaybackStylePreference.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }

                    Picker("Default Quality", selection: settingsStore.binding(for: \PlaybackSettings.defaultQuality)) {
                        ForEach(PlaybackQualityPreference.allCases) { quality in
                            Text(quality.title).tag(quality)
                        }
                    }

                    Picker("Preferred Audio", selection: settingsStore.binding(for: \PlaybackSettings.preferredAudioLanguage)) {
                        ForEach(AudioLanguagePreference.allCases) { language in
                            Text(language.title).tag(language)
                        }
                    }

                    Picker("Preferred Subtitles", selection: settingsStore.binding(for: \PlaybackSettings.preferredSubtitles)) {
                        ForEach(SubtitlePreference.allCases) { subtitles in
                            Text(subtitles.title).tag(subtitles)
                        }
                    }
                }

                SettingsSectionContainer(title: "Behavior", subtitle: "Match the player to your habits") {
                    Toggle("Auto-Play Next Episode", isOn: settingsStore.binding(for: \PlaybackSettings.autoPlayNextEpisode))
                    Toggle("Auto Full Screen on Play", isOn: settingsStore.binding(for: \PlaybackSettings.autoFullscreenOnPlay))
                    Toggle("Show Skip Intro Button", isOn: settingsStore.binding(for: \PlaybackSettings.skipIntroVisible))
                    Toggle("Remember Playback Speed", isOn: settingsStore.binding(for: \PlaybackSettings.rememberPlaybackSpeed))
                    Toggle("Resume From Last Position", isOn: settingsStore.binding(for: \PlaybackSettings.resumeFromLastPosition))

                    Picker("Default Speed", selection: settingsStore.binding(for: \PlaybackSettings.defaultPlaybackSpeed)) {
                        ForEach(PlaybackSpeedPreset.allCases) { speed in
                            Text(speed.rawValue).tag(speed)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.markWatchedThreshold(Int(settingsStore.settings.playback.markWatchedThreshold * 100)))
                            .foregroundStyle(theme.palette.textPrimary)
                        Slider(value: settingsStore.binding(for: \PlaybackSettings.markWatchedThreshold), in: 0.7...0.98, step: 0.01)
                            .tint(theme.palette.accent)
                    }
                }
            }
            .padding(theme.spacing.large)
        }
        .themedBackground()
        .navigationTitle("Playback")
        .navigationBarTitleDisplayMode(.inline)
        .pickerStyle(.menu)
        .tint(theme.palette.accent)
    }
}

private struct DownloadSettingsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var downloadManager: DownloadManager

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SettingsSectionContainer(title: "Transfer Policy", subtitle: "Control how offline media is fetched and retained") {
                    Toggle("Download Over Wi-Fi Only", isOn: settingsStore.binding(for: \DownloadSettings.wifiOnly))
                    Toggle("Smart Download Next Episode", isOn: settingsStore.binding(for: \DownloadSettings.smartDownloadNextEpisode))
                    Toggle("Auto-Delete Watched Downloads", isOn: settingsStore.binding(for: \DownloadSettings.autoDeleteWatched))
                    Toggle("Show File Sizes", isOn: settingsStore.binding(for: \DownloadSettings.showFileSizes))
                    Toggle("Ask Before Cellular Usage", isOn: settingsStore.binding(for: \DownloadSettings.askBeforeCellularUsage))
                }

                SettingsSectionContainer(title: "Quality + Storage", subtitle: "Dial in offline balance") {
                    Picker("Preferred Quality", selection: settingsStore.binding(for: \DownloadSettings.preferredQuality)) {
                        ForEach(DownloadQualityPreference.allCases) { quality in
                            Text(quality.title).tag(quality)
                        }
                    }
                    Picker("Storage Limit", selection: settingsStore.binding(for: \DownloadSettings.storageLimit)) {
                        ForEach(StorageLimitPreset.allCases) { limit in
                            Text(limit.title).tag(limit)
                        }
                    }
                    TextField("Destination", text: settingsStore.binding(for: \DownloadSettings.destinationLabel))
                }

                SettingsSectionContainer(title: "Maintenance", subtitle: "Mock cleanup actions wired to local state") {
                    Button("Clear Cache") {
                        downloadManager.removeAllFailed()
                    }
                    Button("Clear Downloaded Metadata") {
                        downloadManager.clearCompletedMetadata()
                    }
                }
            }
            .padding(theme.spacing.large)
        }
        .themedBackground()
        .navigationTitle("Downloads")
        .navigationBarTitleDisplayMode(.inline)
        .pickerStyle(.menu)
        .tint(theme.palette.accent)
    }
}

private struct NotificationSettingsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SettingsSectionContainer(title: "Alert Types", subtitle: "What should gently pull you back in") {
                    Toggle("New Episode Alerts", isOn: settingsStore.binding(for: \NotificationSettings.newEpisodeAlerts))
                    Toggle("Continue Watching Reminders", isOn: settingsStore.binding(for: \NotificationSettings.continueWatchingReminders))
                    Toggle("Weekly Digest", isOn: settingsStore.binding(for: \NotificationSettings.weeklyDigestEnabled))
                    Toggle("Favorite Titles Updates", isOn: settingsStore.binding(for: \NotificationSettings.favoriteTitlesUpdates))
                }

                SettingsSectionContainer(title: "Quiet Hours", subtitle: "Placeholder UI ready for real scheduling logic") {
                    Toggle("Enable Quiet Hours", isOn: Binding(
                        get: { settingsStore.settings.notifications.quietHours.enabled },
                        set: { settingsStore.settings.notifications.quietHours.enabled = $0 }
                    ))
                    Stepper(L10n.startHour(settingsStore.settings.notifications.quietHours.startHour), value: Binding(
                        get: { settingsStore.settings.notifications.quietHours.startHour },
                        set: { settingsStore.settings.notifications.quietHours.startHour = $0 }
                    ), in: 0...23)
                    Stepper(L10n.endHour(settingsStore.settings.notifications.quietHours.endHour), value: Binding(
                        get: { settingsStore.settings.notifications.quietHours.endHour },
                        set: { settingsStore.settings.notifications.quietHours.endHour = $0 }
                    ), in: 0...23)
                }
            }
            .padding(theme.spacing.large)
        }
        .themedBackground()
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .tint(theme.palette.accent)
    }
}

private struct AppleEcosystemSettingsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SettingsSectionContainer(title: "Playback Surface", subtitle: "Apple platform handoffs and large-screen options") {
                    Toggle("Handoff Ready", isOn: settingsStore.binding(for: \AppleEcosystemSettings.handoffReady))
                    Toggle("Prefer AirPlay", isOn: settingsStore.binding(for: \AppleEcosystemSettings.airPlayPreferred))
                    Toggle("Picture in Picture", isOn: settingsStore.binding(for: \AppleEcosystemSettings.pictureInPictureEnabled))
                    Toggle("SharePlay Ready", isOn: settingsStore.binding(for: \AppleEcosystemSettings.sharePlayReady))
                }

                SettingsSectionContainer(title: "OS Integrations", subtitle: "Hooks for Siri, widgets, and live surfaces") {
                    Toggle("Siri Shortcuts", isOn: settingsStore.binding(for: \AppleEcosystemSettings.siriShortcutsReady))
                    Toggle("Widgets", isOn: settingsStore.binding(for: \AppleEcosystemSettings.widgetsReady))
                    Toggle("Live Activities", isOn: settingsStore.binding(for: \AppleEcosystemSettings.liveActivitiesReady))
                    Toggle("iCloud Sync", isOn: settingsStore.binding(for: \AppleEcosystemSettings.iCloudSyncReady))
                    Toggle("Universal Links", isOn: settingsStore.binding(for: \AppleEcosystemSettings.universalLinksReady))
                }
            }
            .padding(theme.spacing.large)
        }
        .themedBackground()
        .navigationTitle("Apple Ecosystem")
        .navigationBarTitleDisplayMode(.inline)
        .tint(theme.palette.accent)
    }
}

private struct AdvancedSettingsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                SettingsSectionContainer(title: "Data Source", subtitle: "Swap transport layers without touching UI code") {
                    Picker("Mode", selection: settingsStore.binding(for: \AdvancedSettings.dataSourceMode)) {
                        ForEach(DataSourceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    TextField("Base URL", text: settingsStore.binding(for: \AdvancedSettings.baseURL))
                        .textInputAutocapitalization(.never)
                    Toggle("Enable Request Logging", isOn: settingsStore.binding(for: \AdvancedSettings.enableRequestLogging))
                }

                SettingsSectionContainer(title: "Reset Tools", subtitle: "Local-only maintenance actions") {
                    Button("Reset Onboarding") {
                        settingsStore.resetOnboarding()
                    }
                    Button("Reset App State") {
                        settingsStore.resetAll()
                    }
                    Button("Clear Recent Searches") {
                        container.recentSearchStore.clear()
                    }
                }

                SettingsSectionContainer(title: "Diagnostics", subtitle: "Placeholder surfaces ready for real logging exports") {
                    Text("Session diagnostics: cookie store, token snapshot, and restore state hooks live in the WebSession services layer.")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.palette.textSecondary)
                    Text("Streaming diagnostics: playback engine, route selection, and quality fallback hooks live in Services/Playback.")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.palette.textSecondary)
                }
            }
            .padding(theme.spacing.large)
        }
        .themedBackground()
        .navigationTitle("Advanced")
        .pickerStyle(.menu)
        .tint(theme.palette.accent)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environmentObject(AppContainer.live)
    .environmentObject(AppContainer.live.settingsStore)
    .environmentObject(AppContainer.live.downloadManager)
    .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
}
