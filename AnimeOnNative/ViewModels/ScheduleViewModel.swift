import Foundation

@MainActor
final class ScheduleViewModel: ObservableObject {
    @Published var state: LoadableState<[ScheduleDay]> = .idle
    @Published var selectedDayID: UUID?

    private let repository: AnimeRepositoryProtocol

    init(repository: AnimeRepositoryProtocol) {
        self.repository = repository
    }

    func load(refresh: Bool = false) async {
        state = .loading

        do {
            let days = try await repository.schedule(refresh: refresh)
            selectedDayID = selectedDayID ?? days.first?.id
            state = days.isEmpty ? .empty("Календарь пока пуст.") : .loaded(days)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
