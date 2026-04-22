import Foundation

@MainActor
protocol APIClientProtocol {
    func makeURL(for endpoint: Endpoint) -> URL?
}

@MainActor
struct APIClient: APIClientProtocol {
    private let settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
    }

    func makeURL(for endpoint: Endpoint) -> URL? {
        let configuration = AppEnvironment.configuration(from: settingsStore.settings.advanced)
        guard var components = URLComponents(string: configuration.baseURL) else { return nil }
        components.path += endpoint.path
        components.queryItems = endpoint.queryItems
        return components.url
    }
}
