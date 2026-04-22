import Combine
import Foundation
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @Published var settings: AppSettings {
        didSet { persist() }
    }

    private let defaults: UserDefaults
    private let key = "animeon.settings"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }

    func binding<Value>(for keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings[keyPath: keyPath] },
            set: { self.settings[keyPath: keyPath] = $0 }
        )
    }

    func binding<Value>(for keyPath: WritableKeyPath<AppearanceSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings.appearance[keyPath: keyPath] },
            set: { self.settings.appearance[keyPath: keyPath] = $0 }
        )
    }

    func binding<Value>(for keyPath: WritableKeyPath<PlaybackSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings.playback[keyPath: keyPath] },
            set: { self.settings.playback[keyPath: keyPath] = $0 }
        )
    }

    func binding<Value>(for keyPath: WritableKeyPath<DownloadSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings.downloads[keyPath: keyPath] },
            set: { self.settings.downloads[keyPath: keyPath] = $0 }
        )
    }

    func binding<Value>(for keyPath: WritableKeyPath<NotificationSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings.notifications[keyPath: keyPath] },
            set: { self.settings.notifications[keyPath: keyPath] = $0 }
        )
    }

    func binding<Value>(for keyPath: WritableKeyPath<AppleEcosystemSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings.ecosystem[keyPath: keyPath] },
            set: { self.settings.ecosystem[keyPath: keyPath] = $0 }
        )
    }

    func binding<Value>(for keyPath: WritableKeyPath<AdvancedSettings, Value>) -> Binding<Value> {
        Binding(
            get: { self.settings.advanced[keyPath: keyPath] },
            set: { self.settings.advanced[keyPath: keyPath] = $0 }
        )
    }

    func resetAll() {
        settings = .default
    }

    func resetOnboarding() {
        settings.advanced.hasCompletedOnboarding = false
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
