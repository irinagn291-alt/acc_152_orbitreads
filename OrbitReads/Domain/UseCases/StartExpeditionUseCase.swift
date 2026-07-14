import Foundation

struct StartExpeditionUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol

    init(repository: OrbitReadsBookRepositoryProtocol) {
        self.repository = repository
    }

    func execute(expeditionId: UUID, routeBookIds: [UUID]) async throws -> Expedition {
        var expeditions = try await repository.fetchExpeditions()
        guard let index = expeditions.firstIndex(where: { $0.id == expeditionId }) else {
            throw OrbitReadsDomainError.expeditionNotFound
        }
        expeditions[index].routeBookIds = routeBookIds
        try await repository.saveExpedition(expeditions[index])
        return expeditions[index]
    }
}
