import SwiftUI

struct AnimeCardView: View {
    let anime: Anime
    let pipeline: ImagePipeline
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                RemoteImageView(url: anime.posterURL, pipeline: pipeline)
                    .frame(height: 250)
                    .overlay(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [.clear, Color.black.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .overlay(alignment: .bottomLeading) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(anime.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)

                                Text("\(anime.year) • \(anime.type.localizedTitle)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.74))
                            }
                            .padding(14)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                HStack(spacing: 8) {
                    pill(text: String(format: "%.1f", anime.rating), color: AppTheme.accent)
                    if anime.status == .ongoing {
                        pill(text: "Онгоинг", color: AppTheme.success)
                    }
                }
                .padding(12)
            }

            HStack {
                Text(anime.progressText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Text("\(anime.viewsCount.formatted(.number.notation(.compactName))) views")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isHovered ? 0.26 : 0.12), radius: isHovered ? 24 : 12, y: isHovered ? 16 : 8)
        .scaleEffect(isHovered ? 1.015 : 1)
        .animation(.spring(response: 0.3, dampingFraction: 0.82), value: isHovered)
        #if os(macOS)
        .onHover { hovering in
            isHovered = hovering
        }
        #endif
    }

    private func pill(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(color)
            )
    }
}
