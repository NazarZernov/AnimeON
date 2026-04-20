import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel: ProfileViewModel
    @Binding private var selectedSection: AppSection

    init(repository: AnimeRepositoryProtocol, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(repository: repository))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .profile,
            title: viewModel.isAuthenticated ? "Ваш профиль" : "Войти в профиль",
            subtitle: AppSection.profile.subtitle,
            onRefresh: {
                await viewModel.loadProfile()
            }
        ) {
            if !viewModel.isAuthenticated {
                loginCard
            } else {
                profileContent
            }
        }
        .task {
            if viewModel.isAuthenticated {
                await viewModel.loadProfile()
            }
        }
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Вход")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            profileField(title: "Email", text: $viewModel.email, isSecure: false)
            profileField(title: "Пароль", text: $viewModel.password, isSecure: true)

            if let authError = viewModel.authError {
                Text(authError)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.danger)
            }

            Text("Demo login уже подставлен. После подключения production-auth этот экран останется тем же.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textMuted)

            Button("Войти") {
                Task { await viewModel.login() }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var profileContent: some View {
        switch viewModel.profileState {
        case .idle, .loading:
            LoadingStateView(message: "Загружаем профиль, статистику и локальные данные...")

        case let .failed(message):
            MessageStateView(title: "Профиль недоступен", message: message, actionTitle: "Повторить") {
                Task { await viewModel.loadProfile() }
            }

        case let .empty(message):
            MessageStateView(title: "Нет данных", message: message, actionTitle: nil, action: nil)

        case let .loaded(profile):
            VStack(alignment: .leading, spacing: 20) {
                profileHeader(profile)
                statusCards(profile)
                quickActions
                badgesCard(profile)
                watchlistCard(profile)
                historyCard(profile)
            }
        }
    }

    private func profileHeader(_ profile: UserProfile) -> some View {
        HStack(spacing: 18) {
            RemoteImageView(url: profile.avatarURL, pipeline: container.imagePipeline)
                .frame(width: 96, height: 96)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text(profile.displayName)
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("@\(profile.username)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                if profile.isPremium {
                    Label("Premium active", systemImage: "crown.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.warning)
                }
            }

            Spacer()

            Button("Sync now") {
                Task {
                    await container.repository.flushSyncQueue()
                    await viewModel.loadProfile()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }

    private func statusCards(_ profile: UserProfile) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            StatTile(title: "Level", value: "\(profile.level)", tint: AppTheme.accent)
            StatTile(title: "Watch hours", value: "\(profile.watchHours)h", tint: AppTheme.success)
            StatTile(title: "Episodes", value: "\(profile.watchedEpisodesCount)", tint: AppTheme.info)
            StatTile(title: "Likes", value: "\(profile.likedAnimeIDs.count)", tint: AppTheme.warning)
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            NavigationLink {
                DownloadsView(selectedSection: $selectedSection)
                    .environmentObject(container)
            } label: {
                quickActionCard(
                    title: "Downloads",
                    subtitle: "\(container.downloadManager.orderedDownloads.count) офлайн-эпизодов",
                    systemImage: "arrow.down.circle.fill",
                    tint: AppTheme.info
                )
            }
            .buttonStyle(.plain)

            quickActionCard(
                title: "Sync queue",
                subtitle: "\(container.syncManager.pendingCount) ожидают отправки",
                systemImage: "arrow.triangle.2.circlepath",
                tint: container.syncManager.pendingCount == 0 ? AppTheme.success : AppTheme.warning
            )
        }
    }

    private func badgesCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Badges", subtitle: "\(profile.badges.count) достижений")
            FlexibleBadgeRow(items: profile.badges)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
    }

    private func watchlistCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Watchlist", subtitle: "\(profile.watchlistIDs.count) тайтлов")

            if viewModel.watchlistPreview.isEmpty {
                Text(profile.watchlistIDs.map(String.init).joined(separator: ", "))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.watchlistPreview) { anime in
                            NavigationLink(value: anime) {
                                AnimeCardView(anime: anime, pipeline: container.imagePipeline)
                                    .frame(width: 190)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
    }

    private func historyCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Recent history", subtitle: "\(profile.history.count) последних просмотров")

            if viewModel.historyPreview.isEmpty {
                ForEach(profile.history.prefix(5)) { entry in
                    HStack {
                        Text("Anime #\(entry.animeID)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Spacer()

                        Text("\(Int(entry.progressSeconds)) сек")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
            } else {
                ForEach(viewModel.historyPreview) { anime in
                    HStack(spacing: 14) {
                        RemoteImageView(url: anime.posterURL, pipeline: container.imagePipeline)
                            .frame(width: 70, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 6) {
                            Text(anime.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(historySubtitle(for: anime, profile: profile))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
    }

    private func profileField(title: String, text: Binding<String>, isSecure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)

            Group {
                if isSecure {
                    SecureField(title, text: text)
                } else {
                    TextField(title, text: text)
                }
            }
            .textFieldStyle(.plain)
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.background.opacity(0.82))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.surfaceBorder, lineWidth: 1)
            )
        }
    }

    private func quickActionCard(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()
        }
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

    private func historySubtitle(for anime: Anime, profile: UserProfile) -> String {
        guard let entry = profile.history.first(where: { $0.animeID == anime.id }) else {
            return "Последний просмотр"
        }

        return "\(Int(entry.progressSeconds)) сек • \(entry.lastWatchedAt.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct FlexibleBadgeRow: View {
    let items: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items, id: \.self) { badge in
                    Text(badge)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
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
        }
    }
}
