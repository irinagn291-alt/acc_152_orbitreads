import XCTest
@testable import OrbitReads

@MainActor
final class PlacePlanetUseCaseTests: XCTestCase {
    func testPlaceNewAssignsSectorAndCoordinates() {
        let sector = GalaxySector(
            id: UUID(),
            name: "Sci Sector",
            genreKey: "science",
            hue: 0.5,
            centerX: 1000,
            centerY: 1000,
            radius: 400,
            isUnlocked: true
        )
        let book = OrbitReadsBook(
            id: UUID(),
            isbn: "978",
            title: "Foundation",
            author: "Asimov",
            coverURL: nil,
            genre: "science fiction",
            totalPages: 250,
            currentPage: 40,
            dateAdded: Date(),
            isActive: true,
            flavorMeta: "Class-M",
            planetClass: "",
            orbitRadius: 0,
            fuelGenerated: 0,
            sectorId: UUID(),
            positionX: 0,
            positionY: 0
        )
        let placed = PlacePlanetUseCase(repository: OrbitReadsMemoryRepository()).placeNew(
            book,
            sectors: [sector],
            existing: []
        )
        XCTAssertEqual(placed.sectorId, sector.id)
        XCTAssertTrue(placed.positionX != 0 || placed.positionY != 0)
        XCTAssertGreaterThan(placed.orbitRadius, 0)
        XCTAssertFalse(placed.planetClass.isEmpty)
    }
}

@MainActor
final class ContributeFuelUseCaseTests: XCTestCase {
    func testContributeFuelUpdatesStateAndExpedition() async throws {
        let repo = OrbitReadsMemoryRepository()
        let sectorId = UUID()
        let expedition = Expedition(
            id: UUID(),
            name: "Outer Rim",
            targetSectorId: sectorId,
            fuelRequired: 100,
            fuelCollected: 10,
            routeBookIds: [],
            isUnlocked: false
        )
        try await repo.saveExpedition(expedition)
        let useCase = ContributeFuelUseCase(repository: repo)
        let state = try await useCase.execute(amount: 25, expeditionId: expedition.id)
        XCTAssertGreaterThanOrEqual(state.totalFuel, 25)
        let updated = try await repo.fetchExpeditions().first { $0.id == expedition.id }
        XCTAssertEqual(updated?.fuelCollected, 35)
    }

    func testAsteroidBonusAddsExtraFuel() async throws {
        let repo = OrbitReadsMemoryRepository()
        let expedition = Expedition(
            id: UUID(),
            name: "Bonus Run",
            targetSectorId: UUID(),
            fuelRequired: 200,
            fuelCollected: 0,
            routeBookIds: [],
            isUnlocked: false
        )
        try await repo.saveExpedition(expedition)
        let useCase = ContributeFuelUseCase(repository: repo)
        _ = try await useCase.execute(amount: 20, expeditionId: expedition.id, source: .asteroidBonus)
        let updated = try await repo.fetchExpeditions().first { $0.id == expedition.id }
        XCTAssertEqual(updated?.fuelCollected, 30)
    }
}
