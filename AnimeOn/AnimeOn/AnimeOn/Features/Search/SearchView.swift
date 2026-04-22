import Combine
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var filters = AnimeSearchFilters.default
    @Published private(set) var discovery: SearchDiscoveryContent?
    @Published private(set) var results: [Anime] = []
    @Published private(set) var isLoading = false
    @Published var isShowingFilters = false

    func loadDiscovery(using repository: any SearchRepository) async {
        discovery = try? await repository.fetchDiscovery()
    }

    func performSearch(using repository: any SearchRepository) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || filters.isActive else {
            results = []
            isLoading = false
            return
        }
        isLoading = true
        do {
            results = try await repository.search(query: query, filters: filters)
        } catch {
            results = []
        }
        isLoading = false
    }
}

struct SearchView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel = SearchViewModel()

    var body: some View {
        GeometryReader { proxy in
            let metrics = LayoutMetrics.forWidth(proxy.size.width, theme: theme)
            let posterWidth = (metrics.width - (metrics.horizontalPadding * 2) - metrics.cardSpacing) / 2
            let showingResults = !viewModel.query.isEmpty || viewModel.filters.isActive

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: metrics.sectionSpacing) {
                    VStack(alignment: .leading, spacing: theme.spacing.xSmall) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(viewModel.query.isEmpty ? L10n.tr("Discover") : L10n.tr("Results"))
                                .font(theme.typography.display)
                                .foregroundStyle(theme.palette.textPrimary)
                            Spacer()
                            Button {
                                viewModel.isShowingFilters = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                    Text(viewModel.filters.isActive ? L10n.tr("Filtered") : L10n.tr("Filters"))
                                }
                                .font(theme.typography.subheadline)
                                .foregroundStyle(theme.palette.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(theme.palette.secondaryCard.opacity(0.84), in: Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(theme.palette.outline, lineWidth: 1)
                                )
                            }
                        }

                        Text(
                            viewModel.query.isEmpty
                                ? L10n.tr("Find by title, studio, genre, or late-night mood.")
                                : L10n.tr("Matching titles from the mock catalog.")
                        )
                            .font(theme.typography.subheadline)
                            .foregroundStyle(theme.palette.textSecondary)
                    }

                    if !showingResults {
                        discoveryContent(metrics: metrics, posterWidth: posterWidth)
                    } else if viewModel.isLoading {
                        LazyVGrid(columns: metrics.gridColumns, spacing: 18) {
                            ForEach(0..<4, id: \.self) { _ in
                                LoadingSkeletonView(height: posterWidth * 1.62, cornerRadius: theme.radii.poster)
                            }
                        }
                    } else if viewModel.results.isEmpty {
                        EmptyStateView(
                            title: "No Matches",
                            message: "Try a broader title, a different year, or fewer filters.",
                            systemImage: "sparkle.magnifyingglass"
                        )
                        .padding(.top, 40)
                    } else {
                        LazyVGrid(columns: metrics.gridColumns, spacing: 18) {
                            ForEach(viewModel.results) { anime in
                                NavigationLink(value: AppRoute.anime(anime.id)) {
                                    PosterCard(anime: anime, width: posterWidth)
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
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Titles, genres, studios")
        .task {
            await viewModel.loadDiscovery(using: container.searchRepository)
        }
        .onChange(of: viewModel.query) { _, newValue in
            if !newValue.isEmpty {
                container.recentSearchStore.save(newValue)
            }
            Task {
                await viewModel.performSearch(using: container.searchRepository)
            }
        }
        .onChange(of: viewModel.filters) { _, _ in
            Task {
                await viewModel.performSearch(using: container.searchRepository)
            }
        }
        .sheet(isPresented: $viewModel.isShowingFilters) {
            SearchFiltersView(filters: $viewModel.filters)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func discoveryContent(metrics: LayoutMetrics, posterWidth: CGFloat) -> some View {
        if let discovery = viewModel.discovery {
            VStack(alignment: .leading, spacing: theme.spacing.large) {
                GlassCard(padding: metrics.heroInset, cornerRadius: theme.radii.xLarge) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Search by mood")
                            .font(theme.typography.title)
                            .foregroundStyle(theme.palette.textPrimary)
                        Text("Explore high-concept sci-fi, intimate dramas, late-night romance, or anything in between.")
                            .font(theme.typography.body)
                            .foregroundStyle(theme.palette.textSecondary)
                    }
                }

                if !container.recentSearchStore.items.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: "Recent Searches")
                        chipGrid(container.recentSearchStore.items) { query in
                            chip(query) { viewModel.query = query }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Trending Searches")
                    chipGrid(discovery.trendingQueries) { query in
                        chip(query) { viewModel.query = query }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Genre Picks")
                    chipGrid(discovery.featuredGenres) { genre in
                        chip(genre.title) {
                            viewModel.filters.genre = genre
                            viewModel.query = ""
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader(title: "Spotlight")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: metrics.cardSpacing) {
                            ForEach(discovery.spotlightTitles) { anime in
                                NavigationLink(value: AppRoute.anime(anime.id)) {
                                    PosterCard(anime: anime, width: posterWidth * 0.9)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func chip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(theme.typography.subheadline)
                .foregroundStyle(theme.palette.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(theme.palette.secondaryCard.opacity(0.82), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(theme.palette.outline, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func chipGrid<Item: Hashable, Label: View>(
        _ items: [Item],
        @ViewBuilder label: @escaping (Item) -> Label
    ) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10, alignment: .leading)], alignment: .leading, spacing: 10) {
            ForEach(items, id: \.self) { item in
                label(item)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                }
        }
    }
}

struct SearchFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Binding var filters: AnimeSearchFilters

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    SettingsSectionContainer(title: "Catalog Filters", subtitle: "Refine discovery across the mock catalog") {
                        Picker("Genre", selection: $filters.genre) {
                            Text("Any").tag(AnimeGenre?.none)
                            ForEach(AnimeGenre.allCases) { genre in
                                Text(genre.title).tag(AnimeGenre?.some(genre))
                            }
                        }

                        Picker("Status", selection: $filters.status) {
                            Text("Any").tag(AnimeStatus?.none)
                            ForEach(AnimeStatus.allCases, id: \.self) { status in
                                Text(status.title).tag(AnimeStatus?.some(status))
                            }
                        }

                        Picker("Type", selection: $filters.type) {
                            Text("Any").tag(AnimeFormat?.none)
                            ForEach(AnimeFormat.allCases, id: \.self) { type in
                                Text(type.title).tag(AnimeFormat?.some(type))
                            }
                        }

                        Picker("Year", selection: $filters.year) {
                            Text("Any").tag(Int?.none)
                            ForEach([2026, 2025, 2024, 2023], id: \.self) { year in
                                Text(String(year)).tag(Int?.some(year))
                            }
                        }

                        Toggle("Dub Available", isOn: Binding(
                            get: { filters.supportsDub ?? false },
                            set: { filters.supportsDub = $0 ? true : nil }
                        ))

                        Toggle("Subtitles Available", isOn: Binding(
                            get: { filters.supportsSubtitles ?? false },
                            set: { filters.supportsSubtitles = $0 ? true : nil }
                        ))
                    }
                }
                .padding(theme.spacing.large)
            }
            .themedBackground()
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") { filters = .default }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
    .environmentObject(AppContainer.live)
    .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
}
