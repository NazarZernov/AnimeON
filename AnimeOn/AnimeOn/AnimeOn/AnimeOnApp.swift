//
//  AnimeOnApp.swift
//  AnimeOn
//
//  Created by EHM on 22.04.2026.
//

import SwiftUI

@main
struct AnimeOnApp: App {
    @StateObject private var container = AppContainer.live

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .environmentObject(container.settingsStore)
                .environmentObject(container.themeManager)
                .environmentObject(container.sessionStore)
                .environmentObject(container.downloadManager)
                .environmentObject(container.playbackCoordinator)
        }
    }
}
