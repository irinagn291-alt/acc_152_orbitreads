import Foundation

enum PlacePlanetUseCaseTests {
    static func run() {
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
        precondition(placed.positionX != 0 || placed.positionY != 0)
        precondition(placed.sectorId == sector.id)
    }
}

enum ContributeFuelUseCaseTests {
    static func run() async throws {
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
        precondition(state.totalFuel >= 25)
        let updated = try await repo.fetchExpeditions().first { $0.id == expedition.id }
        precondition((updated?.fuelCollected ?? 0) >= 35)
    }
}
