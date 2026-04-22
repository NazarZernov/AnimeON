import Combine
import SwiftUI

@MainActor
final class TitleDetailsViewModel: ObservableObject {
    @Published private(set) var anime: Anime?
    @Published private(set) var relatedTitles: [Anime] = []
    @Published private(set) var libraryEntry: LibraryEntry?
    @Published private(set) var progressByEpisodeID: [String: PlaybackProgress] = [:]
    @Published var selectedSeasonID: String = ""
    @Published var isExpandedSynopsis = false
    @Published var isLoading = true

    func load(
        animeID: String,
        animeRepository: any AnimeRepository,
        libraryRepository: any LibraryRepository,
        playbackRepository: any PlaybackRepository
    ) async {
        isLoading = true
        do {
            async let animeValue = animeRepository.fetchAnime(id: animeID)
            async let relatedValue = animeRepository.fetchRelatedTitles(for: animeID)
            async let libraryValue = libraryRepository.fetchEntry(for: animeID)
            async let playbackValue = playbackRepository.fetchRecentProgress()

            let (anime, related, entry, playback) = try await (animeValue, relatedValue, libraryValue, playbackValue)
            self.anime = anime
            self.relatedTitles = related
            self.libraryEntry = entry
            self.selectedSeasonID = anime.seasons.first(where: \.isCurrent)?.id ?? anime.seasons.first?.id ?? ""
            self.progressByEpisodeID = Dictionary(uniqueKeysWithValues: playback.map { ($0.episodeID, $0) })
        } catch {
            anime = nil
            relatedTitles = []
            libraryEntry = nil
            progressByEpisodeID = [:]
        }
        isLoading = false
    }

    var selectedSeason: AnimeSeason? {
        anime?.seasons.first(where: { $0.id == selectedSeasonID })
    }

    func nextEpisodeToPlay() -> Episode? {
        guard let anime else { return nil }
        if let lastEpisodeID = libraryEntry?.lastEpisodeID,
           let episode = anime.seasons.flatMap(\.episodes).first(where: { $0.id == lastEpisodeID }) {
            return episode
        }
        return anime.seasons.first?.episodes.first
    }
}

struct TitleDetailsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var playbackCoordinator: PlaybackCoordinator
    @EnvironmentObject private var downloadManager: DownloadManager

    let animeID: String

    @StateObject private var viewModel = TitleDetailsViewModel()
    @State private var showListDialog = false
    @State private var showDownloadDialog = false

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics.forWidth(proxy.size.width, theme: theme)

            ScrollView(.vertical, showsIndicators: false) {
                if let anime = viewModel.anime {
                    VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                        header(anime: anime, metrics: metrics)
                        actionRow(anime: anime, metrics: metrics)
                        synopsisSection(anime: anime, metrics: metrics)
                        metadataSection(anime: anime, metrics: metrics)
                        seasonSection(metrics: metrics)
                        if !viewModel.relatedTitles.isEmpty {
                            relatedSection(metrics: metrics)
                        }
                    }
                    .padding(.bottom, 120 + proxy.safeAreaInsets.bottom)
                } else if viewModel.isLoading {
                    VStack(spacing: metrics.compactSectionSpacing) {
                        LoadingSkeletonView(height: metrics.detailsBackdropHeight, cornerRadius: theme.radii.hero)
                            .padding(.horizontal, metrics.horizontalPadding)
                            .padding(.top, theme.spacing.small)
                        LoadingSkeletonView(height: 156, cornerRadius: theme.radii.large)
                            .padding(.horizontal, metrics.horizontalPadding)
                        LoadingSkeletonView(height: 220, cornerRadius: theme.radii.large)
                            .padding(.horizontal, metrics.horizontalPadding)
                    }
                } else {
                    EmptyStateView(
                        title: "Title Unavailable",
                        message: "The selected series could not be opened from the current data source.",
                        systemImage: "exclamationmark.triangle",
                        actionTitle: "Retry"
                    ) {
                        Task { await reload() }
                    }
                    .padding(.horizontal, metrics.horizontalPadding)
                    .padding(.top, 80)
                }
            }
        }
        .themedBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.downloads) {
                    Image(systemName: "arrow.down.circle")
                }
            }
        }
        .task {
            await reload()
        }
        .confirmationDialog("Add to List", isPresented: $showListDialog) {
            if let anime = viewModel.anime {
                Button("Favorites") { update(category: .favorites, animeID: anime.id, include: true) }
                Button("Watch Later") { update(category: .planned, animeID: anime.id, include: true) }
                Button("Watching") { update(category: .watching, animeID: anime.id, include: true) }
            }
        } message: {
            Text("Choose where this title should live in your library.")
        }
        .confirmationDialog("Download Quality", isPresented: $showDownloadDialog) {
            ForEach(DownloadQualityPreference.allCases) { quality in
                Button(quality.title) {
                    if let anime = viewModel.anime,
                       let episode = viewModel.nextEpisodeToPlay() {
                        downloadManager.enqueue(anime: anime, episode: episode, quality: quality)
                    }
                }
            }
        } message: {
            Text("Select a preset for the next episode download.")
        }
    }

    @ViewBuilder
    private func header(anime: Anime, metrics: LayoutMetrics) -> some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                ArtworkView(
                    title: anime.title,
                    imageURL: anime.backdropURL,
                    cornerRadius: theme.radii.hero,
                    overlayOpacity: 0.16
                )
                .frame(height: metrics.detailsBackdropHeight)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.14), .black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.hero, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    MetadataPill("Now Streaming", icon: "tv.fill", highlighted: true)
                    if !anime.tags.isEmpty {
                        Text(anime.tags.prefix(2).joined(separator: " • "))
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(metrics.heroInset)
            }
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.hero, style: .continuous)
                    .stroke(theme.palette.surfaceHighlight.opacity(0.7), lineWidth: 1)
            )
            .padding(.horizontal, metrics.horizontalPadding)
            .padding(.top, theme.spacing.small)

            GlassCard(padding: metrics.heroInset, cornerRadius: theme.radii.xLarge) {
                HStack(alignment: .top, spacing: 14) {
                    ArtworkView(title: anime.title, imageURL: anime.posterURL, cornerRadius: theme.radii.poster)
                        .frame(width: metrics.detailsPosterWidth, height: metrics.detailsPosterHeight)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radii.poster, style: .continuous)
                                .stroke(theme.palette.surfaceHighlight.opacity(0.7), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 10) {
                        Text(anime.title)
                            .font(metrics.isNarrowPhone ? theme.typography.title : theme.typography.hero)
                            .foregroundStyle(theme.palette.textPrimary)
                            .lineLimit(3)

                        Text(anime.originalTitle)
                            .font(theme.typography.subheadline)
                            .foregroundStyle(theme.palette.textSecondary)
                            .lineLimit(1)

                        HStack(spacing: 6) {
                            MetadataPill(String(format: "%.1f", anime.averageRating), icon: "star.fill", highlighted: true)
                            MetadataPill("\(anime.year)")
                            MetadataPill(anime.format.title)
                            MetadataPill(anime.ageRating)
                        }

                        Text(L10n.episodeCountStatusStudio(anime.episodeCount, anime.status.title, anime.studio))
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            ForEach(anime.genres.prefix(3)) { genre in
                                MetadataPill(genre.title)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, metrics.horizontalPadding)
            .offset(y: -metrics.detailsPanelOverlap)
            .padding(.bottom, -metrics.detailsPanelOverlap)
        }
    }

    @ViewBuilder
    private func actionRow(anime: Anime, metrics: LayoutMetrics) -> some View {
        VStack(spacing: metrics.rowSpacing) {
            GradientButton(
                viewModel.libraryEntry?.progress ?? 0 > 0 ? "Continue Watching" : "Watch Now",
                systemImage: "play.fill",
                size: .regular
            ) {
                if let episode = viewModel.nextEpisodeToPlay() {
                    playbackCoordinator.startPlayback(anime: anime, episode: episode)
                }
            }

            HStack(spacing: metrics.cardSpacing) {
                Button {
                    showListDialog = true
                } label: {
                    secondaryActionLabel(title: "Add to List", systemImage: "plus")
                }
                .buttonStyle(.plain)

                Button {
                    showDownloadDialog = true
                } label: {
                    secondaryActionLabel(title: "Download", systemImage: "arrow.down.to.line")
                }
                .buttonStyle(.plain)

                ShareLink(
                    item: URL(string: "https://animeon.local/anime/\(anime.id)")!,
                    preview: SharePreview(anime.title)
                ) {
                    secondaryActionLabel(title: "Share", systemImage: "square.and.arrow.up")
                }
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
    }

    @ViewBuilder
    private func synopsisSection(anime: Anime, metrics: LayoutMetrics) -> some View {
        SettingsSectionContainer(title: "Synopsis", subtitle: "Story, tone, and emotional register") {
            Text(anime.synopsis)
                .font(theme.typography.body)
                .foregroundStyle(theme.palette.textSecondary)
                .lineSpacing(3)
                .lineLimit(viewModel.isExpandedSynopsis ? nil : 5)

            Button(viewModel.isExpandedSynopsis ? L10n.tr("Show Less") : L10n.tr("Read More")) {
                withAnimation(.easeInOut(duration: 0.24)) {
                    viewModel.isExpandedSynopsis.toggle()
                }
            }
            .font(theme.typography.control)
            .foregroundStyle(theme.palette.accent)
        }
        .padding(.horizontal, metrics.horizontalPadding)
    }

    @ViewBuilder
    private func metadataSection(anime: Anime, metrics: LayoutMetrics) -> some View {
        SettingsSectionContainer(title: "Details", subtitle: "Release info, production, and tags") {
            LazyVGrid(columns: metrics.metadataColumns, spacing: 12) {
                metadataBlock(title: "Studio", value: anime.studio)
                metadataBlock(title: "Age Rating", value: anime.ageRating)
                metadataBlock(title: "Status", value: anime.status.title)
                metadataBlock(title: "Format", value: anime.format.title)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(anime.genres) { genre in
                        MetadataPill(genre.title)
                    }
                    ForEach(anime.tags, id: \.self) { tag in
                        MetadataPill(tag, icon: "sparkles")
                    }
                }
            }
        }
        .padding(.horizontal, metrics.horizontalPadding)
    }

    private func seasonSection(metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            SectionHeader(title: "Episodes", subtitle: "Seasons, progress, and offline availability")
                .padding(.horizontal, metrics.horizontalPadding)

            if let anime = viewModel.anime {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(anime.seasons) { season in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedSeasonID = season.id
                                }
                            } label: {
                                Text(season.title.localized)
                                    .font(theme.typography.control)
                                    .foregroundStyle(viewModel.selectedSeasonID == season.id ? theme.palette.textPrimary : theme.palette.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(viewModel.selectedSeasonID == season.id ? theme.palette.accentSoft : theme.palette.secondaryCard.opacity(0.7))
                                    .overlay(
                                        Capsule(style: .continuous)
                                            .stroke(viewModel.selectedSeasonID == season.id ? theme.palette.accent.opacity(0.22) : theme.palette.outline, lineWidth: 1)
                                    )
                                    .clipShape(Capsule(style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, metrics.horizontalPadding)
            }

            VStack(spacing: metrics.rowSpacing) {
                ForEach(viewModel.selectedSeason?.episodes ?? []) { episode in
                    EpisodeTile(
                        episode: episode,
                        progress: viewModel.progressByEpisodeID[episode.id]?.progress ?? 0,
                        isDownloaded: downloadManager.asset(for: episode.id) != nil,
                        artworkWidth: metrics.episodeArtworkWidth,
                        artworkHeight: metrics.episodeArtworkHeight
                    ) {
                        if let anime = viewModel.anime {
                            playbackCoordinator.startPlayback(anime: anime, episode: episode)
                        }
                    }
                }
            }
            .padding(.horizontal, metrics.horizontalPadding)
        }
    }

    private func relatedSection(metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: theme.spacing.medium) {
            SectionHeader(title: "Related Titles", subtitle: "More from the same emotional neighborhood")
                .padding(.horizontal, metrics.horizontalPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: metrics.cardSpacing) {
                    ForEach(viewModel.relatedTitles) { anime in
                        NavigationLink(value: AppRoute.anime(anime.id)) {
                            PosterCard(anime: anime, width: metrics.posterWidth)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, metrics.horizontalPadding)
            }
        }
    }

    private func metadataBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.localized)
                .font(theme.typography.caption)
                .foregroundStyle(theme.palette.textTertiary)
            Text(value)
                .font(theme.typography.headline)
                .foregroundStyle(theme.palette.textPrimary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(theme.palette.secondaryCard.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                .stroke(theme.palette.outline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous))
    }

    private func secondaryActionLabel(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(title.localized)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(theme.typography.caption)
        .foregroundStyle(theme.palette.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 42)
        .background(theme.palette.secondaryCard.opacity(0.92), in: RoundedRectangle(cornerRadius: theme.radii.control, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.control, style: .continuous)
                .stroke(theme.palette.outline, lineWidth: 1)
        )
    }

    private func update(category: LibraryCategory, animeID: String, include: Bool) {
        Task {
            try? await container.libraryRepository.updateCategory(category, animeID: animeID, isIncluded: include)
            await reload()
        }
    }

    private func reload() async {
        await viewModel.load(
            animeID: animeID,
            animeRepository: container.animeRepository,
            libraryRepository: container.libraryRepository,
            playbackRepository: container.playbackRepository
        )
    }
}

struct TitleDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview(device: "iPhone SE (3rd generation)", name: "Details · iPhone SE")
            preview(device: "iPhone 16 Pro", name: "Details · iPhone 16 Pro")
            preview(device: "iPhone 16 Pro Max", name: "Details · Pro Max")
        }
    }

    private static func preview(device: String, name: String) -> some View {
        NavigationStack {
            TitleDetailsView(animeID: MockCatalog.titles[0].id)
        }
        .environmentObject(AppContainer.live)
        .environmentObject(AppContainer.live.playbackCoordinator)
        .environmentObject(AppContainer.live.downloadManager)
        .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
        .previewDevice(PreviewDevice(rawValue: device))
        .previewDisplayName(name)
    }
}
