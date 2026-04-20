import Foundation

@MainActor
final class PremiumViewModel: ObservableObject {
    @Published var state: LoadableState<[PremiumPlan]> = .idle

    private let service: any AnimeServicing

    init(service: any AnimeServicing) {
        self.service = service
    }

    func load() async {
        state = .loading

        do {
            let plans = try await service.fetchPremiumPlans()
            state = plans.isEmpty ? .empty("Планы подписки временно недоступны.") : .loaded(plans)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
