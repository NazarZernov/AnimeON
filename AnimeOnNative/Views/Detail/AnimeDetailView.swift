import SwiftUI

struct AnimeDetailView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel: AnimeDetailViewModel
    @Binding private var selectedSection: AppSection

    init(anime: Anime, repository: AnimeRepositoryProtocol, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: AnimeDetailViewModel(anime: anime, repository: repository))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .catalog,
            title: viewModel.anime.title,
            subtitle: "Карточка тайтла, офлайн, watchlist, рейтинг и стриминговый player flow",
            onRefresh: {
                await viewModel.load(refresh: true)
            }
        ) {
            VStack(alignment: .leading, spacing: 24) {
                header
                aboutSection
                episodesSection
            }
        }
        .task {
            if case .idle = viewModel.episodesState {
                await viewModel.load()
            }
        }
        .overlay(alignment: .bottom) {
            if let toastMessage = viewModel.toastMessage {
                Text(toastMessage)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Capsule(style: .continuous).fill(AppTheme.accent))
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: viewModel.toastMessage)
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 20) {
                detailPoster(width: 250, height: 360)
                detailContent(buttonAxis: .horizontal)
            }

            VStack(alignment: .leading, spacing: 20) {
                detailPoster(width: nil, height: 420)
                detailContent(buttonAxis: .vertical)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Описание", subtitle: "\(viewModel.anime.originalTitle) • \(viewModel.anime.studio)")
            Text(viewModel.anime.extendedSynopsis)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
    }

    private func detailPoster(width: CGFloat?, height: CGFloat) -> some View {
        RemoteImageView(url: viewModel.anime.posterURL, pipeline: container.imagePipeline)
            .frame(maxWidth: width == nil ? .infinity : width, maxHeight: height)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func detailContent(buttonAxis: Axis) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    headerPill(text: String(format: "%.1f", viewModel.anime.rating), color: AppTheme.warning)
                    headerPill(text: "\(viewModel.anime.year)", color: AppTheme.info)
                    headerPill(text: viewModel.anime.type.localizedTitle, color: AppTheme.accent)
                    headerPill(text: viewModel.anime.status.localizedTitle, color: AppTheme.success)
                }
            }

            Text(viewModel.anime.subtitle)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(viewModel.anime.synopsis)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            genreWrap
            actionButtons(axis: buttonAxis)
            statsGrid
        }
    }

    private var genreWrap: some View {
        FlexibleView(data: viewModel.anime.genres, spacing: 10, alignment: .leading) { genre in
            Text(genre)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .fill(AppTheme.surfaceElevated)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(AppTheme.surfaceBorder, lineWidth: 1)
                )
        }
    }

    private func actionButtons(axis: Axis) -> some View {
        Group {
            if axis == .horizontal {
                HStack(spacing: 12) {
                    playButton
                    downloadButton
                    watchlistButton
                    likeButton
                    ratingMenu
                }
            } else {
                VStack(spacing: 12) {
                    playButton
                    downloadButton
                    watchlistButton
                    likeButton
                    ratingMenu
                }
            }
        }
    }

    private var playButton: some View {
        Button {
            playFirstEpisode()
        } label: {
            Label("Play", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppTheme.accent)
    }

    private var downloadButton: some View {
        Button {
            Task { await downloadFirstEpisode() }
        } label: {
            Label("Download", systemImage: "arrow.down.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.info)
    }

    private var watchlistButton: some View {
        Button {
            Task { await viewModel.toggleWatchlist() }
        } label: {
            Label(viewModel.isInWatchlist ? "In Watchlist" : "Add to Watchlist", systemImage: "bookmark.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.warning)
    }

    private var likeButton: some View {
        Button {
            Task { await viewModel.toggleLike() }
        } label: {
            Label(viewModel.isLiked ? "Liked" : "Like", systemImage: viewModel.isLiked ? "heart.fill" : "heart")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.success)
    }

    private var ratingMenu: some View {
        Menu {
            ForEach(1...10, id: \.self) { rating in
                Button("\(rating)/10") {
                    Task { await viewModel.updateRating(rating) }
                }
            }
        } label: {
            Label(viewModel.selectedRating == 0 ? "Rate" : "\(viewModel.selectedRating)/10", systemImage: "star.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(AppTheme.accentSecondary)
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
            StatTile(title: "Рейтинг", value: "\(viewModel.anime.ratingVotes.formatted(.number.notation(.compactName)))", tint: AppTheme.accent)
            StatTile(title: "Эпизоды", value: viewModel.anime.progressText, tint: AppTheme.success)
            StatTile(title: "Возраст", value: viewModel.anime.ageRating, tint: AppTheme.warning)
            StatTile(title: "Watch hours", value: "\(viewModel.anime.watchHours)h", tint: AppTheme.info)
        }
    }

    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeaderView(title: "Список серий", subtitle: "Autoplay next, resume playback, custom controls и offline")

            switch viewModel.episodesState {
            case .idle, .loading:
                LoadingStateView(message: "Подгружаем эпизоды...")

            case let .failed(message):
                MessageStateView(title: "Эпизоды недоступны", message: message, actionTitle: "Повторить") {
                    Task { await viewModel.load(refresh: true) }
                }

            case let .empty(message):
                MessageStateView(title: "Нет серий", message: message, actionTitle: nil, action: nil)

            case let .loaded(episodes):
                VStack(spacing: 12) {
                    ForEach(episodes) { episode in
                        episodeRow(episode, episodes: episodes)
                    }
                }
            }
        }
    }

    private func episodeRow(_ episode: Episode, episodes: [Episode]) -> some View {
        let downloadItem = container.downloadManager.item(for: episode.id)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                RemoteImageView(url: episode.thumbnailURL, pipeline: container.imagePipeline)
                    .frame(width: 132, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Серия \(episode.number) • \(episode.title)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(episode.synopsis)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text("\(episode.durationMinutes) мин")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppTheme.textMuted)

                        if let source = episode.playbackSources.first {
                            Text(source.kind == .hls ? "HLS" : "MP4")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                }

                Spacer()

                Button {
                    playEpisode(episode, within: episodes)
                } label: {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)

                Button {
                    Task { await handleDownload(for: episode) }
                } label: {
                    Image(systemName: downloadSymbol(for: episode))
                }
                .buttonStyle(.bordered)
            }

            if let downloadItem, downloadItem.status != .completed {
                ProgressView(value: downloadItem.progress)
                    .tint(AppTheme.info)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private func playFirstEpisode() {
        guard case let .loaded(episodes) = viewModel.episodesState, let firstEpisode = episodes.first else { return }
        playEpisode(firstEpisode, within: episodes)
    }

    private func downloadFirstEpisode() async {
        guard case let .loaded(episodes) = viewModel.episodesState, let firstEpisode = episodes.first else { return }
        guard supportsOfflineDownload(firstEpisode) else {
            viewModel.toastMessage = "Сайт пока отдаёт эту серию только как embed-источник, офлайн недоступен"
            return
        }
        try? await container.downloadManager.downloadEpisode(firstEpisode)
        viewModel.toastMessage = "Первая серия скачана офлайн"
    }

    private func handleDownload(for episode: Episode) async {
        guard supportsOfflineDownload(episode) else {
            viewModel.toastMessage = "Для этого источника пока нет прямого файла или HLS для офлайн-режима"
            return
        }

        if container.downloadManager.isDownloaded(episode) {
            container.downloadManager.removeDownloadedEpisode(episode.id)
            viewModel.toastMessage = "Скачанный эпизод удалён"
            return
        }

        if let item = container.downloadManager.item(for: episode.id) {
            switch item.status {
            case .downloading:
                container.downloadManager.pauseDownload(episode.id)
                viewModel.toastMessage = "Загрузка приостановлена"
            case .paused, .failed:
                container.downloadManager.resumeDownload(for: episode)
                viewModel.toastMessage = "Загрузка продолжена"
            case .queued, .completed:
                break
            }
            return
        }

        try? await container.downloadManager.downloadEpisode(episode)
        viewModel.toastMessage = "Эпизод добавлен в загрузки"
    }

    private func playEpisode(_ episode: Episode, within episodes: [Episode]) {
        guard supportsNativePlayback(episode) else {
            viewModel.toastMessage = "Источник сайта пока отдает эту серию как web-embed. Для нативного AVPlayer нужен extractor прямого потока."
            return
        }
        container.playerManager.present(anime: viewModel.anime, episodes: episodes, startAt: episode)
    }

    private func supportsNativePlayback(_ episode: Episode) -> Bool {
        guard let url = episode.playbackSources.first?.streamURL else { return false }
        return !isEmbeddedProviderURL(url)
    }

    private func supportsOfflineDownload(_ episode: Episode) -> Bool {
        guard let url = episode.playbackSources.first?.streamURL else { return false }
        if isEmbeddedProviderURL(url) {
            return false
        }
        let ext = url.pathExtension.lowercased()
        return ext == "m3u8" || ext == "mp4"
    }

    private func isEmbeddedProviderURL(_ url: URL) -> Bool {
        (url.host ?? "").localizedCaseInsensitiveContains("kodikplayer.com")
    }

    private func downloadSymbol(for episode: Episode) -> String {
        if container.downloadManager.isDownloaded(episode) {
            return "checkmark.circle.fill"
        }

        switch container.downloadManager.item(for: episode.id)?.status {
        case .downloading:
            return "pause.circle.fill"
        case .paused, .failed:
            return "arrow.clockwise.circle.fill"
        default:
            return "arrow.down.circle"
        }
    }

    private func headerPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule(style: .continuous).fill(color))
    }
}

private struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    var body: some View {
        GeometryReader { geometry in
            generateContent(in: geometry)
        }
        .frame(height: 90)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        let items = Array(data)

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.trailing, spacing)
                    .padding(.bottom, spacing)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height + spacing
                        }
                        let result = width
                        if item == items.last {
                            width = 0
                        } else {
                            width -= dimension.width + spacing
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last {
                            height = 0
                        }
                        return result
                    }
            }
        }
    }
}
