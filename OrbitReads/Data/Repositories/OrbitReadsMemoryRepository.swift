import Foundation

actor OrbitReadsMemoryRepository: OrbitReadsBookRepositoryProtocol {
    private var books: [UUID: OrbitReadsBook] = [:]
    private var sessions: [OrbitReadsReadingSession] = []
    private var sectors: [UUID: GalaxySector] = [:]
    private var expeditions: [UUID: Expedition] = [:]
    private var orbitState: OrbitState = .initial

    func fetchAll() async throws -> [OrbitReadsBook] {
        books.values.sorted { $0.dateAdded > $1.dateAdded }
    }

    func fetchActive() async throws -> OrbitReadsBook? {
        books.values.first(where: \.isActive)
    }

    func fetch(by id: UUID) async throws -> OrbitReadsBook? {
        books[id]
    }

    func save(_ book: OrbitReadsBook) async throws {
        books[book.id] = book
    }

    func setActive(_ bookId: UUID) async throws {
        for key in books.keys {
            books[key]?.isActive = (key == bookId)
        }
    }

    func updateProgress(bookId: UUID, currentPage: Int) async throws {
        books[bookId]?.currentPage = currentPage
        books[bookId]?.fuelGenerated = currentPage * 2
    }

    func updatePlacement(
        bookId: UUID,
        positionX: Double,
        positionY: Double,
        sectorId: UUID,
        orbitRadius: Double,
        fuelGenerated: Int,
        planetClass: String
    ) async throws {
        books[bookId]?.positionX = positionX
        books[bookId]?.positionY = positionY
        books[bookId]?.sectorId = sectorId
        books[bookId]?.orbitRadius = orbitRadius
        books[bookId]?.fuelGenerated = fuelGenerated
        books[bookId]?.planetClass = planetClass
    }

    func logSession(_ session: OrbitReadsReadingSession) async throws {
        sessions.append(session)
    }

    func fetchSessions(for bookId: UUID?) async throws -> [OrbitReadsReadingSession] {
        let filtered = bookId.map { id in sessions.filter { $0.bookId == id } } ?? sessions
        return filtered.sorted { $0.date > $1.date }
    }

    func fetchSessions(from start: Date, to end: Date) async throws -> [OrbitReadsReadingSession] {
        sessions.filter { $0.date >= start && $0.date <= end }
    }

    func fetchSectors() async throws -> [GalaxySector] {
        Array(sectors.values)
    }

    func saveSector(_ sector: GalaxySector) async throws {
        sectors[sector.id] = sector
    }

    func fetchExpeditions() async throws -> [Expedition] {
        Array(expeditions.values)
    }

    func saveExpedition(_ expedition: Expedition) async throws {
        expeditions[expedition.id] = expedition
    }

    func fetchOrbitState() async throws -> OrbitState {
        orbitState
    }

    func saveOrbitState(_ state: OrbitState) async throws {
        orbitState = state
    }
}
