import Foundation

struct UnlockSectorUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol

    init(repository: OrbitReadsBookRepositoryProtocol) {
        self.repository = repository
    }

    func execute(expeditionId: UUID) async throws -> (Expedition, GalaxySector) {
        var expeditions = try await repository.fetchExpeditions()
        guard let index = expeditions.firstIndex(where: { $0.id == expeditionId }) else {
            throw OrbitReadsDomainError.expeditionNotFound
        }
        var expedition = expeditions[index]
        guard expedition.isReady else { throw OrbitReadsDomainError.insufficientFuel }

        var sectors = try await repository.fetchSectors()
        guard let sectorIndex = sectors.firstIndex(where: { $0.id == expedition.targetSectorId }) else {
            throw OrbitReadsDomainError.sectorNotFound
        }
        sectors[sectorIndex].isUnlocked = true
        expedition.isUnlocked = true
        expeditions[index] = expedition

        var state = try await repository.fetchOrbitState()
        if !state.unlockedSectorIds.contains(expedition.targetSectorId) {
            state.unlockedSectorIds.append(expedition.targetSectorId)
        }
        state.warpJumps += 1
        state.lightYears += Double(expedition.fuelRequired) * 0.02

        try await repository.saveSector(sectors[sectorIndex])
        try await repository.saveExpedition(expedition)
        try await repository.saveOrbitState(state)
        return (expedition, sectors[sectorIndex])
    }
}
