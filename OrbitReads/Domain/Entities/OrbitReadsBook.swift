import Foundation

enum OrbitReadsMetadata {
    static let name = "Orbit Reads"
    static let tagline = "Chart the galaxy. One planet per book."
    static let version = "3.0.0-orbit"
    static let seedKey = "com.orbitreads.didSeed.v3"
    static let cameraPrompt = "Initiate warp tunnel to discover new planets"
    static let captain = "Cmdr. Vega"
    static let unit = "fuel units"
    static let recommendationSubjects = ["science_fiction", "space", "dystopia"]
    static let curatedTitle = "Planets to Discover"
    static let discoverTitle = "Open Library Galaxy"
    static let mapWidth: Double = 2400
    static let mapHeight: Double = 2400
    static let websiteHost = "warpages.pro"
    static var privacyPolicyURL: URL { URL(string: "https://\(websiteHost)/privacy-policy")! }
    static var contactUsURL: URL { URL(string: "https://\(websiteHost)/contact-us")! }
}

struct OrbitReadsBook: Identifiable, Equatable, Sendable {
    let id: UUID
    let isbn: String
    var title: String
    var author: String
    var coverURL: URL?
    var genre: String
    var totalPages: Int
    var currentPage: Int
    let dateAdded: Date
    var isActive: Bool
    var flavorMeta: String
    var planetClass: String
    var orbitRadius: Double
    var fuelGenerated: Int
    var sectorId: UUID
    var positionX: Double
    var positionY: Double

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return min(Double(currentPage) / Double(totalPages), 1.0)
    }

    mutating func refreshOrbitRadius(pagesThisWeek: Int) {
        orbitRadius = Self.computeOrbitRadius(totalPages: totalPages, pagesThisWeek: pagesThisWeek)
    }

    nonisolated static func computeOrbitRadius(totalPages: Int, pagesThisWeek: Int) -> Double {
        max(18, Double(pagesThisWeek) * 2.4 + Double(totalPages) * 0.035)
    }

    nonisolated static func defaultPlanetClass(from flavor: String, genre: String) -> String {
        if !flavor.isEmpty { return flavor }
        switch genre.lowercased() {
        case let g where g.contains("opera"): return "Gas Giant"
        case let g where g.contains("hard"): return "Monolith Station"
        case let g where g.contains("dystop"): return "Ash World"
        default: return "Terrestrial"
        }
    }
}

struct OrbitReadsReadingSession: Identifiable, Equatable, Sendable {
    let id: UUID
    let bookId: UUID
    let date: Date
    var pagesRead: Int
    var duration: TimeInterval
    var flavorMeta: String
}

struct OrbitReadsReadingStats: Sendable {
    var currentStreak: Int
    var bestStreak: Int
    var totalPages: Int
    var pagesThisWeek: Int
    var averagePagesPerSession: Double
    var consistencyScore: Int
    var dailyPages: [Date: Int]
}

struct FlightDeckSnapshot: Sendable, Equatable {
    var totalFuel: Int
    var expeditionFuel: Int
    var lightYears: Double
    var warpJumps: Int
    var habitableWorlds: Int
}

struct OrbitReadsOpenLibraryBook: Decodable, Sendable {
    let title: String?
    let authors: [String]?
    let numberOfPages: Int?
    let subjects: [String]?
    let workKey: String?
    let editionKey: String?
    let coverId: Int?

    enum CodingKeys: String, CodingKey {
        case title, authors, subjects
        case numberOfPages = "number_of_pages"
        case workKey, editionKey, coverId
    }
}

struct OrbitReadsBookRecommendation: Identifiable, Equatable, Sendable {
    let id: String
    let isbn: String?
    let isbnCandidates: [String]
    let workKey: String?
    let coverId: Int?
    let coverURLs: [URL]
    let title: String
    let author: String
    let subject: String
    let publishYear: Int?

    var coverURL: URL? { coverURLs.first }
}

struct OrbitReadsRecommendationFeed: Sendable {
    var curated: [OrbitReadsBookRecommendation]
    var discover: [OrbitReadsBookRecommendation]
}
