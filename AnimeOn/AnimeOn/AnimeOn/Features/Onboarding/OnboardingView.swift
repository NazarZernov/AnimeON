import SwiftUI

struct OnboardingView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var sessionStore: SessionStore

    @State private var step = 0
    @State private var selectedGenres = Set([AnimeGenre.sciFi, .mystery, .drama])
    @State private var playbackStyle: PlaybackStylePreference = .cinematic
    @State private var themePreset: ThemePreset = .classicDark
    @State private var notificationsOptIn = true

    private let stepsCount = 5

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                theme.palette.background.ignoresSafeArea()
                LinearGradient(
                    colors: [theme.palette.accent.opacity(0.24), .clear, theme.palette.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .blur(radius: 70)

                VStack(alignment: .leading, spacing: 24) {
                    Text(AppDisplay.appName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.palette.accent)

                    switch step {
                    case 0:
                        welcomeStep
                    case 1:
                        genresStep
                    case 2:
                        playbackStep
                    case 3:
                        themeStep
                    default:
                        notificationsStep
                    }

                    Spacer()

                    VStack(spacing: 16) {
                        ProgressView(value: Double(step + 1), total: Double(stepsCount))
                            .tint(theme.palette.accent)

                        HStack {
                            if step > 0 {
                                Button("Back") {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        step -= 1
                                    }
                                }
                                .foregroundStyle(theme.palette.textSecondary)
                            }
                            Spacer()
                            GradientButton(step == stepsCount - 1 ? "Finish" : "Continue", systemImage: "arrow.right") {
                                if step == stepsCount - 1 {
                                    finishOnboarding()
                                } else {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        step += 1
                                    }
                                }
                            }
                            .frame(maxWidth: 200)
                        }
                    }
                }
                .padding(28)
            }
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("A premium anime experience, built natively for one-hand comfort.")
                .font(theme.typography.hero)
                .foregroundStyle(theme.palette.textPrimary)
            Text("Start with a cinematic foundation now, then grow into real authentication, streaming, downloads, and web-session bridging later without rewriting the product.")
                .font(theme.typography.body)
                .foregroundStyle(theme.palette.textSecondary)
            HStack(spacing: 10) {
                MetadataPill("Apple TV inspired", icon: "sparkles", highlighted: true)
                MetadataPill("Offline ready", icon: "arrow.down.circle")
                MetadataPill("Future API bridge", icon: "network")
            }
        }
    }

    private var genresStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose favorite genres")
                .font(theme.typography.hero)
                .foregroundStyle(theme.palette.textPrimary)
            Text("This tunes the home feed and profile tone from the first launch.")
                .font(theme.typography.body)
                .foregroundStyle(theme.palette.textSecondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                ForEach(AnimeGenre.allCases) { genre in
                    Button {
                        if selectedGenres.contains(genre) {
                            selectedGenres.remove(genre)
                        } else {
                            selectedGenres.insert(genre)
                        }
                    } label: {
                        Text(genre.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(selectedGenres.contains(genre) ? theme.palette.textPrimary : theme.palette.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedGenres.contains(genre) ? theme.palette.accentSoft : theme.palette.secondaryCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var playbackStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pick your playback feel")
                .font(theme.typography.hero)
                .foregroundStyle(theme.palette.textPrimary)
            Text("You can refine this anytime from Settings.")
                .font(theme.typography.body)
                .foregroundStyle(theme.palette.textSecondary)

            ForEach(PlaybackStylePreference.allCases) { style in
                Button {
                    playbackStyle = style
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(style.title)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.palette.textPrimary)
                            Text(description(for: style))
                                .font(theme.typography.caption)
                                .foregroundStyle(theme.palette.textSecondary)
                        }
                        Spacer()
                        Image(systemName: playbackStyle == style ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(playbackStyle == style ? theme.palette.accent : theme.palette.textTertiary)
                    }
                    .padding(18)
                    .background(theme.palette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var themeStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a starting theme")
                .font(theme.typography.hero)
                .foregroundStyle(theme.palette.textPrimary)
            Text("The full theme engine is live from launch and easy to extend later.")
                .font(theme.typography.body)
                .foregroundStyle(theme.palette.textSecondary)

            ForEach(ThemePreset.allCases) { preset in
                ThemePickerRow(
                    preset: preset,
                    selectedPreset: themePreset,
                    accent: settingsStore.settings.appearance.accentColor.color
                ) {
                    themePreset = preset
                }
            }
        }
    }

    private var notificationsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stay in sync")
                .font(theme.typography.hero)
                .foregroundStyle(theme.palette.textPrimary)
            Text("Permission prompting is a placeholder today, but the notification settings architecture is already in place.")
                .font(theme.typography.body)
                .foregroundStyle(theme.palette.textSecondary)

            Toggle("Enable episode alerts and reminders", isOn: $notificationsOptIn)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.palette.textPrimary)
                .padding(18)
                .background(theme.palette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

            Text("You’ll land directly in the full app after this step.")
                .font(theme.typography.caption)
                .foregroundStyle(theme.palette.textSecondary)
        }
    }

    private func description(for style: PlaybackStylePreference) -> String {
        switch style {
        case .seamless: L10n.tr("Fast transitions, fewer interruptions, ready for marathons.")
        case .cinematic: L10n.tr("A balanced premium default with immersive presentation.")
        case .focused: L10n.tr("Cleaner, calmer controls for concentrated viewing.")
        }
    }

    private func finishOnboarding() {
        settingsStore.settings.appearance.preset = themePreset
        settingsStore.settings.playback.playbackStyle = playbackStyle
        settingsStore.settings.notifications.newEpisodeAlerts = notificationsOptIn
        settingsStore.settings.advanced.hasCompletedOnboarding = true
        sessionStore.updatePreferredGenres(Array(selectedGenres))
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppContainer.live.settingsStore)
        .environmentObject(AppContainer.live.sessionStore)
        .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
}
