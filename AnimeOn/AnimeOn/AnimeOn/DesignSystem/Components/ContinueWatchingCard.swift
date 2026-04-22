import SwiftUI

struct ContinueWatchingCard: View {
    @Environment(\.appTheme) private var theme

    let anime: Anime
    let progress: Double
    let subtitle: String
    let width: CGFloat

    init(
        anime: Anime,
        progress: Double,
        subtitle: String,
        width: CGFloat = 268
    ) {
        self.anime = anime
        self.progress = progress
        self.subtitle = subtitle
        self.width = width
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            let height = min(max(width * 0.5, 118), 144)

            ArtworkView(
                title: anime.title,
                imageURL: anime.backdropURL,
                cornerRadius: theme.radii.large,
                overlayOpacity: 0.24
            )
            .frame(width: width, height: height)

            LinearGradient(
                colors: [.clear, .black.opacity(0.12), .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous))

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    MetadataPill("\(Int(progress * 100))%", icon: "play.fill", highlighted: true)
                    Spacer(minLength: 0)
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.22), radius: 12, x: 0, y: 6)
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 5) {
                    Text(anime.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.palette.textPrimary)
                        .lineLimit(2)

                    Text(subtitle.localized)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                        .lineLimit(1)

                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.14))
                            .frame(height: 4)
                        Capsule(style: .continuous)
                            .fill(theme.palette.accent)
                            .frame(width: max((width - 28) * progress, 16), height: 4)
                    }
                }
            }
            .padding(14)
        }
        .frame(width: width, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                .stroke(theme.palette.surfaceHighlight.opacity(0.56), lineWidth: 1)
        )
        .shadow(color: theme.palette.shadow.opacity(0.82), radius: 18, x: 0, y: 12)
    }
}

#Preview {
    ContinueWatchingCard(anime: MockCatalog.titles[0], progress: 0.62, subtitle: "Episode 4 • 13 min left")
        .padding()
        .background(Color.black)
}
