import SwiftUI

struct RandomView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel: RandomViewModel
    @Binding private var selectedSection: AppSection

    init(service: any AnimeServicing, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: RandomViewModel(service: service))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .random,
            title: "Случайный тайтл",
            subtitle: AppSection.random.subtitle
        ) {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(message: "Крутим рулетку аниме...")

            case let .failed(message):
                MessageStateView(title: "Не удалось выбрать тайтл", message: message, actionTitle: "Ещё раз") {
                    Task { await viewModel.loadRandom() }
                }

            case .empty:
                MessageStateView(title: "Каталог пуст", message: "Добавьте данные в mock JSON или подключите backend.", actionTitle: nil, action: nil)

            case let .loaded(anime):
                VStack(alignment: .leading, spacing: 20) {
                    NavigationLink(value: anime) {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 20) {
                                randomPoster(anime, width: 260, height: 360)
                                randomContent(anime)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 20) {
                                randomPoster(anime, width: nil, height: 420)
                                randomContent(anime)
                            }
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(AppTheme.surface.opacity(0.96))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.loadRandom()
            }
        }
    }

    private func randomPill(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Capsule(style: .continuous).fill(AppTheme.surfaceElevated))
    }

    private func randomPoster(_ anime: Anime, width: CGFloat?, height: CGFloat) -> some View {
        RemoteImageView(url: anime.posterURL, pipeline: container.imagePipeline)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private func randomContent(_ anime: Anime) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(anime.title)
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            Text(anime.synopsis)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    randomPill(String(format: "%.1f", anime.rating))
                    randomPill("\(anime.year)")
                    randomPill(anime.type.localizedTitle)
                }
            }

            Button {
                Task { await viewModel.loadRandom() }
            } label: {
                Label("Выбрать ещё", systemImage: "dice.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
    }
}
