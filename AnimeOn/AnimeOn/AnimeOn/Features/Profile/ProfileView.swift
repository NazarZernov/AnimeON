import Combine
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: UserProfile?
    @Published private(set) var stats: ProfileStats?

    func load(
        profileRepository: any ProfileRepository,
        libraryRepository: any LibraryRepository,
        downloadManager: DownloadManager,
        settings: AppSettings
    ) async {
        do {
            async let profileValue = profileRepository.fetchProfile()
            async let libraryValue = libraryRepository.fetchLibrarySections()
            let (profile, library) = try await (profileValue, libraryValue)
            let favorites = library.first(where: { $0.category == .favorites })?.items.count ?? 0
            let continueWatching = library.first(where: { $0.category == .continueWatching })?.items.count ?? 0
            self.profile = profile
            self.stats = ProfileStats(
                favoritesCount: favorites,
                downloadedStorageText: downloadManager.storageSummary(limit: settings.downloads.storageLimit).usedText,
                continueWatchingCount: continueWatching
            )
        } catch {
            profile = nil
            stats = nil
        }
    }
}

struct ProfileView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var sessionStore: SessionStore
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.spacing.large) {
                switch sessionStore.sessionState {
                case .loading:
                    LoadingSkeletonView(height: 220, cornerRadius: theme.radii.large)
                case .signedOut:
                    signedOutView
                case .authenticated:
                    authenticatedView
                }
            }
            .padding(.horizontal, theme.spacing.large)
            .padding(.top, theme.spacing.small)
            .padding(.bottom, 120)
        }
        .themedBackground()
        .navigationTitle("Profile")
        .task {
            await reload()
        }
    }

    private var signedOutView: some View {
        EmptyStateView(
            title: "Sign In to Sync",
            message: "The account architecture is ready for real API or web-session auth later. For now, sign in to restore the mock premium profile.",
            systemImage: "person.crop.circle.badge.exclamationmark",
            actionTitle: "Open Sign In"
        ) {
            sessionStore.signInMock()
        }
    }

    private var authenticatedView: some View {
        VStack(alignment: .leading, spacing: theme.spacing.large) {
            if let profile = viewModel.profile, let stats = viewModel.stats {
                GlassCard {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 16) {
                            Image(systemName: profile.avatarSymbolName)
                                .font(.system(size: 44))
                                .foregroundStyle(theme.palette.textPrimary)
                                .frame(width: 76, height: 76)
                                .background(theme.palette.secondaryCard, in: Circle())

                            VStack(alignment: .leading, spacing: 6) {
                                Text(profile.nickname)
                                    .font(theme.typography.hero)
                                    .foregroundStyle(theme.palette.textPrimary)
                                Text(profile.levelTitle.localized)
                                    .font(theme.typography.body)
                                    .foregroundStyle(theme.palette.textSecondary)
                            }
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(profile.badges, id: \.self) { badge in
                                    MetadataPill(badge, icon: "seal.fill")
                                }
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    statCard(title: "Watched Time", value: L10n.hoursShort(profile.totalWatchedHours))
                    statCard(title: "Episodes", value: "\(profile.totalEpisodes)")
                }

                HStack(spacing: 12) {
                    statCard(title: "Favorites", value: "\(stats.favoritesCount)")
                    statCard(title: "Offline Storage", value: stats.downloadedStorageText)
                }

                SettingsSectionContainer(title: "Quick Actions", subtitle: "Shortcuts into your premium stack") {
                    NavigationLink(value: AppRoute.settings) { profileRow("Settings", icon: "gearshape.fill", tint: theme.palette.accent) }
                    NavigationLink(value: AppRoute.downloads) { profileRow("Downloads", icon: "arrow.down.circle.fill", tint: theme.palette.positive) }
                    NavigationLink(value: AppRoute.signIn) { profileRow("Account Session", icon: "person.badge.key.fill", tint: theme.palette.warning) }
                    Button {
                        sessionStore.signOut()
                    } label: {
                        profileRow("Sign Out", icon: "rectangle.portrait.and.arrow.right", tint: .red.opacity(0.82))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func statCard(title: String, value: String) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(title.localized)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.palette.textSecondary)
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.palette.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func profileRow(_ title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 24)
            Text(title.localized)
                .foregroundStyle(theme.palette.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(theme.palette.textTertiary)
        }
        .font(.system(size: 16, weight: .semibold, design: .rounded))
    }

    private func reload() async {
        await viewModel.load(
            profileRepository: container.profileRepository,
            libraryRepository: container.libraryRepository,
            downloadManager: container.downloadManager,
            settings: container.settingsStore.settings
        )
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .environmentObject(AppContainer.live)
    .environmentObject(AppContainer.live.sessionStore)
    .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
}
