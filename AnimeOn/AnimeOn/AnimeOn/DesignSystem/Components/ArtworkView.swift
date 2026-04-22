import SwiftUI

struct ArtworkView: View {
    let title: String
    let imageURL: URL?
    let cornerRadius: CGFloat
    let overlayOpacity: Double

    init(
        title: String,
        imageURL: URL?,
        cornerRadius: CGFloat = 24,
        overlayOpacity: Double = 0.22
    ) {
        self.title = title
        self.imageURL = imageURL
        self.cornerRadius = cornerRadius
        self.overlayOpacity = overlayOpacity
    }

    var body: some View {
        AsyncImage(url: imageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                ZStack {
                    LinearGradient(
                        colors: [
                            Color(hex: 0x2A3040),
                            Color(hex: 0x181D28),
                            Color(hex: 0x090B11)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.12),
                            .clear
                        ],
                        center: .top,
                        startRadius: 10,
                        endRadius: 180
                    )
                    VStack(spacing: 10) {
                        Image(systemName: "play.rectangle.on.rectangle.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(.white.opacity(0.88))
                        Text(title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white.opacity(0.78))
                            .padding(.horizontal, 16)
                    }
                    .padding()
                }
            }
        }
        .overlay(
            LinearGradient(
                colors: [.clear, Color.black.opacity(overlayOpacity), Color.black.opacity(overlayOpacity + 0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

#Preview {
    ArtworkView(title: "Solar Drift 404", imageURL: MockCatalog.titles.first?.posterURL)
        .frame(width: 180, height: 260)
        .padding()
        .background(Color.black)
}
