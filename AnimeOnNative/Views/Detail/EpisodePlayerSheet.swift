import SwiftUI

struct EpisodePlayerSheet: View {
    @ObservedObject var coordinator: PlayerManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    PlayerSurfaceView(manager: coordinator)
                        .frame(minHeight: 320)
                        .aspectRatio(16 / 9, contentMode: .fit)

                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: 20) {
                            summaryPanel
                            episodePanel
                        }

                        VStack(alignment: .leading, spacing: 20) {
                            summaryPanel
                            episodePanel
                        }
                    }
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        coordinator.dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Next Episode") {
                        coordinator.playNextEpisode()
                    }
                }
            }
        }
        #if os(macOS)
        .onMoveCommand { direction in
            switch direction {
            case .left:
                coordinator.seek(by: -10)
            case .right:
                coordinator.seek(by: 10)
            case .down:
                coordinator.playNextEpisode()
            default:
                break
            }
        }
        .onExitCommand {
            coordinator.dismiss()
        }
        #endif
    }

    private var summaryPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(coordinator.anime?.title ?? "AnimeOn")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)

            if let episode = coordinator.currentEpisode {
                Text("Серия \(episode.number) • \(episode.title)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)

                Text(episode.synopsis)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 12) {
                statPill(title: "Source", value: coordinator.selectedSource?.title ?? "Default")
                statPill(
                    title: "Quality",
                    value: coordinator.availableQualities.first(where: { $0.id == coordinator.selectedQualityID })?.label ?? "Auto"
                )
                statPill(title: "Speed", value: "\(coordinator.playbackRate.formatted())x")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
    }

    private var episodePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeaderView(title: "Очередь серий", subtitle: "Стрелки клавиатуры, enter и autoplay")

            VStack(spacing: 12) {
                ForEach(coordinator.episodes) { episode in
                    Button {
                        coordinator.selectEpisode(episode)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("EP \(episode.number)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(AppTheme.textMuted)

                                Text(episode.title)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(AppTheme.textPrimary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            if coordinator.currentEpisode == episode {
                                Image(systemName: "waveform.circle.fill")
                                    .foregroundStyle(AppTheme.accent)
                            }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(coordinator.currentEpisode == episode ? AppTheme.accent.opacity(0.16) : AppTheme.surface.opacity(0.96))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(coordinator.currentEpisode == episode ? AppTheme.accent : AppTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(AppTheme.textMuted)

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.surfaceElevated)
        )
    }
}
