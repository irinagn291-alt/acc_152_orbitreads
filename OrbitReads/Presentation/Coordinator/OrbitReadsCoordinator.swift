import SwiftUI

enum OrbitReadsRoute: Hashable {
    case galaxyMap
    case planetDetail(UUID)
    case routePlanner
    case expeditionRun
    case scanner
}

enum OrbitReadsSheet: Identifiable, Equatable {
    case planetDetail(UUID)
    case routePlanner
    case scanner
    case asteroidDodge(UUID)
    case settings

    var id: String {
        switch self {
        case .planetDetail(let id): return "planet-\(id)"
        case .routePlanner: return "route"
        case .scanner: return "scanner"
        case .asteroidDodge(let id): return "dodge-\(id)"
        case .settings: return "settings"
        }
    }
}

enum OrbitReadsOverlay: Equatable {
    case trajectory
    case none
}

@MainActor
@Observable
final class OrbitReadsCoordinator {
    var path = NavigationPath()
    var activeSheet: OrbitReadsSheet?
    var overlay: OrbitReadsOverlay = .none
    var selectedPlanetId: UUID?
    var expeditionRunId: UUID?

    func openGalaxy() {
        path = NavigationPath()
        activeSheet = nil
        overlay = .none
    }

    func openPlanet(_ id: UUID) {
        selectedPlanetId = id
        activeSheet = .planetDetail(id)
    }

    func openRoutePlanner() {
        activeSheet = .routePlanner
    }

    func openScanner() {
        activeSheet = .scanner
    }

    func openSettings() {
        activeSheet = .settings
    }

    func openAsteroidDodge(bookId: UUID) {
        activeSheet = .asteroidDodge(bookId)
    }

    func openExpeditionRun(_ id: UUID) {
        expeditionRunId = id
        path.append(OrbitReadsRoute.expeditionRun)
    }

    func toggleTrajectory() {
        overlay = overlay == .trajectory ? .none : .trajectory
    }

    func dismissSheet() {
        activeSheet = nil
    }

    func dismissOverlay() {
        overlay = .none
    }
}
