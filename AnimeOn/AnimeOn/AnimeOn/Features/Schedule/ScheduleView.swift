import Combine
import SwiftUI

@MainActor
final class ScheduleViewModel: ObservableObject {
    enum Segment: CaseIterable, Identifiable {
        case today
        case tomorrow
        case week

        var id: String { title }

        var title: String {
            switch self {
            case .today: L10n.tr("Today")
            case .tomorrow: L10n.tr("Tomorrow")
            case .week: L10n.tr("This Week")
            }
        }
    }

    @Published private(set) var entries: [ScheduleEntry] = []
    @Published private(set) var followedIDs = Set<String>()
    @Published var segment: Segment = .today
    @Published var followedOnly = false

    func load(scheduleRepository: any ScheduleRepository, libraryRepository: any LibraryRepository) async {
        do {
            async let schedule = scheduleRepository.fetchSchedule()
            async let library = libraryRepository.fetchLibrarySections()
            let (entries, sections) = try await (schedule, library)
            self.entries = entries
            self.followedIDs = Set(sections.flatMap(\.items).map { $0.anime.id })
        } catch {
            entries = []
            followedIDs = []
        }
    }

    func filteredEntries(now: Date = .now) -> [ScheduleEntry] {
        let calendar = Calendar.current
        return entries.filter { entry in
            let matchesFollowed = !followedOnly || followedIDs.contains(entry.anime.id)
            let matchesSegment: Bool
            switch segment {
            case .today:
                matchesSegment = calendar.isDate(entry.releaseDate, inSameDayAs: now)
            case .tomorrow:
                let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
                matchesSegment = calendar.isDate(entry.releaseDate, inSameDayAs: tomorrow)
            case .week:
                matchesSegment = entry.releaseDate <= calendar.date(byAdding: .day, value: 7, to: now) ?? now
            }
            return matchesFollowed && matchesSegment
        }
    }
}

struct ScheduleView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var container: AppContainer
    @StateObject private var viewModel = ScheduleViewModel()

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: theme.spacing.large) {
                Picker("Schedule Window", selection: $viewModel.segment) {
                    ForEach(ScheduleViewModel.Segment.allCases) { segment in
                        Text(segment.title).tag(segment)
                    }
                }
                .pickerStyle(.segmented)

                Toggle("Followed titles only", isOn: $viewModel.followedOnly)
                    .toggleStyle(.switch)
                    .foregroundStyle(theme.palette.textPrimary)

                let filtered = viewModel.filteredEntries()
                if filtered.isEmpty {
                    EmptyStateView(
                        title: "A Calm Schedule",
                        message: "No releases match this window yet. Try expanding to the week view or disabling followed-only mode.",
                        systemImage: "calendar.badge.clock"
                    )
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 14) {
                        ForEach(filtered) { entry in
                            GlassCard {
                                HStack(spacing: 14) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(entry.anime.title)
                                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                                            .foregroundStyle(theme.palette.textPrimary)
                                            .lineLimit(2)
                                        Text(L10n.episodeWithTitle(entry.episode.number, entry.episode.title))
                                            .font(theme.typography.caption)
                                            .foregroundStyle(theme.palette.textSecondary)
                                        Text(entry.releaseDate.formatted(date: .omitted, time: .shortened))
                                            .font(theme.typography.caption)
                                            .foregroundStyle(theme.palette.accent)
                                    }
                                    Spacer()
                                    VStack(spacing: 12) {
                                        Button {
                                            Task {
                                                try? await container.scheduleRepository.updateNotificationsEnabled(
                                                    for: entry.anime.id,
                                                    enabled: !entry.notificationsEnabled
                                                )
                                                await reload()
                                            }
                                        } label: {
                                            Image(systemName: entry.notificationsEnabled ? "bell.fill" : "bell.slash")
                                                .foregroundStyle(entry.notificationsEnabled ? theme.palette.accent : theme.palette.textSecondary)
                                        }
                                        NavigationLink(value: AppRoute.anime(entry.anime.id)) {
                                            Image(systemName: entry.isWatched ? "checkmark.circle.fill" : "play.circle.fill")
                                                .foregroundStyle(entry.isWatched ? theme.palette.positive : theme.palette.textPrimary)
                                                .font(.system(size: 24))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, theme.spacing.large)
            .padding(.top, theme.spacing.small)
            .padding(.bottom, 120)
        }
        .themedBackground()
        .navigationTitle("Schedule")
        .task {
            await reload()
        }
    }

    private func reload() async {
        await viewModel.load(
            scheduleRepository: container.scheduleRepository,
            libraryRepository: container.libraryRepository
        )
    }
}

#Preview {
    NavigationStack {
        ScheduleView()
    }
    .environmentObject(AppContainer.live)
    .environment(\.appTheme, ThemeManager.makeTheme(preset: .classicDark, accent: .violet, posterRadius: 26, density: .balanced))
}
