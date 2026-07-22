import Foundation

enum OrbitReadsMockCatalog {
    static let coreSectorId = UUID(uuidString: "A0000001-0000-0000-0000-000000000001")!
    static let rimSectorId = UUID(uuidString: "A0000002-0000-0000-0000-000000000002")!
    static let voidSectorId = UUID(uuidString: "A0000003-0000-0000-0000-000000000003")!
    static let nebulaSectorId = UUID(uuidString: "A0000004-0000-0000-0000-000000000004")!
    static let expeditionId = UUID(uuidString: "E0000001-0000-0000-0000-000000000001")!

    private static func cover(_ isbn: String) -> URL? {
        URL(string: "https://covers.openlibrary.org/b/isbn/\(isbn)-L.jpg")
    }

    static let sectors: [GalaxySector] = [
        GalaxySector(id: coreSectorId, name: "Opera Core", genreKey: "space opera", hue: 0.55, centerX: 900, centerY: 1100, radius: 420, isUnlocked: true),
        GalaxySector(id: rimSectorId, name: "Hard Rim", genreKey: "hard sf", hue: 0.62, centerX: 1700, centerY: 900, radius: 380, isUnlocked: true),
        GalaxySector(id: voidSectorId, name: "Ash Void", genreKey: "dystopia", hue: 0.78, centerX: 1300, centerY: 1750, radius: 400, isUnlocked: false),
        GalaxySector(id: nebulaSectorId, name: "Myth Nebula", genreKey: "fantasy", hue: 0.42, centerX: 600, centerY: 1600, radius: 360, isUnlocked: true)
    ]

    static let foundation = OrbitReadsBook(
        id: UUID(uuidString: "D0000001-0000-0000-0000-000000000001")!,
        isbn: "9780553293357", title: "Foundation", author: "Isaac Asimov",
        coverURL: cover("9780553293357"), genre: "Space Opera", totalPages: 244, currentPage: 180,
        dateAdded: daysAgo(20), isActive: true, flavorMeta: "Desert World", planetClass: "Desert World",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 244, pagesThisWeek: 35),
        fuelGenerated: 360, sectorId: coreSectorId, positionX: 820, positionY: 1040
    )
    static let odyssey = OrbitReadsBook(
        id: UUID(uuidString: "D0000002-0000-0000-0000-000000000002")!,
        isbn: "9780451178495", title: "2001: A Space Odyssey", author: "Arthur C. Clarke",
        coverURL: cover("9780451178495"), genre: "Hard SF", totalPages: 224, currentPage: 224,
        dateAdded: daysAgo(40), isActive: false, flavorMeta: "Monolith Station", planetClass: "Monolith Station",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 224, pagesThisWeek: 0),
        fuelGenerated: 448, sectorId: rimSectorId, positionX: 1580, positionY: 820
    )
    static let hyperion = OrbitReadsBook(
        id: UUID(uuidString: "D0000003-0000-0000-0000-000000000003")!,
        isbn: "9780553283686", title: "Hyperion", author: "Dan Simmons",
        coverURL: cover("9780553283686"), genre: "Space Opera", totalPages: 482, currentPage: 95,
        dateAdded: daysAgo(8), isActive: false, flavorMeta: "Gas Giant", planetClass: "Gas Giant",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 482, pagesThisWeek: 28),
        fuelGenerated: 190, sectorId: coreSectorId, positionX: 980, positionY: 1180
    )
    static let leftHand = OrbitReadsBook(
        id: UUID(uuidString: "D0000004-0000-0000-0000-000000000004")!,
        isbn: "9780441478125", title: "The Left Hand of Darkness", author: "Ursula K. Le Guin",
        coverURL: cover("9780441478125"), genre: "Hard SF", totalPages: 304, currentPage: 140,
        dateAdded: daysAgo(16), isActive: false, flavorMeta: "Ice World", planetClass: "Ice World",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 304, pagesThisWeek: 20),
        fuelGenerated: 280, sectorId: rimSectorId, positionX: 1750, positionY: 980
    )
    static let neuromancer = OrbitReadsBook(
        id: UUID(uuidString: "D0000005-0000-0000-0000-000000000005")!,
        isbn: "9780441569595", title: "Neuromancer", author: "William Gibson",
        coverURL: cover("9780441569595"), genre: "Dystopia", totalPages: 271, currentPage: 0,
        dateAdded: daysAgo(25), isActive: false, flavorMeta: "Ash World", planetClass: "Ash World",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 271, pagesThisWeek: 0),
        fuelGenerated: 0, sectorId: voidSectorId, positionX: 1220, positionY: 1680
    )
    static let dune = OrbitReadsBook(
        id: UUID(uuidString: "D0000006-0000-0000-0000-000000000006")!,
        isbn: "9780441172719", title: "Dune", author: "Frank Herbert",
        coverURL: cover("9780441172719"), genre: "Space Opera", totalPages: 688, currentPage: 220,
        dateAdded: daysAgo(30), isActive: false, flavorMeta: "Desert World", planetClass: "Desert World",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 688, pagesThisWeek: 40),
        fuelGenerated: 440, sectorId: coreSectorId, positionX: 760, positionY: 1220
    )
    static let ender = OrbitReadsBook(
        id: UUID(uuidString: "D0000007-0000-0000-0000-000000000007")!,
        isbn: "9780812550702", title: "Ender's Game", author: "Orson Scott Card",
        coverURL: cover("9780812550702"), genre: "Hard SF", totalPages: 324, currentPage: 180,
        dateAdded: daysAgo(12), isActive: false, flavorMeta: "Battle School", planetClass: "Monolith Station",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 324, pagesThisWeek: 22),
        fuelGenerated: 360, sectorId: rimSectorId, positionX: 1650, positionY: 1050
    )
    static let dispossessed = OrbitReadsBook(
        id: UUID(uuidString: "D0000008-0000-0000-0000-000000000008")!,
        isbn: "9780061054884", title: "The Dispossessed", author: "Ursula K. Le Guin",
        coverURL: cover("9780061054884"), genre: "Dystopia", totalPages: 387, currentPage: 50,
        dateAdded: daysAgo(9), isActive: false, flavorMeta: "Anarres", planetClass: "Ash World",
        orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: 387, pagesThisWeek: 12),
        fuelGenerated: 100, sectorId: nebulaSectorId, positionX: 540, positionY: 1520
    )

    static let books = [
        foundation, odyssey, hyperion, leftHand, neuromancer, dune, ender, dispossessed
    ]

    static let expeditions: [Expedition] = [
        Expedition(
            id: expeditionId,
            name: "Ash Void Crossing",
            targetSectorId: voidSectorId,
            fuelRequired: 200,
            fuelCollected: 80,
            routeBookIds: [foundation.id, hyperion.id, dune.id],
            isUnlocked: false
        )
    ]

    static let orbitState = OrbitState(
        totalFuel: 2218,
        expeditionFuel: 80,
        lightYears: 18.4,
        warpJumps: 6,
        unlockedSectorIds: [coreSectorId, rimSectorId, nebulaSectorId]
    )

    static func sessions() -> [OrbitReadsReadingSession] {
        let cal = Calendar.current
        return [
            OrbitReadsReadingSession(id: UUID(), bookId: foundation.id, date: cal.date(byAdding: .day, value: -1, to: Date())!, pagesRead: 35, duration: 2400, flavorMeta: "Warp 3"),
            OrbitReadsReadingSession(id: UUID(), bookId: hyperion.id, date: cal.date(byAdding: .day, value: -2, to: Date())!, pagesRead: 28, duration: 2100, flavorMeta: "Orbit stable"),
            OrbitReadsReadingSession(id: UUID(), bookId: foundation.id, date: cal.date(byAdding: .day, value: -4, to: Date())!, pagesRead: 40, duration: 2700, flavorMeta: "Fuel transfer"),
            OrbitReadsReadingSession(id: UUID(), bookId: dune.id, date: cal.date(byAdding: .day, value: -3, to: Date())!, pagesRead: 40, duration: 2800, flavorMeta: "Spice burn"),
            OrbitReadsReadingSession(id: UUID(), bookId: leftHand.id, date: cal.date(byAdding: .day, value: -5, to: Date())!, pagesRead: 20, duration: 1600, flavorMeta: "Ice skim"),
            OrbitReadsReadingSession(id: UUID(), bookId: ender.id, date: cal.date(byAdding: .day, value: -6, to: Date())!, pagesRead: 22, duration: 1700, flavorMeta: "Battle sim"),
            OrbitReadsReadingSession(id: UUID(), bookId: dispossessed.id, date: cal.date(byAdding: .day, value: -7, to: Date())!, pagesRead: 12, duration: 1100, flavorMeta: "Nebula dock")
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
        let existing = (try? await repository.fetchAll()) ?? []

        for sector in OrbitReadsMockCatalog.sectors {
            try? await repository.saveSector(sector)
        }

        if existing.isEmpty {
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
            return
        }

        let ids = Set(existing.map(\.id))
        for book in OrbitReadsMockCatalog.books where !ids.contains(book.id) {
            try? await repository.save(book)
        }
        UserDefaults.standard.set(true, forKey: OrbitReadsMetadata.seedKey)
    }
}
