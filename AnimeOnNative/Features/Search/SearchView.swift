import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel: SearchViewModel
    @Binding private var selectedSection: AppSection

    private let columns = [GridItem(.adaptive(minimum: 180, maximum: 240), spacing: 16)]

    init(repository: AnimeRepositoryProtocol, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: SearchViewModel(repository: repository))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .search,
            title: "Поиск",
            subtitle: AppSection.search.subtitle,
            onRefresh: {
                await viewModel.rerun()
            }
        ) {
            VStack(alignment: .leading, spacing: 20) {
                searchField

                if !viewModel.recentQueries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeaderView(title: "Recent queries", subtitle: "Продолжайте поиск с того же места")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(viewModel.recentQueries, id: \.self) { query in
                                    Button(query) {
                                        viewModel.useQuery(query)
                                    }
                                    .buttonStyle(.bordered)
                                    .tint(AppTheme.surfaceElevated)
                                }
                            }
                        }
                    }
                }

                switch viewModel.state {
                case .idle, .loading:
                    LoadingStateView(message: "Ищем по каталогу и локальному кэшу...")

                case let .failed(message):
                    MessageStateView(title: "Поиск недоступен", message: message, actionTitle: "Повторить") {
                        Task { await viewModel.rerun() }
                    }

                case let .empty(message):
                    MessageStateView(title: "Поиск", message: message, actionTitle: nil, action: nil)

                case let .loaded(results):
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(results) { anime in
                            NavigationLink(value: anime) {
                                AnimeCardView(anime: anime, pipeline: container.imagePipeline)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.textMuted)

            TextField("Название, жанр, оригинальный тайтл", text: $viewModel.query)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.textPrimary)

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
