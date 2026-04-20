import Foundation

@MainActor
final class ImagePipeline {
    private let cacheManager: CacheManager
    private let session: URLSession

    init(cacheManager: CacheManager, session: URLSession = .shared) {
        self.cacheManager = cacheManager
        self.session = session
    }

    func image(for url: URL) async throws -> PlatformImage {
        if let cachedData = await cacheManager.data(forKey: url.absoluteString),
           let cached = PlatformImage(data: cachedData) {
            return cached
        }

        let (data, _) = try await session.data(from: url)
        guard let image = PlatformImage(data: data) else {
            throw URLError(.cannotDecodeRawData)
        }

        await cacheManager.store(data, forKey: url.absoluteString)
        return image
    }
}
