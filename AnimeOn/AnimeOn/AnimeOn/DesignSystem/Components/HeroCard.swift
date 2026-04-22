import SwiftUI

struct HeroCard: View {
    @Environment(\.appTheme) private var theme

    let anime: Anime
    let metrics: LayoutMetrics
    let onPlay: () -> Void
    let onDetails: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            ArtworkView(
                title: anime.title,
                imageURL: anime.backdropURL,
                cornerRadius: theme.radii.hero,
                overlayOpacity: 0.2
            )
            .frame(height: metrics.heroHeight)

            LinearGradient(
                colors: [
                    Color.black.opacity(0.12),
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.hero, style: .continuous))

            HStack(alignment: .bottom, spacing: metrics.rowSpacing) {
                VStack(alignment: .leading, spacing: metrics.rowSpacing) {
                    HStack(spacing: 8) {
                        MetadataPill("Featured", icon: "sparkles", highlighted: true)
                        MetadataPill(anime.format.title)
                        MetadataPill(String(format: "%.1f", anime.averageRating), icon: "star.fill")
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(anime.title)
                            .font(metrics.isNarrowPhone ? theme.typography.title : theme.typography.hero)
                            .foregroundStyle(theme.palette.textPrimary)
                            .lineLimit(2)

                        Text(L10n.originalYearStatus(anime.originalTitle, anime.year, anime.status.title))
                            .font(theme.typography.subheadline)
                            .foregroundStyle(theme.palette.textSecondary)
                            .lineLimit(1)

                        Text(anime.synopsis)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.palette.textSecondary)
                            .lineLimit(metrics.heroSynopsisLines)
                    }

                    HStack(spacing: 8) {
                        ForEach(anime.genres.prefix(3)) { genre in
                            MetadataPill(genre.title)
                        }
                    }

                    HStack(spacing: 10) {
                        GradientButton("Watch", systemImage: "play.fill", size: .compact, action: onPlay)
                        GradientButton("Details", systemImage: "info.circle", isProminent: false, size: .compact, action: onDetails)
                    }
                }
                .padding(.trailing, metrics.isNarrowPhone ? 0 : 4)

                if !metrics.isNarrowPhone {
                    ArtworkView(title: anime.title, imageURL: anime.posterURL, cornerRadius: theme.radii.poster)
                        .frame(width: 90, height: 128)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radii.poster, style: .continuous)
                                .stroke(theme.palette.surfaceHighlight, lineWidth: 1)
                        )
                        .shadow(color: theme.palette.shadow.opacity(0.55), radius: 18, x: 0, y: 12)
                }
            }
            .padding(metrics.heroInset)
        }
        .overlay(
            RoundedRectangle(cornerRadius: theme.radii.hero, style: .continuous)
                .stroke(theme.palette.surfaceHighlight.opacity(0.7), lineWidth: 1)
        )
        .shadow(color: theme.palette.shadow.opacity(0.82), radius: 26, x: 0, y: 16)
        .frame(height: metrics.heroHeight)
    }
}

#Preview {
    HeroCard(
        anime: MockCatalog.titles[0],
        metrics: LayoutMetrics.forWidth(390, theme: ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced)),
        onPlay: {},
        onDetails: {}
    )
        .padding()
        .background(Color.black)
}
