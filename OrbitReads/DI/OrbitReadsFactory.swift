import CoreData
import SwiftUI

@MainActor
final class OrbitReadsFactory {
    static let shared = OrbitReadsFactory()

    let bookRepository: OrbitReadsBookRepositoryProtocol
    let openLibrary: OrbitReadsOpenLibraryClient
    let placePlanetUseCase: PlacePlanetUseCase
    let unlockSectorUseCase: UnlockSectorUseCase
    let contributeFuelUseCase: ContributeFuelUseCase
    let getFlightDeckUseCase: GetFlightDeckUseCase
    let startExpeditionUseCase: StartExpeditionUseCase
    let addBookUseCase: OrbitReadsAddBookUseCase
    let logPagesUseCase: OrbitReadsLogPagesUseCase
    let getStatsUseCase: OrbitReadsGetStatsUseCase
    let seedDataUseCase: OrbitReadsSeedDataUseCase
    let fetchBookRecommendationsUseCase: OrbitReadsFetchBookRecommendationsUseCase

    private init() {
        if let container = OrbitReadsPersistenceController.makeContainer() {
            bookRepository = OrbitReadsBookRepository(container: container)
        } else {
            bookRepository = OrbitReadsMemoryRepository()
        }
        openLibrary = OrbitReadsOpenLibraryClient()
        placePlanetUseCase = PlacePlanetUseCase(repository: bookRepository)
        unlockSectorUseCase = UnlockSectorUseCase(repository: bookRepository)
        contributeFuelUseCase = ContributeFuelUseCase(repository: bookRepository)
        getFlightDeckUseCase = GetFlightDeckUseCase(repository: bookRepository)
        startExpeditionUseCase = StartExpeditionUseCase(repository: bookRepository)
        addBookUseCase = OrbitReadsAddBookUseCase(repository: bookRepository, api: openLibrary, placePlanet: placePlanetUseCase)
        logPagesUseCase = OrbitReadsLogPagesUseCase(repository: bookRepository, contributeFuel: contributeFuelUseCase, placePlanet: placePlanetUseCase)
        getStatsUseCase = OrbitReadsGetStatsUseCase(repository: bookRepository)
        seedDataUseCase = OrbitReadsSeedDataUseCase(repository: bookRepository)
        fetchBookRecommendationsUseCase = OrbitReadsFetchBookRecommendationsUseCase(repository: bookRepository, api: openLibrary)
    }

    func makeCoordinator() -> OrbitReadsCoordinator {
        OrbitReadsCoordinator()
    }

    func bootstrap() async {
        await seedDataUseCase.executeIfNeeded()
    }
}
