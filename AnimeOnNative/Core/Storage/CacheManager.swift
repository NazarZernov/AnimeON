import CryptoKit
import Foundation

actor CacheManager {
    private let memoryCache: NSCache<NSString, NSData>
    private let directoryURL: URL
    private let fileManager: FileManager

    init(namespace: String) {
        let fileManager = FileManager.default
        let memoryCache = NSCache<NSString, NSData>()
        let appSupport = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? fileManager.temporaryDirectory

        let directoryURL = appSupport
            .appendingPathComponent("AnimeOnNative", isDirectory: true)
            .appendingPathComponent(namespace, isDirectory: true)

        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        self.fileManager = fileManager
        self.memoryCache = memoryCache
        self.directoryURL = directoryURL
        memoryCache.countLimit = 300
        memoryCache.totalCostLimit = 96 * 1_024 * 1_024
    }

    func data(forKey key: String) -> Data? {
        let nsKey = key as NSString
        if let data = memoryCache.object(forKey: nsKey) {
            return Data(referencing: data)
        }

        let url = fileURL(forKey: key)
        guard let data = try? Data(contentsOf: url) else {
            return nil
        }

        memoryCache.setObject(data as NSData, forKey: nsKey, cost: data.count)
        return data
    }

    func store(_ data: Data, forKey key: String) {
        let nsKey = key as NSString
        memoryCache.setObject(data as NSData, forKey: nsKey, cost: data.count)
        try? data.write(to: fileURL(forKey: key), options: [.atomic])
    }

    func removeValue(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
        try? fileManager.removeItem(at: fileURL(forKey: key))
    }

    func value<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder.cachedDecoder.decode(T.self, from: data)
    }

    func store<T: Encodable>(_ value: T, forKey key: String) {
        guard let data = try? JSONEncoder.cachedEncoder.encode(value) else {
            return
        }
        store(data, forKey: key)
    }

    private func fileURL(forKey key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        return directoryURL.appendingPathComponent(digest)
    }
}

private extension JSONEncoder {
    static let cachedEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}

private extension JSONDecoder {
    static let cachedDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
