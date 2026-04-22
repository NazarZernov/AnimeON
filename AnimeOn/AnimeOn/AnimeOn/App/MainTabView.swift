import SwiftUI

struct MainTabView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var playbackCoordinator: PlaybackCoordinator
    @State private var selectedTab: AppTab = .home

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics.forWidth(proxy.size.width, theme: theme)

            ZStack(alignment: .bottom) {
                TabView(selection: $selectedTab) {
                    tabNavigation {
                        HomeView()
                    }
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(AppTab.home)

                    tabNavigation {
                        SearchView()
                    }
                    .tabItem { Label("Search", systemImage: "magnifyingglass") }
                    .tag(AppTab.search)

                    tabNavigation {
                        ScheduleView()
                    }
                    .tabItem { Label("Schedule", systemImage: "calendar") }
                    .tag(AppTab.schedule)

                    tabNavigation {
                        LibraryView()
                    }
                    .tabItem { Label("Library", systemImage: "rectangle.stack.fill") }
                    .tag(AppTab.library)

                    tabNavigation {
                        ProfileView()
                    }
                    .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                    .tag(AppTab.profile)
                }
                .toolbarBackground(theme.palette.elevatedBackground, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)

                if playbackCoordinator.currentContext != nil, !playbackCoordinator.isPresentingPlayer {
                    MiniPlayerBar()
                        .padding(.horizontal, metrics.horizontalPadding)
                        .padding(.bottom, metrics.miniPlayerBottomInset + max(proxy.safeAreaInsets.bottom - 4, 0))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .themedBackground()
        .fullScreenCover(isPresented: $playbackCoordinator.isPresentingPlayer) {
            PlayerView()
        }
    }

    @ViewBuilder
    private func tabNavigation<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack {
            content()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .anime(let id):
                        TitleDetailsView(animeID: id)
                    case .settings:
                        SettingsView()
                    case .downloads:
                        DownloadsView()
                    case .signIn:
                        SignInView()
                    case .signUp:
                        SignUpView()
                    }
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppContainer.live)
        .environmentObject(AppContainer.live.settingsStore)
        .environmentObject(AppContainer.live.themeManager)
        .environmentObject(AppContainer.live.sessionStore)
        .environmentObject(AppContainer.live.downloadManager)
        .environmentObject(AppContainer.live.playbackCoordinator)
        .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
}
