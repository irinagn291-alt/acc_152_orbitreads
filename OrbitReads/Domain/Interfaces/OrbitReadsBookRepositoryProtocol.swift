import Foundation

protocol OrbitReadsBookRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [OrbitReadsBook]
    func fetchActive() async throws -> OrbitReadsBook?
    func fetch(by id: UUID) async throws -> OrbitReadsBook?
    func save(_ book: OrbitReadsBook) async throws
    func setActive(_ bookId: UUID) async throws
    func updateProgress(bookId: UUID, currentPage: Int) async throws
    func updatePlacement(bookId: UUID, positionX: Double, positionY: Double, sectorId: UUID, orbitRadius: Double, fuelGenerated: Int, planetClass: String) async throws
    func logSession(_ session: OrbitReadsReadingSession) async throws
    func fetchSessions(for bookId: UUID?) async throws -> [OrbitReadsReadingSession]
    func fetchSessions(from start: Date, to end: Date) async throws -> [OrbitReadsReadingSession]
    func fetchSectors() async throws -> [GalaxySector]
    func saveSector(_ sector: GalaxySector) async throws
    func fetchExpeditions() async throws -> [Expedition]
    func saveExpedition(_ expedition: Expedition) async throws
    func fetchOrbitState() async throws -> OrbitState
    func saveOrbitState(_ state: OrbitState) async throws
}

protocol OrbitReadsOpenLibraryAPIProtocol: Sendable {
    func fetchBook(isbn: String) async throws -> OrbitReadsOpenLibraryBook
    func fetchBook(isbns: [String]) async throws -> OrbitReadsOpenLibraryBook
    func fetchRecommendations(subjects: [String], limit: Int) async throws -> [OrbitReadsBookRecommendation]
    func coverURL(for isbn: String) -> URL
    func bestCoverURL(isbn: String, coverId: Int?) -> URL
    func coverURLs(isbn: String?, coverId: Int?, isbnCandidates: [String]) -> [URL]
    func sourceURL(isbn: String, workKey: String?) -> URL
}
