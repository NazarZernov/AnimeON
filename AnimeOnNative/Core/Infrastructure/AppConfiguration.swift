import Foundation

enum DataSourceMode {
    case mock
    case remote(baseURL: URL)
    case hybrid(baseURL: URL)
}

struct AppConfiguration {
    let dataSourceMode: DataSourceMode

    static let current = AppConfiguration(
        dataSourceMode: .hybrid(baseURL: URL(string: "https://animeon.su/api")!)
    )
}
