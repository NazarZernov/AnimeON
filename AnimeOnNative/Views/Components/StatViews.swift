import SwiftUI

struct LeaderboardCard: View {
    let entry: PlayerLeaderboardEntry
    let pipeline: ImagePipeline

    var body: some View {
        HStack(spacing: 14) {
            Text("#\(entry.rank)")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 32)

            RemoteImageView(url: entry.avatarURL, pipeline: pipeline)
                .frame(width: 56, height: 56)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(entry.username)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    if entry.isPremium {
                        Label("Premium", systemImage: "crown.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Capsule(style: .continuous).fill(AppTheme.accent))
                    }
                }

                Text("\(entry.watchTimeLabel) • \(entry.tier)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Spacer()

            Text("\(entry.score)")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.warning)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)

            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(tint)
                .frame(width: 48, height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AppTheme.surfaceBorder, lineWidth: 1)
        )
    }
}
