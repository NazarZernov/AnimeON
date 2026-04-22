import SwiftUI

struct MiniPlayerBar: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var playbackCoordinator: PlaybackCoordinator

    var body: some View {
        if let context = playbackCoordinator.currentContext {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ArtworkView(title: context.anime.title, imageURL: context.anime.posterURL, cornerRadius: 14, overlayOpacity: 0.18)
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.anime.title)
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.palette.textPrimary)
                            .lineLimit(1)
                        Text(L10n.format("Episode %d • Tap for full controls", context.episode.number))
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        playbackCoordinator.togglePlayback()
                    } label: {
                        Image(systemName: playbackCoordinator.engine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(theme.palette.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(theme.palette.secondaryCard.opacity(0.96), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 9)
                .contentShape(Rectangle())
                .onTapGesture {
                    playbackCoordinator.isPresentingPlayer = true
                }

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 3)
                    Capsule(style: .continuous)
                        .fill(theme.palette.accent)
                        .frame(width: max(progress * 280, 16), height: 3)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(theme.palette.card.opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(theme.palette.surfaceHighlight.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(theme.palette.outline, lineWidth: 1)
                    )
            )
            .shadow(color: theme.palette.shadow.opacity(0.72), radius: 18, x: 0, y: 10)
        }
    }

    private var progress: CGFloat {
        let duration = playbackCoordinator.engine.duration
        guard duration > 0 else { return 0.02 }
        return min(max(playbackCoordinator.engine.currentTime / duration, 0.02), 1)
    }
}

#Preview {
    MiniPlayerBar()
        .environmentObject(AppContainer.live.playbackCoordinator)
        .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
        .padding()
        .background(Color.black)
}
