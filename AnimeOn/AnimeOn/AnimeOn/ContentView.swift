//
//  ContentView.swift
//  AnimeOn
//
//  Created by EHM on 22.04.2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var settingsStore: SettingsStore

    var body: some View {
        Group {
            if settingsStore.settings.advanced.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView()
            }
        }
        .environment(\.appTheme, themeManager.theme)
        .preferredColorScheme(themeManager.colorScheme)
        .tint(themeManager.theme.palette.accent)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppContainer.live)
        .environmentObject(AppContainer.live.settingsStore)
        .environmentObject(AppContainer.live.themeManager)
        .environmentObject(AppContainer.live.sessionStore)
        .environmentObject(AppContainer.live.downloadManager)
        .environmentObject(AppContainer.live.playbackCoordinator)
}
