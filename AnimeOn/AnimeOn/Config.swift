import Foundation

enum AppDisplay {
    static let appName = "AnimeOn Native"
    static let appTagline = "Cinematic anime, designed natively."
    static let supportEmail = "support@animeon.local"
}

struct EnvironmentConfiguration: Equatable {
    let baseURL: String
    let dataSource: DataSourceMode
    let isRequestLoggingEnabled: Bool
}

enum AppEnvironment {
    static func configuration(from settings: AdvancedSettings) -> EnvironmentConfiguration {
        EnvironmentConfiguration(
            baseURL: settings.baseURL.isEmpty ? "https://api.animeon.local" : settings.baseURL,
            dataSource: settings.dataSourceMode,
            isRequestLoggingEnabled: settings.enableRequestLogging
        )
    }
}
