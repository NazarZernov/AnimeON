import SwiftUI

struct EpisodeTile: View {
    @Environment(\.appTheme) private var theme

    let episode: Episode
    let progress: Double
    let isDownloaded: Bool
    let artworkWidth: CGFloat
    let artworkHeight: CGFloat
    let action: () -> Void

    init(
        episode: Episode,
        progress: Double,
        isDownloaded: Bool,
        artworkWidth: CGFloat = 102,
        artworkHeight: CGFloat = 58,
        action: @escaping () -> Void
    ) {
        self.episode = episode
        self.progress = progress
        self.isDownloaded = isDownloaded
        self.artworkWidth = artworkWidth
        self.artworkHeight = artworkHeight
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ArtworkView(
                    title: episode.title,
                    imageURL: episode.thumbnailURL,
                    cornerRadius: theme.radii.medium,
                    overlayOpacity: 0.24
                )
                .frame(width: artworkWidth, height: artworkHeight)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .center, spacing: 8) {
                        Text(L10n.format("EP %d", episode.number))
                            .font(theme.typography.pill)
                            .foregroundStyle(theme.palette.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(theme.palette.secondaryCard.opacity(0.75), in: Capsule(style: .continuous))
                        if episode.isNew {
                            MetadataPill("New", icon: "sparkles", highlighted: true)
                        }
                    }

                    Text(episode.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.palette.textPrimary)
                        .lineLimit(2)

                    Text(episode.synopsis)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(L10n.compactMinutes(episode.durationMinutes))
                        Text("•")
                        Text(L10n.dubs(episode.dubCount))
                        Text("•")
                        Text(L10n.subtitles(episode.subtitleCount))
                        if isDownloaded {
                            Text("Offline")
                                .foregroundStyle(theme.palette.accent)
                        }
                    }
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.palette.textTertiary)
                    .lineLimit(1)

                    if progress > 0 {
                        ZStack(alignment: .leading) {
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 4)
                            Capsule(style: .continuous)
                                .fill(theme.palette.accent)
                                .frame(width: max(88 * progress, 12), height: 4)
                        }
                    }
                }
                Spacer(minLength: 0)

                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(theme.palette.accent.opacity(0.9), in: Circle())
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.palette.card, theme.palette.secondaryCard.opacity(0.94)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                            .fill(theme.palette.surfaceHighlight.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                            .stroke(theme.palette.outline, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EpisodeTile(episode: MockCatalog.titles[0].seasons[0].episodes[0], progress: 0.42, isDownloaded: false, action: {})
        .padding()
        .background(Color.black)
}
