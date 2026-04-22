import SwiftUI

struct DownloadProgressRow: View {
    @Environment(\.appTheme) private var theme

    let task: DownloadTaskModel
    let formattedSize: String
    let onPauseResume: () -> Void
    let onCancel: () -> Void

    var body: some View {
        GlassCard(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.animeTitle)
                            .font(theme.typography.headline)
                            .foregroundStyle(theme.palette.textPrimary)
                            .lineLimit(2)
                        Text(L10n.episodeWithTitle(task.episodeNumber, task.quality.title))
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.palette.textSecondary)
                    }
                    Spacer()
                    MetadataPill(task.status.title, icon: iconName)
                }

                ProgressView(value: task.progress)
                    .tint(theme.palette.accent)

                HStack {
                    Text(formattedSize)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                    Spacer()
                    Button(task.status == .downloading ? L10n.tr("Pause") : L10n.tr("Resume"), action: onPauseResume)
                        .foregroundStyle(theme.palette.accent)
                    Button("Cancel", role: .destructive, action: onCancel)
                }
                .font(theme.typography.caption)
            }
        }
    }

    private var iconName: String {
        switch task.status {
        case .queued: "clock"
        case .downloading: "arrow.down.circle"
        case .paused: "pause.circle"
        case .completed: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        }
    }
}

#Preview {
    DownloadProgressRow(
        task: MockCatalog.seedDownloads[0],
        formattedSize: "667 MB of 1.45 GB",
        onPauseResume: {},
        onCancel: {}
    )
    .padding()
    .background(Color.black)
}
