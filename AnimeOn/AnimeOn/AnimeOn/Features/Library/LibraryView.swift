import Combine
import SwiftUI

@MainActor
final class LibraryViewModel: ObservableObject {
    enum DisplayMode {
        case grid
        case list
    }

    @Published private(set) var sections: [LibrarySection] = []
    @Published var selectedCategory: LibraryCategory = .continueWatching
    @Published var displayMode: DisplayMode = .grid
    @Published var isLoading = true

    func load(repository: any LibraryRepository) async {
        isLoading = true
        do {
            sections = try await repository.fetchLibrarySections()
        } catch {
            sections = []
        }
        isLoading = false
    }

    var selectedItems: [LibraryItem] {
        sections.first(where: { $0.category == selectedCategory })?.items ?? []
    }
}

struct LibraryView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var playbackCoordinator: PlaybackCoordinator
    @StateObject private var viewModel = LibraryViewModel()

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics.forWidth(proxy.size.width, theme: theme)
            let cardWidth = (metrics.width - (metrics.horizontalPadding * 2) - metrics.cardSpacing) / 2

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                    VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
                        Text("Library")
                            .font(theme.typography.display)
                            .foregroundStyle(theme.palette.textPrimary)
                        Text("Continue episodes, favorites, and offline picks without losing the premium flow.")
                            .font(theme.typography.subheadline)
                            .foregroundStyle(theme.palette.textSecondary)
                    }

                    GlassCard(padding: metrics.heroInset, cornerRadius: theme.radii.xLarge) {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.selectedCategory.title)
                                        .font(theme.typography.title)
                                        .foregroundStyle(theme.palette.textPrimary)
                                    Text(L10n.titlesInShelf(viewModel.selectedItems.count))
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.palette.textSecondary)
                                }
                                Spacer()
                                Button {
                                    viewModel.displayMode = viewModel.displayMode == .grid ? .list : .grid
                                } label: {
                                    Image(systemName: viewModel.displayMode == .grid ? "list.bullet" : "square.grid.2x2")
                                        .foregroundStyle(theme.palette.textPrimary)
                                        .frame(width: 36, height: 36)
                                        .background(theme.palette.secondaryCard, in: Circle())
                                }
                            }

                            categoryStrip
                        }
                    }
                    
                    if viewModel.isLoading {
                        VStack(spacing: 14) {
                            ForEach(0..<4, id: \.self) { _ in
                                LoadingSkeletonView(height: 150, cornerRadius: theme.radii.large)
                            }
                        }
                    } else if viewModel.selectedItems.isEmpty {
                        EmptyStateView(
                            title: "Nothing Here Yet",
                            message: "Curate favorites, continue episodes, and offline titles will gather right here.",
                            systemImage: "rectangle.stack.badge.plus"
                        )
                        .padding(.top, 10)
                    } else if viewModel.displayMode == .grid {
                        LazyVGrid(columns: metrics.gridColumns, spacing: 18) {
                            ForEach(viewModel.selectedItems) { item in
                                NavigationLink(value: AppRoute.anime(item.anime.id)) {
                                    libraryGridCard(item, width: cardWidth)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button("Resume") { play(item) }
                                    Button(L10n.removeFrom(viewModel.selectedCategory.title)) {
                                        remove(item)
                                    }
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.selectedItems) { item in
                                NavigationLink(value: AppRoute.anime(item.anime.id)) {
                                    libraryListRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, metrics.horizontalPadding)
                .padding(.top, theme.spacing.small)
                .padding(.bottom, 120 + proxy.safeAreaInsets.bottom)
            }
        }
        .themedBackground()
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.downloads) {
                    Image(systemName: "arrow.down.circle")
                }
            }
        }
        .task {
            await reload()
        }
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LibraryCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.selectedCategory = category
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: category.icon)
                            Text(category.title)
                        }
                        .font(theme.typography.subheadline)
                        .foregroundStyle(viewModel.selectedCategory == category ? theme.palette.textPrimary : theme.palette.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(viewModel.selectedCategory == category ? theme.palette.accentSoft : theme.palette.secondaryCard.opacity(0.66))
                        .overlay(
                            Capsule()
                                .stroke(viewModel.selectedCategory == category ? theme.palette.accent.opacity(0.2) : theme.palette.outline, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func libraryGridCard(_ item: LibraryItem, width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomLeading) {
                ArtworkView(title: item.anime.title, imageURL: item.anime.posterURL, cornerRadius: theme.radii.poster)
                    .frame(width: width, height: width * 1.46)

                if item.entry.progress > 0 {
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        Capsule(style: .continuous)
                            .fill(theme.palette.accent)
                            .frame(width: max((width - 24) * item.entry.progress, 14), height: 4)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.poster, style: .continuous)
                    .stroke(theme.palette.surfaceHighlight.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: theme.palette.shadow.opacity(0.58), radius: 16, x: 0, y: 10)

            Text(item.anime.title)
                .font(theme.typography.headline)
                .foregroundStyle(theme.palette.textPrimary)
                .lineLimit(2)

            HStack {
                Text(item.entry.isDownloaded ? L10n.tr("Offline ready") : progressLabel(for: item))
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.palette.textSecondary)
                Spacer()
                if item.entry.progress > 0 {
                    Button {
                        play(item)
                    } label: {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(theme.palette.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: width, alignment: .leading)
    }

    private func libraryListRow(_ item: LibraryItem) -> some View {
        GlassCard(padding: 14) {
            HStack(spacing: 12) {
                ArtworkView(title: item.anime.title, imageURL: item.anime.backdropURL, cornerRadius: theme.radii.medium, overlayOpacity: 0.34)
                    .frame(width: 118, height: 72)

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.anime.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.palette.textPrimary)
                        .lineLimit(2)
                    Text(progressLabel(for: item))
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                    ProgressView(value: max(item.entry.progress, 0.02))
                        .tint(theme.palette.accent)
                }

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        play(item)
                    } label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 34, height: 34)
                            .background(theme.palette.accent, in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button("Remove") { remove(item) }
                        .font(theme.typography.caption)
                        .foregroundStyle(.red.opacity(0.82))
                }
            }
        }
    }

    private func progressLabel(for item: LibraryItem) -> String {
        guard let episode = item.progress.flatMap({ MockCatalog.episode(for: $0.episodeID) }) else {
            return item.entry.isDownloaded ? L10n.tr("Downloaded") : L10n.tr("Ready to start")
        }
        return L10n.episodeWatched(episode.number, Int(item.entry.progress * 100))
    }

    private func play(_ item: LibraryItem) {
        let episodes = item.anime.seasons.flatMap(\.episodes)
        let episode = episodes.first(where: { $0.id == item.entry.lastEpisodeID }) ?? episodes.first
        if let episode {
            playbackCoordinator.startPlayback(anime: item.anime, episode: episode)
        }
    }

    private func remove(_ item: LibraryItem) {
        Task {
            try? await container.libraryRepository.updateCategory(viewModel.selectedCategory, animeID: item.anime.id, isIncluded: false)
            await reload()
        }
    }

    private func reload() async {
        await viewModel.load(repository: container.libraryRepository)
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .environmentObject(AppContainer.live)
    .environmentObject(AppContainer.live.playbackCoordinator)
    .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
}
