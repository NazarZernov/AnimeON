import SwiftUI

@main
struct AnimeOnNativeApp: App {
    @StateObject private var container = AppContainer()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(container)
                .preferredColorScheme(.dark)
                .onChange(of: scenePhase) { _, newPhase in
                    container.handleScenePhase(newPhase)
                }
        }
        .commands {
            CommandMenu("AnimeOn") {
                Button("Главная") {
                    container.selectedSection = .home
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button("Каталог") {
                    container.selectedSection = .catalog
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button("Расписание") {
                    container.selectedSection = .schedule
                }
                .keyboardShortcut("3", modifiers: [.command])

                Button("Поиск") {
                    container.selectedSection = .search
                }
                .keyboardShortcut("f", modifiers: [.command])

                Button("Загрузки") {
                    container.selectedSection = .downloads
                }
                .keyboardShortcut("d", modifiers: [.command, .option])
            }
        }
        #if os(macOS)
        WindowGroup("Player", id: "player-window") {
            Group {
                if container.playerManager.isPresented {
                    EpisodePlayerSheet(coordinator: container.playerManager)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "play.rectangle.on.rectangle")
                            .font(.system(size: 36))
                            .foregroundStyle(AppTheme.textMuted)
                        Text("Плеер появится здесь после выбора серии")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.background.ignoresSafeArea())
                }
            }
            .environmentObject(container)
            .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1180, height: 780)
        #endif
    }
}
