import Foundation

struct ContributeFuelUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol

    init(repository: OrbitReadsBookRepositoryProtocol) {
        self.repository = repository
    }

    func execute(amount: Int, expeditionId: UUID? = nil, source: FuelSource = .reading) async throws -> OrbitState {
        guard amount > 0 else { return try await repository.fetchOrbitState() }
        var state = try await repository.fetchOrbitState()
        state.totalFuel += amount
        state.expeditionFuel += amount
        state.lightYears = Double(state.totalFuel) * 0.01
        try await repository.saveOrbitState(state)

        var expeditions = try await repository.fetchExpeditions()
        let targetId = expeditionId ?? expeditions.first(where: { !$0.isUnlocked })?.id
        if let targetId, let idx = expeditions.firstIndex(where: { $0.id == targetId }) {
            expeditions[idx].fuelCollected += amount
            if source == .asteroidBonus {
                expeditions[idx].fuelCollected += max(0, amount / 2)
            }
            try await repository.saveExpedition(expeditions[idx])
        }
        return try await repository.fetchOrbitState()
    }
}

enum FuelSource: Sendable {
    case reading
    case asteroidBonus
}
