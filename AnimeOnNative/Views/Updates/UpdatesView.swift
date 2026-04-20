import SwiftUI

struct UpdatesView: View {
    @StateObject private var viewModel: UpdatesViewModel
    @Binding private var selectedSection: AppSection

    init(service: any AnimeServicing, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: UpdatesViewModel(service: service))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .updates,
            title: "Лента обновлений",
            subtitle: AppSection.updates.subtitle
        ) {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(message: "Подтягиваем свежие эпизоды...")

            case let .failed(message):
                MessageStateView(title: "Обновления недоступны", message: message, actionTitle: "Повторить") {
                    Task { await viewModel.load() }
                }

            case let .empty(message):
                MessageStateView(title: "Пока без апдейтов", message: message, actionTitle: nil, action: nil)

            case let .loaded(items):
                VStack(spacing: 14) {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(item.animeTitle)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Spacer()

                                Text(item.publishedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppTheme.textMuted)
                            }

                            Text("Новая серия \(item.episodeNumber)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.accent)

                            Text(item.summary)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(AppTheme.surface.opacity(0.96))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
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
}
