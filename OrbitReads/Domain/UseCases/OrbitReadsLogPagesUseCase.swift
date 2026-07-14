import Foundation

struct OrbitReadsLogPagesUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol
    private let contributeFuel: ContributeFuelUseCase
    private let placePlanet: PlacePlanetUseCase

    init(repository: OrbitReadsBookRepositoryProtocol, contributeFuel: ContributeFuelUseCase, placePlanet: PlacePlanetUseCase) {
        self.repository = repository
        self.contributeFuel = contributeFuel
        self.placePlanet = placePlanet
    }

    func execute(bookId: UUID, pages: Int, date: Date = Date()) async throws {
        guard pages > 0 else { return }
        guard let book = try await repository.fetch(by: bookId) else { return }
        let newPage = min(book.currentPage + pages, book.totalPages)
        try await repository.updateProgress(bookId: bookId, currentPage: newPage)
        let session = OrbitReadsReadingSession(
            id: UUID(),
            bookId: bookId,
            date: date,
            pagesRead: pages,
            duration: 0,
            flavorMeta: "Fuel +\(pages)"
        )
        try await repository.logSession(session)
        _ = try await contributeFuel.execute(amount: pages, source: .reading)
        _ = try await placePlanet.execute(bookId: bookId)
    }
}
