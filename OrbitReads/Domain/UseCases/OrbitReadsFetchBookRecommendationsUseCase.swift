import Foundation

struct OrbitReadsFetchBookRecommendationsUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol
    private let api: OrbitReadsOpenLibraryAPIProtocol

    init(repository: OrbitReadsBookRepositoryProtocol, api: OrbitReadsOpenLibraryAPIProtocol) {
        self.repository = repository
        self.api = api
    }

    func execute() async -> OrbitReadsRecommendationFeed {
        let books = (try? await repository.fetchAll()) ?? []
        let existing = Set(books.map(\.isbn))
        let curatedSubject = subjectForGenre(mostCommonGenre(in: books))

        async let curated = load(subjects: [curatedSubject], limit: 6, excluding: existing)
        async let discover = load(subjects: OrbitReadsMetadata.recommendationSubjects, limit: 10, excluding: existing)
        return OrbitReadsRecommendationFeed(curated: await curated, discover: await discover)
    }

    private func load(subjects: [String], limit: Int, excluding: Set<String>) async -> [OrbitReadsBookRecommendation] {
        guard let items = try? await api.fetchRecommendations(subjects: subjects, limit: limit) else { return [] }
        return items.filter { rec in
            let candidates = rec.isbnCandidates.isEmpty ? (rec.isbn.map { [$0] } ?? []) : rec.isbnCandidates
            return candidates.contains { isbn in
                let normalized = isbn.filter(\.isNumber)
                return !normalized.isEmpty && !excluding.contains(normalized)
            }
        }
    }

    private func mostCommonGenre(in books: [OrbitReadsBook]) -> String? {
        var counts: [String: Int] = [:]
        books.forEach { counts[$0.genre, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func subjectForGenre(_ genre: String?) -> String {
        guard let genre, !genre.isEmpty else { return OrbitReadsMetadata.recommendationSubjects[0] }
        return genre.lowercased().replacingOccurrences(of: " ", with: "_")
    }
}
