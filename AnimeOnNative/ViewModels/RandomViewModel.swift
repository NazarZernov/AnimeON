import Foundation

@MainActor
final class RandomViewModel: ObservableObject {
    @Published var state: LoadableState<Anime> = .idle

    private let service: any AnimeServicing

    init(service: any AnimeServicing) {
        self.service = service
    }

    func loadRandom() async {
        state = .loading

        do {
            let anime = try await service.randomAnime()
            state = .loaded(anime)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
