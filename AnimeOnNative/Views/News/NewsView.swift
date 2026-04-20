import SwiftUI

struct NewsView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel: NewsViewModel
    @Binding private var selectedSection: AppSection

    init(service: any AnimeServicing, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: NewsViewModel(service: service))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .news,
            title: "Новости и редакционные подборки",
            subtitle: AppSection.news.subtitle
        ) {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(message: "Загружаем новости...")

            case let .failed(message):
                MessageStateView(title: "Новости недоступны", message: message, actionTitle: "Повторить") {
                    Task { await viewModel.load() }
                }

            case let .empty(message):
                MessageStateView(title: "Новостей нет", message: message, actionTitle: nil, action: nil)

            case let .loaded(items):
                LazyVStack(spacing: 18) {
                    ForEach(items) { item in
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 18) {
                                newsImage(item, width: 220, height: 140)
                                newsCopy(item)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                newsImage(item, width: nil, height: 220)
                                newsCopy(item)
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(AppTheme.surface.opacity(0.96))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
    }

    private func newsImage(_ item: NewsItem, width: CGFloat?, height: CGFloat) -> some View {
        RemoteImageView(url: item.imageURL, pipeline: container.imagePipeline)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func newsCopy(_ item: NewsItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.tag.uppercased())
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AppTheme.accent)

            Text(item.title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(item.summary)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            Text(item.body)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
                .lineLimit(3)

            Text(item.publishedAt.formatted(date: .long, time: .omitted))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)
        }
    }
}
