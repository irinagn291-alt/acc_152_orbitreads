import CoreData

final class OrbitReadsBookRepository: OrbitReadsBookRepositoryProtocol, @unchecked Sendable {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    private var context: NSManagedObjectContext { container.viewContext }

    func fetchAll() async throws -> [OrbitReadsBook] {
        try await perform {
            let request = NSFetchRequest<OrbitReadsBookEntity>(entityName: "OrbitReadsBookEntity")
            request.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: false)]
            return try self.context.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func fetchActive() async throws -> OrbitReadsBook? {
        try await perform {
            let request = NSFetchRequest<OrbitReadsBookEntity>(entityName: "OrbitReadsBookEntity")
            request.predicate = NSPredicate(format: "isActive == YES")
            request.fetchLimit = 1
            return try self.context.fetch(request).first?.toDomain()
        }
    }

    func fetch(by id: UUID) async throws -> OrbitReadsBook? {
        try await perform {
            let request = NSFetchRequest<OrbitReadsBookEntity>(entityName: "OrbitReadsBookEntity")
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            return try self.context.fetch(request).first?.toDomain()
        }
    }

    func save(_ book: OrbitReadsBook) async throws {
        try await perform {
            let request = NSFetchRequest<OrbitReadsBookEntity>(entityName: "OrbitReadsBookEntity")
            request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
            let entity = try self.context.fetch(request).first ?? OrbitReadsBookEntity(context: self.context)
            entity.apply(book)
            try self.context.save()
        }
    }

    func setActive(_ bookId: UUID) async throws {
        try await perform {
            let all = NSFetchRequest<OrbitReadsBookEntity>(entityName: "OrbitReadsBookEntity")
            let books = try self.context.fetch(all)
            books.forEach { $0.isActive = ($0.id == bookId) }
            try self.context.save()
        }
    }

    func updateProgress(bookId: UUID, currentPage: Int) async throws {
        try await perform {
            let request = NSFetchRequest<OrbitReadsBookEntity>(entityName: "OrbitReadsBookEntity")
            request.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
            guard let entity = try self.context.fetch(request).first else { return }
            entity.currentPage = Int32(currentPage)
            entity.fuelGenerated = Int32(currentPage * 2)
            try self.context.save()
        }
    }

    func updatePlacement(bookId: UUID, positionX: Double, positionY: Double, sectorId: UUID, orbitRadius: Double, fuelGenerated: Int, planetClass: String) async throws {
        try await perform {
            let request = NSFetchRequest<OrbitReadsBookEntity>(entityName: "OrbitReadsBookEntity")
            request.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
            guard let entity = try self.context.fetch(request).first else { return }
            entity.positionX = positionX
            entity.positionY = positionY
            entity.sectorId = sectorId
            entity.orbitRadius = orbitRadius
            entity.fuelGenerated = Int32(fuelGenerated)
            entity.planetClass = planetClass
            try self.context.save()
        }
    }

    func logSession(_ session: OrbitReadsReadingSession) async throws {
        try await perform {
            let entity = OrbitReadsSessionEntity(context: self.context)
            entity.id = session.id
            entity.bookId = session.bookId
            entity.date = session.date
            entity.pagesRead = Int32(session.pagesRead)
            entity.duration = session.duration
            entity.flavorMeta = session.flavorMeta
            try self.context.save()
        }
    }

    func fetchSessions(for bookId: UUID?) async throws -> [OrbitReadsReadingSession] {
        try await perform {
            let request = NSFetchRequest<OrbitReadsSessionEntity>(entityName: "OrbitReadsSessionEntity")
            if let bookId {
                request.predicate = NSPredicate(format: "bookId == %@", bookId as CVarArg)
            }
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
            return try self.context.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func fetchSessions(from start: Date, to end: Date) async throws -> [OrbitReadsReadingSession] {
        try await perform {
            let request = NSFetchRequest<OrbitReadsSessionEntity>(entityName: "OrbitReadsSessionEntity")
            request.predicate = NSPredicate(format: "date >= %@ AND date <= %@", start as NSDate, end as NSDate)
            return try self.context.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func fetchSectors() async throws -> [GalaxySector] {
        try await perform {
            let request = NSFetchRequest<SectorEntity>(entityName: "SectorEntity")
            return try self.context.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func saveSector(_ sector: GalaxySector) async throws {
        try await perform {
            let request = NSFetchRequest<SectorEntity>(entityName: "SectorEntity")
            request.predicate = NSPredicate(format: "id == %@", sector.id as CVarArg)
            let entity = try self.context.fetch(request).first ?? SectorEntity(context: self.context)
            entity.apply(sector)
            try self.context.save()
        }
    }

    func fetchExpeditions() async throws -> [Expedition] {
        try await perform {
            let request = NSFetchRequest<ExpeditionEntity>(entityName: "ExpeditionEntity")
            return try self.context.fetch(request).compactMap { $0.toDomain() }
        }
    }

    func saveExpedition(_ expedition: Expedition) async throws {
        try await perform {
            let request = NSFetchRequest<ExpeditionEntity>(entityName: "ExpeditionEntity")
            request.predicate = NSPredicate(format: "id == %@", expedition.id as CVarArg)
            let entity = try self.context.fetch(request).first ?? ExpeditionEntity(context: self.context)
            entity.apply(expedition)
            try self.context.save()
        }
    }

    func fetchOrbitState() async throws -> OrbitState {
        try await perform {
            let request = NSFetchRequest<OrbitStateEntity>(entityName: "OrbitStateEntity")
            request.fetchLimit = 1
            if let entity = try self.context.fetch(request).first {
                return entity.toDomain()
            }
            return OrbitState.initial
        }
    }

    func saveOrbitState(_ state: OrbitState) async throws {
        try await perform {
            let request = NSFetchRequest<OrbitStateEntity>(entityName: "OrbitStateEntity")
            request.fetchLimit = 1
            let entity = try self.context.fetch(request).first ?? OrbitStateEntity(context: self.context)
            entity.apply(state)
            try self.context.save()
        }
    }

    private func perform<T>(_ work: @escaping () throws -> T) async throws -> T {
        try await context.perform {
            try work()
        }
    }
}
