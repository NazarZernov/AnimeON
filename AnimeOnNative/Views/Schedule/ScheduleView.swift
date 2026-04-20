import SwiftUI

struct ScheduleView: View {
    @StateObject private var viewModel: ScheduleViewModel
    @Binding private var selectedSection: AppSection

    init(repository: AnimeRepositoryProtocol, selectedSection: Binding<AppSection>) {
        _viewModel = StateObject(wrappedValue: ScheduleViewModel(repository: repository))
        _selectedSection = selectedSection
    }

    var body: some View {
        ScreenContainer(
            selectedSection: $selectedSection,
            currentSection: .schedule,
            title: "Календарь релизов",
            subtitle: AppSection.schedule.subtitle,
            onRefresh: {
                await viewModel.load(refresh: true)
            }
        ) {
            switch viewModel.state {
            case .idle, .loading:
                LoadingStateView(message: "Собираем расписание выхода серий...")

            case let .failed(message):
                MessageStateView(title: "Расписание недоступно", message: message, actionTitle: "Повторить") {
                    Task { await viewModel.load() }
                }

            case let .empty(message):
                MessageStateView(title: "Пока пусто", message: message, actionTitle: nil, action: nil)

            case let .loaded(days):
                VStack(alignment: .leading, spacing: 18) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(days) { day in
                                Button {
                                    withAnimation(.snappy) {
                                        viewModel.selectedDayID = day.id
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(day.shortWeekday)
                                            .font(.system(size: 12, weight: .bold))
                                        Text(day.shortDateLabel)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundStyle(viewModel.selectedDayID == day.id ? .white : AppTheme.textSecondary)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(viewModel.selectedDayID == day.id ? AppTheme.accent : AppTheme.surface.opacity(0.96))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if let selectedDay = days.first(where: { $0.id == viewModel.selectedDayID }) {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeaderView(title: "\(selectedDay.shortWeekday), \(selectedDay.shortDateLabel)", subtitle: "\(selectedDay.releases.count) релизов")

                            ForEach(selectedDay.releases) { release in
                                HStack(spacing: 14) {
                                    Text(release.releaseTime)
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(AppTheme.accent)
                                        .frame(width: 64)

                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(release.animeTitle)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(AppTheme.textPrimary)

                                        Text("Серия \(release.episodeNumber) • \(release.statusText)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }

                                    Spacer()

                                    if let rating = release.rating {
                                        Text(String(format: "%.1f", rating))
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(Capsule(style: .continuous).fill(AppTheme.warning))
                                    }
                                }
                                .padding(16)
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
                    }
                }
            }
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
    }
}
