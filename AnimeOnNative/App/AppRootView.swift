import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case home
    case catalog
    case schedule
    case search
    case downloads
    case random
    case updates
    case news
    case premium
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .catalog: "Catalog"
        case .schedule: "Schedule"
        case .search: "Search"
        case .downloads: "Downloads"
        case .random: "Random"
        case .updates: "Updates"
        case .news: "News"
        case .premium: "Premium"
        case .profile: "Profile"
        }
    }

    var displayTitle: String {
        switch self {
        case .home: "Главная"
        case .catalog: "Каталог"
        case .schedule: "Расписание"
        case .search: "Поиск"
        case .downloads: "Загрузки"
        case .random: "Рандом"
        case .updates: "Обновления"
        case .news: "Новости"
        case .premium: "Premium"
        case .profile: "Профиль"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .catalog: "square.grid.2x2.fill"
        case .schedule: "calendar"
        case .search: "magnifyingglass"
        case .downloads: "arrow.down.circle.fill"
        case .random: "shuffle"
        case .updates: "sparkles.rectangle.stack.fill"
        case .news: "newspaper.fill"
        case .premium: "crown.fill"
        case .profile: "person.crop.circle.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .home:
            return "Главная витрина с hero-баннером, свежими эпизодами, расписанием и новостями."
        case .catalog:
            return "Большая сетка постеров, фильтры, сортировка и бесконечная лента."
        case .schedule:
            return "Календарь релизов, синхронизированный с привычным ритмом AnimeOn."
        case .search:
            return "Дебаунс-поиск по каталогу, быстрые результаты и recent queries."
        case .downloads:
            return "Офлайн-эпизоды, прогресс загрузки, пауза, продолжение и удаление."
        case .random:
            return "Случайный тайтл, когда хочется выбрать что-то без долгих раздумий."
        case .updates:
            return "Все свежие эпизоды и изменения по каталогу в одной ленте."
        case .news:
            return "Редакционные анонсы, сезонные подборки и заметки о релизах."
        case .premium:
            return "Премиум-оформление, ускоренный прогресс и 4K-режим."
        case .profile:
            return "Вход, watchlist, история просмотра и пользовательская статистика."
        }
    }

    static let primarySections: [AppSection] = [.home, .catalog, .schedule, .search, .profile]
    static let macSidebarSections: [AppSection] = [.home, .catalog, .schedule, .search, .downloads, .profile]
}

struct AppRootView: View {
    @EnvironmentObject private var container: AppContainer

    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    #endif

    var body: some View {
        ZStack {
            StreamingBackgroundView()
                .ignoresSafeArea()

            #if os(macOS)
            NavigationSplitView {
                List(selection: selectedSectionBinding) {
                    Section("Browse") {
                        ForEach(AppSection.macSidebarSections) { section in
                            Label(section.displayTitle, systemImage: section.systemImage)
                                .tag(section)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("AnimeOn Native")
            } detail: {
                rootNavigationStack(for: container.selectedSection)
            }
            .navigationSplitViewStyle(.balanced)
            #else
            TabView(selection: selectedSectionBinding) {
                ForEach(AppSection.primarySections) { section in
                    rootNavigationStack(for: section)
                        .tag(section)
                        .tabItem {
                            Label(section.displayTitle, systemImage: section.systemImage)
                        }
                }
            }
            .tint(AppTheme.accent)
            #endif
        }
        #if os(iOS)
        .fullScreenCover(isPresented: Binding(
            get: { container.playerManager.isPresented },
            set: { isPresented in
                if !isPresented {
                    container.playerManager.dismiss()
                }
            }
        )) {
            EpisodePlayerSheet(coordinator: container.playerManager)
                .environmentObject(container)
        }
        #endif
        #if os(macOS)
        .onChange(of: container.playerManager.isPresented) { _, isPresented in
            if isPresented {
                openWindow(id: "player-window")
            } else {
                dismissWindow(id: "player-window")
            }
        }
        #endif
    }

    private var selectedSectionBinding: Binding<AppSection> {
        Binding(
            get: { container.selectedSection },
            set: { container.selectedSection = $0 }
        )
    }

    @ViewBuilder
    private func rootNavigationStack(for section: AppSection) -> some View {
        NavigationStack {
            sectionView(for: section)
                .navigationDestination(for: Anime.self) { anime in
                    AnimeDetailView(
                        anime: anime,
                        repository: container.repository,
                        selectedSection: selectedSectionBinding
                    )
                    .environmentObject(container)
                }
        }
    }

    @ViewBuilder
    private func sectionView(for section: AppSection) -> some View {
        switch section {
        case .home:
            HomeView(repository: container.repository, selectedSection: selectedSectionBinding)
        case .catalog:
            CatalogView(repository: container.repository, selectedSection: selectedSectionBinding)
        case .schedule:
            ScheduleView(repository: container.repository, selectedSection: selectedSectionBinding)
        case .search:
            SearchView(repository: container.repository, selectedSection: selectedSectionBinding)
        case .downloads:
            DownloadsView(selectedSection: selectedSectionBinding)
        case .profile:
            ProfileView(repository: container.repository, selectedSection: selectedSectionBinding)
        case .random, .updates, .news, .premium:
            placeholderSection(for: section)
        }
    }

    private func placeholderSection(for section: AppSection) -> some View {
        ScreenContainer(
            selectedSection: selectedSectionBinding,
            currentSection: section,
            title: section.displayTitle,
            subtitle: "Этот раздел теперь перенесён в новую Home/Search/Profile-информационную архитектуру."
        ) {
            MessageStateView(
                title: section.displayTitle,
                message: "Функции раздела доступны через главную витрину, поиск и профиль.",
                actionTitle: "На главную"
            ) {
                container.selectedSection = .home
            }
        }
    }
}
