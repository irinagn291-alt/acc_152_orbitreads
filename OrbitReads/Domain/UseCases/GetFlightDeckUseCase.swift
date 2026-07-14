import Foundation

struct GetFlightDeckUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol

    init(repository: OrbitReadsBookRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> FlightDeckSnapshot {
        let books = try await repository.fetchAll()
        let state = try await repository.fetchOrbitState()
        let sessions = try await repository.fetchSessions(for: nil)
        let fuelFromReading = sessions.reduce(0) { $0 + $1.pagesRead }
        let totalFuel = max(state.totalFuel, fuelFromReading)
        return FlightDeckSnapshot(
            totalFuel: totalFuel,
            expeditionFuel: state.expeditionFuel,
            lightYears: max(state.lightYears, Double(totalFuel) * 0.01),
            warpJumps: max(state.warpJumps, books.count),
            habitableWorlds: books.filter { $0.progress >= 1.0 }.count
        )
    }
}
