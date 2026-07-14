import Foundation

struct OrbitReadsAddBookUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol
    private let api: OrbitReadsOpenLibraryAPIProtocol
    private let placePlanet: PlacePlanetUseCase

    init(repository: OrbitReadsBookRepositoryProtocol, api: OrbitReadsOpenLibraryAPIProtocol, placePlanet: PlacePlanetUseCase) {
        self.repository = repository
        self.api = api
        self.placePlanet = placePlanet
    }

    func execute(isbn: String) async throws -> OrbitReadsBook {
        let normalized = isbn.uppercased().filter { $0.isNumber || $0 == "X" }
        let metadata = try await api.fetchBook(isbn: normalized)
        return try await save(metadata: metadata, isbn: normalized)
    }

    func execute(recommendation: OrbitReadsBookRecommendation) async throws -> OrbitReadsBook {
        let candidates = recommendation.isbnCandidates.isEmpty
            ? (recommendation.isbn.map { [$0] } ?? [])
            : recommendation.isbnCandidates
        guard !candidates.isEmpty else { throw OrbitReadsOpenLibraryError.notFound }

        var lastError: Error = OrbitReadsOpenLibraryError.notFound
        for isbn in candidates {
            do { return try await execute(isbn: isbn) }
            catch { lastError = error }
        }
        throw lastError
    }

    private func save(metadata: OrbitReadsOpenLibraryBook, isbn: String) async throws -> OrbitReadsBook {
        let genre = metadata.subjects?.first ?? "General"
        let code = String(genre.prefix(2)).capitalized + "-\(Int.random(in: 10...99))"
        let sectors = try await repository.fetchSectors()
        let existing = try await repository.fetchAll()
        var book = OrbitReadsBook(
            id: UUID(),
            isbn: isbn,
            title: metadata.title ?? "Unknown Title",
            author: metadata.authors?.first ?? "Unknown Author",
            coverURL: api.bestCoverURL(isbn: isbn, coverId: metadata.coverId),
            genre: genre,
            totalPages: metadata.numberOfPages ?? 300,
            currentPage: 0,
            dateAdded: Date(),
            isActive: true,
            flavorMeta: code,
            planetClass: OrbitReadsBook.defaultPlanetClass(from: code, genre: genre),
            orbitRadius: OrbitReadsBook.computeOrbitRadius(totalPages: metadata.numberOfPages ?? 300, pagesThisWeek: 0),
            fuelGenerated: 0,
            sectorId: UUID(),
            positionX: 0,
            positionY: 0
        )
        book = placePlanet.placeNew(book, sectors: sectors, existing: existing)
        try await repository.save(book)
        try await repository.setActive(book.id)
        var state = try await repository.fetchOrbitState()
        state.warpJumps += 1
        try await repository.saveOrbitState(state)
        return book
    }
}
