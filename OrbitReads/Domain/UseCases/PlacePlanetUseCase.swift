import Foundation

struct PlacePlanetUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol

    init(repository: OrbitReadsBookRepositoryProtocol) {
        self.repository = repository
    }

    func execute(bookId: UUID) async throws -> OrbitReadsBook {
        guard var book = try await repository.fetch(by: bookId) else {
            throw OrbitReadsDomainError.bookNotFound
        }
        let sectors = try await repository.fetchSectors()
        let books = try await repository.fetchAll()
        let sessions = try await repository.fetchSessions(for: bookId)
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let pagesThisWeek = sessions.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.pagesRead }

        let sector = Self.resolveSector(for: book.genre, sectors: sectors)
        let siblings = books.filter { $0.author == book.author && $0.id != book.id }
        let (x, y) = Self.coordinates(
            author: book.author,
            bookId: book.id,
            sector: sector,
            siblingCount: siblings.count
        )
        book.sectorId = sector.id
        book.positionX = x
        book.positionY = y
        book.refreshOrbitRadius(pagesThisWeek: pagesThisWeek)
        book.fuelGenerated = book.currentPage * 2
        if book.planetClass.isEmpty {
            book.planetClass = OrbitReadsBook.defaultPlanetClass(from: book.flavorMeta, genre: book.genre)
        }
        try await repository.updatePlacement(
            bookId: book.id,
            positionX: book.positionX,
            positionY: book.positionY,
            sectorId: book.sectorId,
            orbitRadius: book.orbitRadius,
            fuelGenerated: book.fuelGenerated,
            planetClass: book.planetClass
        )
        return book
    }

    func placeNew(_ book: OrbitReadsBook, sectors: [GalaxySector], existing: [OrbitReadsBook]) -> OrbitReadsBook {
        var placed = book
        let sector = Self.resolveSector(for: book.genre, sectors: sectors)
        let siblings = existing.filter { $0.author == book.author }
        let (x, y) = Self.coordinates(
            author: book.author,
            bookId: book.id,
            sector: sector,
            siblingCount: siblings.count
        )
        placed.sectorId = sector.id
        placed.positionX = x
        placed.positionY = y
        placed.orbitRadius = OrbitReadsBook.computeOrbitRadius(totalPages: book.totalPages, pagesThisWeek: 0)
        placed.fuelGenerated = book.currentPage * 2
        if placed.planetClass.isEmpty {
            placed.planetClass = OrbitReadsBook.defaultPlanetClass(from: book.flavorMeta, genre: book.genre)
        }
        return placed
    }

    static func resolveSector(for genre: String, sectors: [GalaxySector]) -> GalaxySector {
        let key = genre.lowercased()
        if let match = sectors.first(where: { key.contains($0.genreKey.lowercased()) || $0.genreKey.lowercased().contains(key) }) {
            return match
        }
        if let unlocked = sectors.first(where: \.isUnlocked) { return unlocked }
        return sectors.first ?? GalaxySector(
            id: UUID(uuidString: "A0000001-0000-0000-0000-000000000001")!,
            name: "Core Nebula",
            genreKey: "general",
            hue: 0.55,
            centerX: 1200,
            centerY: 1200,
            radius: 420,
            isUnlocked: true
        )
    }

    static func coordinates(author: String, bookId: UUID, sector: GalaxySector, siblingCount: Int) -> (Double, Double) {
        let authorHash = abs(author.hashValue)
        let angle = Double(authorHash % 360) * .pi / 180
        let systemRadius = sector.radius * 0.35
        let systemX = sector.centerX + cos(angle) * systemRadius
        let systemY = sector.centerY + sin(angle) * systemRadius
        let bookHash = abs(bookId.hashValue)
        let orbitAngle = Double(bookHash % 360) * .pi / 180 + Double(siblingCount) * 0.7
        let orbit = 40 + Double(siblingCount) * 28
        return (systemX + cos(orbitAngle) * orbit, systemY + sin(orbitAngle) * orbit)
    }
}

enum OrbitReadsDomainError: Error, Sendable {
    case bookNotFound
    case sectorNotFound
    case expeditionNotFound
    case insufficientFuel
}
