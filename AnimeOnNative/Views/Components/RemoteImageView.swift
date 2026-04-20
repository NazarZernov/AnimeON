import SwiftUI

@MainActor
final class RemoteImageLoader: ObservableObject {
    @Published var image: PlatformImage?

    private let pipeline: ImagePipeline
    private var lastLoadedURL: URL?

    init(pipeline: ImagePipeline) {
        self.pipeline = pipeline
    }

    func load(from url: URL?) async {
        guard lastLoadedURL != url || image == nil else { return }
        lastLoadedURL = url

        guard let url else {
            image = nil
            return
        }

        do {
            image = try await pipeline.image(for: url)
        } catch {
            image = nil
        }
    }
}

struct RemoteImageView: View {
    let url: URL?
    let pipeline: ImagePipeline
    let contentMode: ContentMode

    @StateObject private var loader: RemoteImageLoader

    init(url: URL?, pipeline: ImagePipeline, contentMode: ContentMode = .fill) {
        self.url = url
        self.pipeline = pipeline
        self.contentMode = contentMode
        _loader = StateObject(wrappedValue: RemoteImageLoader(pipeline: pipeline))
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.cardGradient)

            if let image = loader.image {
                Image(platformImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.textMuted)
                    Text("AnimeOn")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textMuted)
                }
            }
        }
        .clipped()
        .task(id: url) {
            await loader.load(from: url)
        }
    }
}
