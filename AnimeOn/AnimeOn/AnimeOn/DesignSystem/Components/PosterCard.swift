import SwiftUI

struct PosterCard: View {
    @Environment(\.appTheme) private var theme

    let anime: Anime
    let width: CGFloat

    init(anime: Anime, width: CGFloat = 160) {
        self.anime = anime
        self.width = width
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                ArtworkView(
                    title: anime.title,
                    imageURL: anime.posterURL,
                    cornerRadius: theme.radii.poster
                )
                .frame(width: width, height: width * 1.48)

                LinearGradient(
                    colors: [.clear, .black.opacity(0.12), .black.opacity(0.7)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: theme.radii.poster, style: .continuous))

                HStack(alignment: .top) {
                    MetadataPill(anime.format.title)
                    Spacer(minLength: 0)
                    MetadataPill(String(format: "%.1f", anime.averageRating), icon: "star.fill", highlighted: true)
                }
                .padding(10)
            }
            .overlay(
                RoundedRectangle(cornerRadius: theme.radii.poster, style: .continuous)
                    .stroke(theme.palette.surfaceHighlight.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: theme.palette.shadow.opacity(0.6), radius: 16, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 5) {
                Text(anime.title)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.palette.textPrimary)
                    .lineLimit(2)

                Text(L10n.yearStatusStudio(anime.year, anime.status.title, anime.studio))
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.palette.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: width, alignment: .leading)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    PosterCard(anime: MockCatalog.titles[1])
        .padding()
        .background(Color.black)
}
