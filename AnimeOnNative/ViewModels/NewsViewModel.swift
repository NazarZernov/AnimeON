import Foundation

@MainActor
final class NewsViewModel: ObservableObject {
    @Published var state: LoadableState<[NewsItem]> = .idle

    private let service: any AnimeServicing

    init(service: any AnimeServicing) {
        self.service = service
    }

    func load() async {
        state = .loading

        do {
            let items = try await service.fetchNews()
            state = items.isEmpty ? .empty("Новостей пока нет.") : .loaded(items)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
