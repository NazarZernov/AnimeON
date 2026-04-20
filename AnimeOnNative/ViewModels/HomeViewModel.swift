import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var state: LoadableState<HomeDashboard> = .idle

    private let repository: AnimeRepositoryProtocol

    init(repository: AnimeRepositoryProtocol) {
        self.repository = repository
    }

    func load(refresh: Bool = false) async {
        state = .loading

        do {
            let dashboard = try await repository.dashboard(refresh: refresh)
            state = .loaded(dashboard)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
