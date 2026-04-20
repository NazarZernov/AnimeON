import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel: HomeViewModel
    @Binding private var selectedSection: AppSection

    init(repository: AnimeRepositoryProtocol, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(repository: repository))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .home,
            title: "AnimeOn для Apple-платформ",
            subtitle: AppSection.home.subtitle,
            onRefresh: {
                await viewModel.load(refresh: true)
            }
        ) {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(message: "Собираем главную витрину, новости и релизы...")

            case let .failed(message):
                MessageStateView(title: "Не удалось загрузить Home", message: message, actionTitle: "Повторить") {
                    Task { await viewModel.load(refresh: true) }
                }

            case let .empty(message):
                MessageStateView(title: "Пусто", message: message, actionTitle: "Обновить") {
                    Task { await viewModel.load(refresh: true) }
                }

            case let .loaded(dashboard):
                VStack(alignment: .leading, spacing: 28) {
                    heroCard(dashboard: dashboard)
                    rail(title: "Popular ongoing", subtitle: "Главные онгоинги недели", items: dashboard.heroFeed.popularOngoing)
                    rail(title: "Recent episodes", subtitle: "Новые серии, готовые к стримингу и офлайну", items: dashboard.heroFeed.newEpisodes)
                    rail(title: "Top 100", subtitle: "Рейтинг, который ближе всего к сервисной витрине", items: dashboard.heroFeed.topHundred)
                    if !dashboard.updates.isEmpty {
                        updatesSection(dashboard.updates)
                    }
                    if !dashboard.news.isEmpty {
                        newsSection(dashboard.news)
                    }
                    if !dashboard.schedule.isEmpty {
                        schedulePreview(dashboard.schedule)
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

    private func heroCard(dashboard: HomeDashboard) -> some View {
        let featured = dashboard.heroFeed.featured

        return ZStack(alignment: .bottomLeading) {
            RemoteImageView(url: featured.bannerURL, pipeline: container.imagePipeline, contentMode: .fill)
                .frame(height: 360)
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.86)],
                startPoint: .center,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    heroPill(text: String(format: "%.1f", featured.rating), color: AppTheme.warning)
                    heroPill(text: featured.status.localizedTitle, color: AppTheme.success)
                    heroPill(text: "\(featured.year)", color: AppTheme.info)
                }

                Text(featured.title)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(featured.extendedSynopsis)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(3)
                    .frame(maxWidth: 760, alignment: .leading)

                HStack(spacing: 12) {
                    NavigationLink(value: featured) {
                        Label("Открыть тайтл", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)

                    NavigationLink(value: dashboard.randomPick) {
                        Label("Случайный выбор", systemImage: "shuffle")
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.info)
                }
            }
            .padding(28)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private func rail(title: String, subtitle: String, items: [Anime]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: title, subtitle: subtitle)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { anime in
                        NavigationLink(value: anime) {
                            AnimeCardView(anime: anime, pipeline: container.imagePipeline)
                                .frame(width: 220)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func updatesSection(_ updates: [UpdateItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Обновления", subtitle: "Последние эпизоды и апдейты каталога")

            VStack(spacing: 12) {
                ForEach(updates.prefix(4)) { item in
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.animeTitle)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Эпизод \(item.episodeNumber) • \(item.summary)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()

                        Text(item.publishedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .padding(18)
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
        }
    }

    private func newsSection(_ news: [NewsItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Новости", subtitle: "Редакционные заметки и витрина релизов")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(news.prefix(5)) { item in
                        VStack(alignment: .leading, spacing: 12) {
                            RemoteImageView(url: item.imageURL, pipeline: container.imagePipeline)
                                .frame(width: 300, height: 170)
                                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                            Text(item.tag.uppercased())
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(AppTheme.accent)

                            Text(item.title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(item.summary)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                                .lineLimit(3)
                        }
                        .frame(width: 300, alignment: .leading)
                        .padding(16)
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
    }

    private func schedulePreview(_ days: [ScheduleDay]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Ближайшие релизы", subtitle: "Расписание прямо с домашнего экрана")

            ForEach(days.prefix(2)) { day in
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(day.shortWeekday), \(day.shortDateLabel)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    ForEach(day.releases.prefix(3)) { release in
                        HStack {
                            Text(release.releaseTime)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.accent)

                            Text(release.animeTitle)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Spacer()

                            Text("EP \(release.episodeNumber)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(20)
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

    private func heroPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(color))
    }
}
