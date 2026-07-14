import Foundation

struct GalaxySector: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var genreKey: String
    var hue: Double
    var centerX: Double
    var centerY: Double
    var radius: Double
    var isUnlocked: Bool
}

struct StarSystem: Identifiable, Equatable, Sendable {
    let id: UUID
    var author: String
    var sectorId: UUID
    var centerX: Double
    var centerY: Double
    var bookIds: [UUID]
}

struct OrbitState: Equatable, Sendable {
    var totalFuel: Int
    var expeditionFuel: Int
    var lightYears: Double
    var warpJumps: Int
    var unlockedSectorIds: [UUID]

    nonisolated static let initial = OrbitState(
        totalFuel: 0,
        expeditionFuel: 0,
        lightYears: 0,
        warpJumps: 0,
        unlockedSectorIds: []
    )
}

struct Expedition: Identifiable, Equatable, Sendable {
    let id: UUID
    var name: String
    var targetSectorId: UUID
    var fuelRequired: Int
    var fuelCollected: Int
    var routeBookIds: [UUID]
    var isUnlocked: Bool

    var progress: Double {
        guard fuelRequired > 0 else { return 0 }
        return min(Double(fuelCollected) / Double(fuelRequired), 1.0)
    }

    var isReady: Bool { fuelCollected >= fuelRequired }
}

struct GalaxyMapSnapshot: Sendable, Equatable {
    var books: [OrbitReadsBook]
    var sectors: [GalaxySector]
    var systems: [StarSystem]
    var expeditions: [Expedition]
    var orbitState: OrbitState
    var sessions: [OrbitReadsReadingSession]
}
