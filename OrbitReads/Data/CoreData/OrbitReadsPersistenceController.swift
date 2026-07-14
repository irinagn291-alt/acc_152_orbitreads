import CoreData

enum OrbitReadsPersistenceController {
    static func makeContainer(storeName: String = "OrbitReads") -> NSPersistentContainer? {
        let model = makeModel()
        let container = NSPersistentContainer(name: storeName, managedObjectModel: model)
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        if loadError != nil { return nil }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        let bookEntity = NSEntityDescription()
        bookEntity.name = "OrbitReadsBookEntity"
        bookEntity.managedObjectClassName = "OrbitReadsBookEntity"
        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "OrbitReadsSessionEntity"
        sessionEntity.managedObjectClassName = "OrbitReadsSessionEntity"
        let sectorEntity = NSEntityDescription()
        sectorEntity.name = "SectorEntity"
        sectorEntity.managedObjectClassName = "SectorEntity"
        let expeditionEntity = NSEntityDescription()
        expeditionEntity.name = "ExpeditionEntity"
        expeditionEntity.managedObjectClassName = "ExpeditionEntity"
        let orbitStateEntity = NSEntityDescription()
        orbitStateEntity.name = "OrbitStateEntity"
        orbitStateEntity.managedObjectClassName = "OrbitStateEntity"

        func attr(_ n: String, _ t: NSAttributeType, opt: Bool = false) -> NSAttributeDescription {
            let a = NSAttributeDescription()
            a.name = n
            a.attributeType = t
            a.isOptional = opt
            return a
        }

        bookEntity.properties = [
            attr("id", .UUIDAttributeType),
            attr("isbn", .stringAttributeType),
            attr("title", .stringAttributeType),
            attr("author", .stringAttributeType),
            attr("coverURLString", .stringAttributeType, opt: true),
            attr("genre", .stringAttributeType),
            attr("totalPages", .integer32AttributeType),
            attr("currentPage", .integer32AttributeType),
            attr("dateAdded", .dateAttributeType),
            attr("isActive", .booleanAttributeType),
            attr("flavorMeta", .stringAttributeType, opt: true),
            attr("planetClass", .stringAttributeType, opt: true),
            attr("orbitRadius", .doubleAttributeType),
            attr("fuelGenerated", .integer32AttributeType),
            attr("sectorId", .UUIDAttributeType, opt: true),
            attr("positionX", .doubleAttributeType),
            attr("positionY", .doubleAttributeType)
        ]
        sessionEntity.properties = [
            attr("id", .UUIDAttributeType),
            attr("bookId", .UUIDAttributeType),
            attr("date", .dateAttributeType),
            attr("pagesRead", .integer32AttributeType),
            attr("duration", .doubleAttributeType),
            attr("flavorMeta", .stringAttributeType, opt: true)
        ]
        sectorEntity.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType),
            attr("genreKey", .stringAttributeType),
            attr("hue", .doubleAttributeType),
            attr("centerX", .doubleAttributeType),
            attr("centerY", .doubleAttributeType),
            attr("radius", .doubleAttributeType),
            attr("isUnlocked", .booleanAttributeType)
        ]
        expeditionEntity.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType),
            attr("targetSectorId", .UUIDAttributeType),
            attr("fuelRequired", .integer32AttributeType),
            attr("fuelCollected", .integer32AttributeType),
            attr("routeBookIdsData", .binaryDataAttributeType, opt: true),
            attr("isUnlocked", .booleanAttributeType)
        ]
        orbitStateEntity.properties = [
            attr("id", .UUIDAttributeType),
            attr("totalFuel", .integer32AttributeType),
            attr("expeditionFuel", .integer32AttributeType),
            attr("lightYears", .doubleAttributeType),
            attr("warpJumps", .integer32AttributeType),
            attr("unlockedSectorIdsData", .binaryDataAttributeType, opt: true)
        ]
        model.entities = [bookEntity, sessionEntity, sectorEntity, expeditionEntity, orbitStateEntity]
        return model
    }
}

@objc(OrbitReadsBookEntity)
final class OrbitReadsBookEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var isbn: String?
    @NSManaged var title: String?
    @NSManaged var author: String?
    @NSManaged var coverURLString: String?
    @NSManaged var genre: String?
    @NSManaged var totalPages: Int32
    @NSManaged var currentPage: Int32
    @NSManaged var dateAdded: Date?
    @NSManaged var isActive: Bool
    @NSManaged var flavorMeta: String?
    @NSManaged var planetClass: String?
    @NSManaged var orbitRadius: Double
    @NSManaged var fuelGenerated: Int32
    @NSManaged var sectorId: UUID?
    @NSManaged var positionX: Double
    @NSManaged var positionY: Double

    func toDomain() -> OrbitReadsBook? {
        guard let id, let isbn, let title, let author, let genre, let dateAdded else { return nil }
        return OrbitReadsBook(
            id: id,
            isbn: isbn,
            title: title,
            author: author,
            coverURL: coverURLString.flatMap(URL.init(string:)),
            genre: genre,
            totalPages: Int(totalPages),
            currentPage: Int(currentPage),
            dateAdded: dateAdded,
            isActive: isActive,
            flavorMeta: flavorMeta ?? "",
            planetClass: planetClass ?? OrbitReadsBook.defaultPlanetClass(from: flavorMeta ?? "", genre: genre),
            orbitRadius: orbitRadius > 0 ? orbitRadius : OrbitReadsBook.computeOrbitRadius(totalPages: Int(totalPages), pagesThisWeek: 0),
            fuelGenerated: Int(fuelGenerated),
            sectorId: sectorId ?? UUID(),
            positionX: positionX,
            positionY: positionY
        )
    }

    func apply(_ book: OrbitReadsBook) {
        id = book.id
        isbn = book.isbn
        title = book.title
        author = book.author
        coverURLString = book.coverURL?.absoluteString
        genre = book.genre
        totalPages = Int32(book.totalPages)
        currentPage = Int32(book.currentPage)
        dateAdded = book.dateAdded
        isActive = book.isActive
        flavorMeta = book.flavorMeta
        planetClass = book.planetClass
        orbitRadius = book.orbitRadius
        fuelGenerated = Int32(book.fuelGenerated)
        sectorId = book.sectorId
        positionX = book.positionX
        positionY = book.positionY
    }
}

@objc(OrbitReadsSessionEntity)
final class OrbitReadsSessionEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var bookId: UUID?
    @NSManaged var date: Date?
    @NSManaged var pagesRead: Int32
    @NSManaged var duration: Double
    @NSManaged var flavorMeta: String?

    func toDomain() -> OrbitReadsReadingSession? {
        guard let id, let bookId, let date else { return nil }
        return OrbitReadsReadingSession(
            id: id,
            bookId: bookId,
            date: date,
            pagesRead: Int(pagesRead),
            duration: duration,
            flavorMeta: flavorMeta ?? ""
        )
    }
}

@objc(SectorEntity)
final class SectorEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var genreKey: String?
    @NSManaged var hue: Double
    @NSManaged var centerX: Double
    @NSManaged var centerY: Double
    @NSManaged var radius: Double
    @NSManaged var isUnlocked: Bool

    func toDomain() -> GalaxySector? {
        guard let id, let name, let genreKey else { return nil }
        return GalaxySector(
            id: id,
            name: name,
            genreKey: genreKey,
            hue: hue,
            centerX: centerX,
            centerY: centerY,
            radius: radius,
            isUnlocked: isUnlocked
        )
    }

    func apply(_ sector: GalaxySector) {
        id = sector.id
        name = sector.name
        genreKey = sector.genreKey
        hue = sector.hue
        centerX = sector.centerX
        centerY = sector.centerY
        radius = sector.radius
        isUnlocked = sector.isUnlocked
    }
}

@objc(ExpeditionEntity)
final class ExpeditionEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var name: String?
    @NSManaged var targetSectorId: UUID?
    @NSManaged var fuelRequired: Int32
    @NSManaged var fuelCollected: Int32
    @NSManaged var routeBookIdsData: Data?
    @NSManaged var isUnlocked: Bool

    func toDomain() -> Expedition? {
        guard let id, let name, let targetSectorId else { return nil }
        let ids = (try? JSONDecoder().decode([UUID].self, from: routeBookIdsData ?? Data())) ?? []
        return Expedition(
            id: id,
            name: name,
            targetSectorId: targetSectorId,
            fuelRequired: Int(fuelRequired),
            fuelCollected: Int(fuelCollected),
            routeBookIds: ids,
            isUnlocked: isUnlocked
        )
    }

    func apply(_ expedition: Expedition) {
        id = expedition.id
        name = expedition.name
        targetSectorId = expedition.targetSectorId
        fuelRequired = Int32(expedition.fuelRequired)
        fuelCollected = Int32(expedition.fuelCollected)
        routeBookIdsData = try? JSONEncoder().encode(expedition.routeBookIds)
        isUnlocked = expedition.isUnlocked
    }
}

@objc(OrbitStateEntity)
final class OrbitStateEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var totalFuel: Int32
    @NSManaged var expeditionFuel: Int32
    @NSManaged var lightYears: Double
    @NSManaged var warpJumps: Int32
    @NSManaged var unlockedSectorIdsData: Data?

    func toDomain() -> OrbitState {
        let ids = (try? JSONDecoder().decode([UUID].self, from: unlockedSectorIdsData ?? Data())) ?? []
        return OrbitState(
            totalFuel: Int(totalFuel),
            expeditionFuel: Int(expeditionFuel),
            lightYears: lightYears,
            warpJumps: Int(warpJumps),
            unlockedSectorIds: ids
        )
    }

    func apply(_ state: OrbitState) {
        if id == nil { id = UUID() }
        totalFuel = Int32(state.totalFuel)
        expeditionFuel = Int32(state.expeditionFuel)
        lightYears = state.lightYears
        warpJumps = Int32(state.warpJumps)
        unlockedSectorIdsData = try? JSONEncoder().encode(state.unlockedSectorIds)
    }
}
