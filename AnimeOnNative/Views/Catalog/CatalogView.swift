import SwiftUI

struct CatalogView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel: CatalogViewModel
    @Binding private var selectedSection: AppSection

    private let columns = [GridItem(.adaptive(minimum: 170, maximum: 230), spacing: 16)]
    private var availableYears: [Int] {
        Array((CatalogFilters.minimumYear...CatalogFilters.currentYear).reversed())
    }

    init(repository: AnimeRepositoryProtocol, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: CatalogViewModel(repository: repository))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .catalog,
            title: "Каталог аниме",
            subtitle: AppSection.catalog.subtitle,
            onRefresh: {
                await viewModel.load(refresh: true)
            }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                filterPanel

                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView(message: "Загружаем каталог и фильтры...")

                case let .failed(message):
                    MessageStateView(title: "Каталог недоступен", message: message, actionTitle: "Повторить") {
                        Task { await viewModel.load() }
                    }

                case let .empty(message):
                    MessageStateView(title: "Ничего не найдено", message: message, actionTitle: "Сбросить фильтры") {
                        viewModel.filters = CatalogFilters()
                        Task { await viewModel.reloadForChangedFilters() }
                    }

                case .loaded:
                    catalogSummary

                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(viewModel.items) { anime in
                            NavigationLink(value: anime) {
                                AnimeCardView(anime: anime, pipeline: container.imagePipeline)
                            }
                            .buttonStyle(.plain)
                            .task {
                                await viewModel.loadNextPageIfNeeded(currentItem: anime)
                            }
                        }
                    }

                    if viewModel.isLoadingNextPage {
                        LoadingStateView(message: "Подгружаем следующую страницу...")
                    }
                }
            }
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
        .animation(.snappy, value: viewModel.items)
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    searchField
                    sortMenu
                }

                VStack(alignment: .leading, spacing: 12) {
                    searchField
                    sortMenu
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    quickPresetButton(
                        title: "Топ сезона",
                        isActive: viewModel.filters.status == .ongoing && viewModel.filters.yearRange.lowerBound >= CatalogFilters.currentYear - 1
                    ) {
                        viewModel.filters.status = .ongoing
                        viewModel.filters.sort = .popular
                        viewModel.filters.yearRange = max(CatalogFilters.minimumYear, CatalogFilters.currentYear - 1)...CatalogFilters.currentYear
                        viewModel.filters.minimumRating = 0
                        Task { await viewModel.reloadForChangedFilters() }
                    }

                    quickPresetButton(title: "Популярные", isActive: viewModel.filters.sort == .popular && viewModel.filters.status == nil) {
                        viewModel.filters.sort = .popular
                        viewModel.filters.status = nil
                        viewModel.filters.minimumRating = 0
                        Task { await viewModel.reloadForChangedFilters() }
                    }

                    quickPresetButton(title: "Top 100", isActive: viewModel.filters.sort == .rating && viewModel.filters.minimumRating >= 8.5) {
                        viewModel.filters.sort = .rating
                        viewModel.filters.minimumRating = 8.5
                        Task { await viewModel.reloadForChangedFilters() }
                    }

                    quickPresetButton(title: "Новые серии", isActive: viewModel.filters.sort == .recentlyUpdated) {
                        viewModel.filters.sort = .recentlyUpdated
                        viewModel.filters.status = .ongoing
                        Task { await viewModel.reloadForChangedFilters() }
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    Menu {
                        Button("Все типы") {
                            viewModel.filters.type = nil
                            Task { await viewModel.reloadForChangedFilters() }
                        }

                        ForEach(AnimeType.allCases) { type in
                            Button(type.localizedTitle) {
                                viewModel.filters.type = type
                                Task { await viewModel.reloadForChangedFilters() }
                            }
                        }
                    } label: {
                        filterCapsule(title: "Тип", value: viewModel.filters.type?.localizedTitle ?? "Все")
                    }

                    Menu {
                        Button("Любой статус") {
                            viewModel.filters.status = nil
                            Task { await viewModel.reloadForChangedFilters() }
                        }

                        ForEach(AnimeStatus.allCases) { status in
                            Button(status.localizedTitle) {
                                viewModel.filters.status = status
                                Task { await viewModel.reloadForChangedFilters() }
                            }
                        }
                    } label: {
                        filterCapsule(title: "Статус", value: viewModel.filters.status?.localizedTitle ?? "Любой")
                    }

                    Menu {
                        ForEach(availableYears, id: \.self) { year in
                            Button("От \(year)") {
                                let upperBound = max(year, viewModel.filters.yearRange.upperBound)
                                viewModel.filters.yearRange = year...upperBound
                                Task { await viewModel.reloadForChangedFilters() }
                            }
                        }
                    } label: {
                        filterCapsule(title: "Год от", value: "\(viewModel.filters.yearRange.lowerBound)")
                    }

                    Menu {
                        ForEach(availableYears, id: \.self) { year in
                            Button("До \(year)") {
                                let lowerBound = min(year, viewModel.filters.yearRange.lowerBound)
                                viewModel.filters.yearRange = lowerBound...year
                                Task { await viewModel.reloadForChangedFilters() }
                            }
                        }
                    } label: {
                        filterCapsule(title: "Год до", value: "\(viewModel.filters.yearRange.upperBound)")
                    }

                    Menu {
                        ForEach([0.0, 6.0, 7.0, 8.0, 9.0], id: \.self) { rating in
                            Button("От \(rating.formatted())") {
                                viewModel.filters.minimumRating = rating
                                Task { await viewModel.reloadForChangedFilters() }
                            }
                        }
                    } label: {
                        filterCapsule(title: "Рейтинг", value: "от \(viewModel.filters.minimumRating.formatted())")
                    }

                    Button {
                        viewModel.filters = CatalogFilters()
                        Task { await viewModel.reloadForChangedFilters() }
                    } label: {
                        filterCapsule(title: "Фильтры", value: "Сбросить")
                    }
                    .buttonStyle(.plain)

                    ForEach(viewModel.availableGenres.prefix(10), id: \.self) { genre in
                        Button {
                            if viewModel.filters.genres.contains(genre) {
                                viewModel.filters.genres.remove(genre)
                            } else {
                                viewModel.filters.genres.insert(genre)
                            }
                            Task { await viewModel.reloadForChangedFilters() }
                        } label: {
                            Text(genre)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(viewModel.filters.genres.contains(genre) ? .white : AppTheme.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(viewModel.filters.genres.contains(genre) ? AppTheme.accent : AppTheme.surface.opacity(0.96))
                                )
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(viewModel.filters.genres.contains(genre) ? AppTheme.accent : AppTheme.surfaceBorder, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textMuted)
            TextField("Поиск по названию или оригинальному тайтлу", text: $viewModel.filters.searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.textPrimary)
                .onChange(of: viewModel.filters.searchText) { _, _ in
                    viewModel.scheduleSearchRefresh()
                }
                .onSubmit { Task { await viewModel.reloadForChangedFilters() } }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private var sortMenu: some View {
        Menu {
            ForEach(CatalogSort.allCases) { sort in
                Button(sort.localizedTitle) {
                    viewModel.filters.sort = sort
                    Task { await viewModel.reloadForChangedFilters() }
                }
            }
        } label: {
            filterCapsule(title: "Сортировка", value: viewModel.filters.sort.localizedTitle)
        }
    }

    private func filterCapsule(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private var catalogSummary: some View {
        HStack(spacing: 12) {
            Label("\(viewModel.totalCount) тайтлов", systemImage: "film.stack.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Label("Страница \(viewModel.currentPage)", systemImage: "rectangle.grid.1x2.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer()

            Text(viewModel.filters.yearSummary)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.accent)

            if viewModel.hasNextPage {
                Text("Infinite feed")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.success)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private func quickPresetButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isActive ? .white : AppTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(isActive ? AppTheme.accent : AppTheme.surface.opacity(0.96))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(isActive ? AppTheme.accent : AppTheme.surfaceBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
