import Foundation

@MainActor
final class UpdatesViewModel: ObservableObject {
    @Published var state: LoadableState<[UpdateItem]> = .idle

    private let service: any AnimeServicing

    init(service: any AnimeServicing) {
        self.service = service
    }

    func load() async {
        state = .loading

        do {
            let updates = try await service.fetchUpdates()
            state = updates.isEmpty ? .empty("Свежих обновлений пока нет.") : .loaded(updates)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
