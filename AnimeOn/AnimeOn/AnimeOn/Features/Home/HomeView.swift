import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    enum LoadState {
        case loading
        case loaded(HomeContent)
        case empty
        case failed(String)
    }

    @Published private(set) var state: LoadState = .loading
    @Published private(set) var recentProgress: [String: PlaybackProgress] = [:]

    func load(
        homeRepository: any HomeRepository,
        playbackRepository: any PlaybackRepository
    ) async {
        state = .loading
        do {
            async let home = homeRepository.fetchHomeContent()
            async let progress = playbackRepository.fetchRecentProgress()
            let (content, history) = try await (home, progress)
            recentProgress = Dictionary(uniqueKeysWithValues: history.map { ($0.animeID, $0) })
            state = content.shelves.isEmpty ? .empty : .loaded(content)
        } catch {
            state = .failed("Unable to refresh the home feed right now.")
        }
    }
}

struct HomeView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var playbackCoordinator: PlaybackCoordinator
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedHeroAnimeID: String?

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics.forWidth(proxy.size.width, theme: theme)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                    switch viewModel.state {
                    case .loading:
                        loadingContent(metrics: metrics)
                    case .empty:
                        EmptyStateView(
                            title: "Home Will Warm Up Soon",
                            message: "Your shelves are ready for personalized picks as soon as the catalog refreshes.",
                            systemImage: "sparkles.tv",
                            actionTitle: "Reload"
                        ) {
                            Task { await reload() }
                        }
                    case .failed(let message):
                        EmptyStateView(
                            title: "Home Couldn’t Load",
                            message: message,
                            systemImage: "wifi.exclamationmark",
                            actionTitle: "Try Again"
                        ) {
                            Task { await reload() }
                        }
                    case .loaded(let content):
                        topHeader(metrics: metrics)

                        if let continueShelf = continueShelf(from: content.shelves) {
                            shelfView(continueShelf, metrics: metrics)
                        }

                        HeroCard(
                            anime: content.featured,
                            metrics: metrics,
                            onPlay: { playFirstEpisode(of: content.featured) },
                            onDetails: { selectedHeroAnimeID = content.featured.id }
                        )

                        ForEach(orderedShelves(from: content.shelves).filter { $0.style != .continueWatching }) { shelf in
                            shelfView(shelf, metrics: metrics)
                        }
                    }
                }
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, theme.spacing.small)
                .padding(.bottom, 120 + proxy.safeAreaInsets.bottom)
            }
        }
        .themedBackground()
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await reload()
        }
        .task {
            await reload()
        }
        .navigationDestination(isPresented: Binding(get: { selectedHeroAnimeID != nil }, set: { if !$0 { selectedHeroAnimeID = nil } })) {
            if let selectedHeroAnimeID {
                TitleDetailsView(animeID: selectedHeroAnimeID)
            }
        }
    }

    private func loadingContent(metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
            VStack(alignment: .leading, spacing: theme.spacing.small) {
                LoadingSkeletonView(width: 144, height: 18, cornerRadius: 10)
                LoadingSkeletonView(width: 220, height: 14, cornerRadius: 8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: metrics.cardSpacing) {
                    ForEach(0..<3, id: \.self) { _ in
                        LoadingSkeletonView(height: metrics.continueCardHeight, cornerRadius: theme.radii.large)
                            .frame(width: metrics.continueCardWidth)
                    }
                }
            }

            LoadingSkeletonView(height: metrics.heroHeight, cornerRadius: theme.radii.hero)

            ForEach(0..<2, id: \.self) { _ in
                VStack(alignment: .leading, spacing: theme.spacing.small) {
                    LoadingSkeletonView(width: 180, height: 20, cornerRadius: 10)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: metrics.cardSpacing) {
                            ForEach(0..<4, id: \.self) { _ in
                                LoadingSkeletonView(width: metrics.posterWidth, height: metrics.posterWidth * 1.48, cornerRadius: theme.radii.poster)
                            }
                        }
                    }
                }
            }
        }
    }

    private func subtitle(for anime: Anime) -> String {
        guard let progress = viewModel.recentProgress[anime.id],
              let episode = MockCatalog.episode(for: progress.episodeID) else {
            return L10n.tr("Continue watching")
        }
        let remainingMinutes = max(Int((progress.durationSeconds - progress.positionSeconds) / 60), 1)
        return L10n.episodeMinutesLeft(episode.number, remainingMinutes)
    }

    private func playFirstEpisode(of anime: Anime) {
        let resumeEpisode = anime.seasons
            .flatMap(\.episodes)
            .first(where: { $0.id == viewModel.recentProgress[anime.id]?.episodeID })
        let episode = resumeEpisode ?? anime.seasons.first?.episodes.first
        if let episode {
            playbackCoordinator.startPlayback(anime: anime, episode: episode)
        }
    }

    private func reload() async {
        await viewModel.load(
            homeRepository: container.homeRepository,
            playbackRepository: container.playbackRepository
        )
    }

    private func orderedShelves(from shelves: [HomeShelf]) -> [HomeShelf] {
        shelves.sorted { lhs, rhs in
            rank(for: lhs) < rank(for: rhs)
        }
    }

    @ViewBuilder
    private func topHeader(metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
            Text("Tonight")
                .font(theme.typography.display)
                .foregroundStyle(theme.palette.textPrimary)

            Text("Premium picks, fresh episodes, and the fastest route back into your queue.")
                .font(theme.typography.subheadline)
                .foregroundStyle(theme.palette.textSecondary)
                .lineLimit(2)
        }
        .padding(.top, theme.spacing.xSmall)
    }

    private func continueShelf(from shelves: [HomeShelf]) -> HomeShelf? {
        shelves.first(where: { $0.style == .continueWatching })
    }

    @ViewBuilder
    private func shelfView(_ shelf: HomeShelf, metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.small) {
            SectionHeader(title: displayTitle(for: shelf), subtitle: shelf.subtitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: metrics.cardSpacing) {
                    ForEach(shelf.items) { anime in
                        if shelf.style == .continueWatching {
                            NavigationLink(value: AppRoute.anime(anime.id)) {
                                ContinueWatchingCard(
                                    anime: anime,
                                    progress: viewModel.recentProgress[anime.id]?.progress ?? 0.12,
                                    subtitle: subtitle(for: anime),
                                    width: metrics.continueCardWidth
                                )
                            }
                            .buttonStyle(.plain)
                        } else {
                            NavigationLink(value: AppRoute.anime(anime.id)) {
                                PosterCard(anime: anime, width: shelf.style == .wide ? metrics.widePosterWidth : metrics.posterWidth)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func displayTitle(for shelf: HomeShelf) -> String {
        let title = shelf.title.lowercased()
        if title.contains("top picks") {
            return "Featured Collection"
        }
        if title.contains("because") {
            return "Because You Watched"
        }
        return shelf.title
    }

    private func rank(for shelf: HomeShelf) -> Int {
        let title = shelf.title.lowercased()
        if shelf.style == .continueWatching { return 0 }
        if title.contains("new") { return 1 }
        if title.contains("trending") { return 2 }
        if title.contains("because") { return 3 }
        if title.contains("top picks") { return 4 }
        return 4
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview(device: "iPhone SE (3rd generation)", name: "Home · iPhone SE")
            preview(device: "iPhone 16 Pro", name: "Home · iPhone 16 Pro")
            preview(device: "iPhone 16 Pro Max", name: "Home · Pro Max")
        }
    }

    private static func preview(device: String, name: String) -> some View {
        NavigationStack {
            HomeView()
        }
        .environmentObject(AppContainer.live)
        .environmentObject(AppContainer.live.playbackCoordinator)
        .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
        .previewDevice(PreviewDevice(rawValue: device))
        .previewDisplayName(name)
    }
}
