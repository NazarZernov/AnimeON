import Foundation

enum MockBundleLoaderError: LocalizedError {
    case fileNotFound(String)
    case decodeFailed(String)

    var errorDescription: String? {
        switch self {
        case let .fileNotFound(fileName):
            return "Mock JSON \(fileName) не найден в bundle."
        case let .decodeFailed(fileName):
            return "Не удалось декодировать mock JSON \(fileName)."
        }
    }
}

enum MockBundleLoader {
    static func load<T: Decodable>(_ fileName: String, bundle: Bundle = .main) throws -> T {
        guard let url = bundle.url(forResource: fileName, withExtension: nil) else {
            throw MockBundleLoaderError.fileNotFound(fileName)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw MockBundleLoaderError.decodeFailed(fileName)
        }
    }
}
