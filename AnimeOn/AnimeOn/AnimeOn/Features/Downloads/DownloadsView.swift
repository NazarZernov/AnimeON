import SwiftUI

struct DownloadsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var settingsStore: SettingsStore
    @EnvironmentObject private var downloadManager: DownloadManager
    @State private var showQueueSheet = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.spacing.large) {
                storageCard

                if activeTasks.isEmpty && queuedTasks.isEmpty && completedTasks.isEmpty && failedTasks.isEmpty {
                    EmptyStateView(
                        title: "No Downloads Yet",
                        message: "Queue episodes for offline playback, storage planning, and future background download integration.",
                        systemImage: "arrow.down.circle"
                    )
                } else {
                    downloadSection("Active Downloads", tasks: activeTasks)
                    downloadSection("Queued", tasks: queuedTasks)
                    completedSection
                    failedSection
                }
            }
            .padding(.horizontal, theme.spacing.large)
            .padding(.top, theme.spacing.small)
            .padding(.bottom, 120)
        }
        .themedBackground()
        .navigationTitle("Downloads")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showQueueSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                Menu {
                    Button("Clear Completed Metadata") {
                        downloadManager.clearCompletedMetadata()
                    }
                    Button("Remove Failed") {
                        downloadManager.removeAllFailed()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showQueueSheet) {
            DownloadQualitySheet { anime, episode, quality in
                downloadManager.enqueue(anime: anime, episode: episode, quality: quality)
            }
        }
    }

    private var activeTasks: [DownloadTaskModel] {
        downloadManager.tasks.filter { $0.status == .downloading || $0.status == .paused }
    }

    private var queuedTasks: [DownloadTaskModel] {
        downloadManager.tasks.filter { $0.status == .queued }
    }

    private var completedTasks: [DownloadTaskModel] {
        downloadManager.tasks.filter { $0.status == .completed }
    }

    private var failedTasks: [DownloadTaskModel] {
        downloadManager.tasks.filter { $0.status == .failed }
    }

    private var storageCard: some View {
        let summary = downloadManager.storageSummary(limit: settingsStore.settings.downloads.storageLimit)
        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Offline Storage")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.palette.textPrimary)
                HStack {
                    Text(summary.usedText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.palette.textPrimary)
                    Spacer()
                    Text(summary.remainingText)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.palette.textSecondary)
                }
                ProgressView(value: summary.usageProgress)
                    .tint(theme.palette.accent)
                Text(L10n.limit(settingsStore.settings.downloads.storageLimit.title))
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.palette.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func downloadSection(_ title: String, tasks: [DownloadTaskModel]) -> some View {
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: title)
                ForEach(tasks) { task in
                    DownloadProgressRow(
                        task: task,
                        formattedSize: L10n.bytesOf(
                            ByteCountFormatter.string(fromByteCount: task.downloadedBytes, countStyle: .file),
                            ByteCountFormatter.string(fromByteCount: task.estimatedSizeInBytes, countStyle: .file)
                        ),
                        onPauseResume: {
                            if task.status == .downloading {
                                downloadManager.pause(taskID: task.id)
                            } else {
                                downloadManager.resume(taskID: task.id)
                            }
                        },
                        onCancel: {
                            downloadManager.cancel(taskID: task.id)
                        }
                    )
                }
            }
        }
    }

    private var completedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !completedTasks.isEmpty {
                SectionHeader(title: "Completed")
                ForEach(completedTasks) { task in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.animeTitle)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(theme.palette.textPrimary)
                                Text(L10n.episodeWithTitle(task.episodeNumber, task.quality.title))
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.palette.textSecondary)
                            }
                            Spacer()
                            MetadataPill("Ready Offline", icon: "checkmark.circle.fill", highlighted: true)
                        }
                    }
                }
            }
        }
    }

    private var failedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !failedTasks.isEmpty {
                SectionHeader(title: "Failed")
                ForEach(failedTasks) { task in
                    GlassCard {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(task.animeTitle)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(theme.palette.textPrimary)
                                Text((task.errorDescription ?? "A mock delivery failed before completion.").localized)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.palette.textSecondary)
                            }
                            Spacer()
                            Button("Retry") {
                                downloadManager.resume(taskID: task.id)
                            }
                            .foregroundStyle(theme.palette.accent)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DownloadsView()
    }
    .environmentObject(AppContainer.live.downloadManager)
    .environmentObject(AppContainer.live.settingsStore)
    .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
}
