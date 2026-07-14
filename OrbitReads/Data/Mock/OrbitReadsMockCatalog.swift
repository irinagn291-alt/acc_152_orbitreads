import Foundation

enum OrbitReadsMockCatalog {
    static let coreSectorId = UUID(uuidString: "A0000001-0000-0000-0000-000000000001")!
    static let rimSectorId = UUID(uuidString: "A0000002-0000-0000-0000-000000000002")!
    static let voidSectorId = UUID(uuidString: "A0000003-0000-0000-0000-000000000003")!
    static let expeditionId = UUID(uuidString: "E0000001-0000-0000-0000-000000000001")!

    static let sectors: [GalaxySector] = [
        GalaxySector(id: coreSectorId, name: "Opera Core", genreKey: "space opera", hue: 0.55, centerX: 900, centerY: 1100, radius: 380, isUnlocked: true),
        GalaxySector(id: rimSectorId, name: "Hard Rim", genreKey: "hard sf", hue: 0.62, centerX: 1600, centerY: 900, radius: 340, isUnlocked: true),
        GalaxySector(id: voidSectorId, name: "Ash Void", genreKey: "dystopia", hue: 0.78, centerX: 1300, centerY: 1700, radius: 360, isUnlocked: false)
    ]

    static let foundation = OrbitReadsBook(
        id: UUID(uuidString: "D0000001-0000-0000-0000-000000000001")!,
        isbn: "9780553293357", title: "Foundation", author: "Isaac Asimov",
        coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9780553293357-L.jpg"),
        genre: "Space Opera", totalPages: 244, currentPage: 180, dateAdded: daysAgo(20), isActive: true,
        flavorMeta: "Desert World", planetClass: "Desert World",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 244, pagesThisWeek: 35),
        fuelGenerated: 360, sectorId: coreSectorId, positionX: 820, positionY: 1040
    )
    static let odyssey = OrbitReadsBook(
        id: UUID(uuidString: "D0000002-0000-0000-0000-000000000002")!,
        isbn: "9780451178495", title: "2001: A Space Odyssey", author: "Arthur C. Clarke",
        coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9780451178495-L.jpg"),
        genre: "Hard SF", totalPages: 224, currentPage: 224, dateAdded: daysAgo(40), isActive: false,
        flavorMeta: "Monolith Station", planetClass: "Monolith Station",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 224, pagesThisWeek: 0),
        fuelGenerated: 448, sectorId: rimSectorId, positionX: 1520, positionY: 860
    )
    static let hyperion = OrbitReadsBook(
        id: UUID(uuidString: "D0000003-0000-0000-0000-000000000003")!,
        isbn: "9780553283686", title: "Hyperion", author: "Dan Simmons",
        coverURL: URL(string: "https://covers.openlibrary.org/b/isbn/9780553283686-L.jpg"),
        genre: "Space Opera", totalPages: 482, currentPage: 95, dateAdded: daysAgo(8), isActive: false,
        flavorMeta: "Gas Giant", planetClass: "Gas Giant",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 482, pagesThisWeek: 28),
        fuelGenerated: 190, sectorId: coreSectorId, positionX: 980, positionY: 1180
    )
    static let books = [foundation, odyssey, hyperion]

    static let expeditions: [Expedition] = [
        Expedition(
            id: expeditionId,
            name: "Ash Void Crossing",
            targetSectorId: voidSectorId,
            fuelRequired: 200,
            fuelCollected: 80,
            routeBookIds: [foundation.id, hyperion.id],
            isUnlocked: false
        )
    ]

    static let orbitState = OrbitState(
        totalFuel: 998,
        expeditionFuel: 80,
        lightYears: 9.98,
        warpJumps: 3,
        unlockedSectorIds: [coreSectorId, rimSectorId]
    )

    static func sessions() -> [OrbitReadsReadingSession] {
        let cal = Calendar.current
        return [
            OrbitReadsReadingSession(id: UUID(), bookId: foundation.id, date: cal.date(byAdding: .day, value: -1, to: Date())!, pagesRead: 35, duration: 2400, flavorMeta: "Warp 3"),
            OrbitReadsReadingSession(id: UUID(), bookId: hyperion.id, date: cal.date(byAdding: .day, value: -2, to: Date())!, pagesRead: 28, duration: 2100, flavorMeta: "Orbit stable"),
            OrbitReadsReadingSession(id: UUID(), bookId: foundation.id, date: cal.date(byAdding: .day, value: -4, to: Date())!, pagesRead: 40, duration: 2700, flavorMeta: "Fuel transfer"),
        ]
    }

    private static func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Date()) ?? Date()
    }
}

struct OrbitReadsSeedDataUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol

    init(repository: OrbitReadsBookRepositoryProtocol) {
        self.repository = repository
    }

    func executeIfNeeded() async {
        guard !UserDefaults.standard.bool(forKey: OrbitReadsMetadata.seedKey) else { return }
        let existing = (try? await repository.fetchAll()) ?? []
        if !existing.isEmpty {
            UserDefaults.standard.set(true, forKey: OrbitReadsMetadata.seedKey)
            return
        }
        for sector in OrbitReadsMockCatalog.sectors {
            try? await repository.saveSector(sector)
        }
        for book in OrbitReadsMockCatalog.books {
            try? await repository.save(book)
        }
        for session in OrbitReadsMockCatalog.sessions() {
            try? await repository.logSession(session)
        }
        for expedition in OrbitReadsMockCatalog.expeditions {
            try? await repository.saveExpedition(expedition)
        }
        try? await repository.saveOrbitState(OrbitReadsMockCatalog.orbitState)
        UserDefaults.standard.set(true, forKey: OrbitReadsMetadata.seedKey)
    }
}
