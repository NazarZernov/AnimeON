import SwiftUI

struct DownloadsView: View {
    @EnvironmentObject private var container: AppContainer
    @Binding private var selectedSection: AppSection

    init(selectedSection: Binding<AppSection>) {
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .downloads,
            title: "Downloads",
            subtitle: AppSection.downloads.subtitle
        ) {
            if container.downloadManager.orderedDownloads.isEmpty {
                MessageStateView(
                    title: "Пока нет офлайн-эпизодов",
                    message: "Скачайте серию из карточки тайтла, и она появится здесь вместе с прогрессом и управлением.",
                    actionTitle: "Открыть каталог"
                ) {
                    selectedSection = .catalog
                }
            } else {
                VStack(spacing: 14) {
                    ForEach(container.downloadManager.orderedDownloads) { item in
                        downloadRow(for: item)
                    }
                }
            }
        }
    }

    private func downloadRow(for item: DownloadItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Эпизод \(item.episode.number)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.textMuted)

                    Text(item.episode.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(item.status.rawValue.capitalized)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(item.isFinished ? AppTheme.success : AppTheme.textSecondary)
                }

                Spacer()

                HStack(spacing: 10) {
                    if item.status == .downloading {
                        Button {
                            container.downloadManager.pauseDownload(item.id)
                        } label: {
                            Image(systemName: "pause.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    if item.status == .paused || item.status == .failed {
                        Button {
                            container.downloadManager.resumeDownload(for: item.episode)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button(role: .destructive) {
                        container.downloadManager.removeDownloadedEpisode(item.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
            }

            ProgressView(value: item.progress)
                .tint(item.isFinished ? AppTheme.success : AppTheme.accent)

            HStack {
                Text(item.isFinished ? "Доступно офлайн" : "\(Int(item.progress * 100))% загружено")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()

                Text("\(item.episode.durationMinutes) мин")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textMuted)
            }
        }
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
