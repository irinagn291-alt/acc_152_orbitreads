import Foundation

enum OrbitReadsOpenLibraryError: Error, Sendable {
    case notFound
    case invalidISBN
}

struct OrbitReadsOpenLibraryClient: OrbitReadsOpenLibraryAPIProtocol {
    func fetchBook(isbn: String) async throws -> OrbitReadsOpenLibraryBook {
        let normalized = normalizeISBN(isbn)
        guard !normalized.isEmpty else { throw OrbitReadsOpenLibraryError.invalidISBN }
        let resolved = try await resolveEdition(isbn: normalized)
        return OrbitReadsOpenLibraryBook(
            title: resolved.title,
            authors: resolved.authors,
            numberOfPages: resolved.numberOfPages,
            subjects: resolved.subjects,
            workKey: resolved.workKey,
            editionKey: resolved.editionKey,
            coverId: resolved.coverId
        )
    }

    func fetchBook(isbns: [String]) async throws -> OrbitReadsOpenLibraryBook {
        for raw in isbns {
            let isbn = normalizeISBN(raw)
            guard !isbn.isEmpty else { continue }
            if let book = try? await fetchBook(isbn: isbn) { return book }
        }
        throw OrbitReadsOpenLibraryError.notFound
    }

    func fetchRecommendations(subjects: [String], limit: Int) async throws -> [OrbitReadsBookRecommendation] {
        var results: [OrbitReadsBookRecommendation] = []
        var seen = Set<String>()

        for subject in subjects {
            guard results.count < limit else { break }
            let encoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
            guard let url = URL(string: "https://openlibrary.org/search.json?q=subject:\(encoded)&limit=\(limit * 2)&fields=key,title,author_name,isbn,cover_i,subject,first_publish_year") else { continue }
            guard let (data, response) = try? await URLSession.shared.data(from: url),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let payload = try? JSONDecoder().decode(OrbitReadsOpenLibrarySearchResponse.self, from: data) else { continue }

            for doc in payload.docs.sorted(by: { ($0.cover_i != nil) && ($1.cover_i == nil) }) {
                guard results.count < limit else { break }
                guard let title = doc.title, !title.isEmpty else { continue }
                let isbns = validISBNs(from: doc.isbn)
                guard !isbns.isEmpty || doc.key != nil else { continue }
                let dedupeKey = doc.key ?? isbns.first ?? title
                guard !seen.contains(dedupeKey) else { continue }
                seen.insert(dedupeKey)

                let primaryISBN = isbns.first
                let urls = coverURLs(isbn: primaryISBN, coverId: doc.cover_i, isbnCandidates: isbns)
                results.append(OrbitReadsBookRecommendation(
                    id: dedupeKey,
                    isbn: primaryISBN,
                    isbnCandidates: isbns,
                    workKey: doc.key,
                    coverId: doc.cover_i,
                    coverURLs: urls,
                    title: title,
                    author: doc.author_name?.first ?? "Unknown Author",
                    subject: doc.subject?.first ?? subject,
                    publishYear: doc.first_publish_year
                ))
            }
        }
        return results
    }

    func coverURL(for isbn: String) -> URL {
        bestCoverURL(isbn: isbn, coverId: nil)
    }

    func bestCoverURL(isbn: String, coverId: Int?) -> URL {
        coverURLs(isbn: isbn, coverId: coverId, isbnCandidates: [isbn]).first
            ?? URL(string: "https://covers.openlibrary.org/b/isbn/\(normalizeISBN(isbn))-L.jpg")!
    }

    func coverURLs(isbn: String?, coverId: Int?, isbnCandidates: [String]) -> [URL] {
        var urls: [URL] = []
        if let coverId {
            urls.append(URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-L.jpg")!)
            urls.append(URL(string: "https://covers.openlibrary.org/b/id/\(coverId)-M.jpg")!)
        }
        var seenISBNs = Set<String>()
        for raw in isbnCandidates + (isbn.map { [$0] } ?? []) {
            let n = normalizeISBN(raw)
            guard n.count == 10 || n.count == 13, !seenISBNs.contains(n) else { continue }
            seenISBNs.insert(n)
            urls.append(URL(string: "https://covers.openlibrary.org/b/isbn/\(n)-L.jpg")!)
            urls.append(URL(string: "https://covers.openlibrary.org/b/isbn/\(n)-M.jpg")!)
        }
        var seenURLs = Set<String>()
        return urls.filter { seenURLs.insert($0.absoluteString).inserted }
    }

    func sourceURL(isbn: String, workKey: String?) -> URL {
        let normalized = normalizeISBN(isbn)
        if !normalized.isEmpty, let url = URL(string: "https://openlibrary.org/isbn/\(normalized)") {
            return url
        }
        if let workKey, let url = URL(string: "https://openlibrary.org\(workKey)") {
            return url
        }
        return URL(string: "https://openlibrary.org")!
    }

    private func resolveEdition(isbn: String) async throws -> ResolvedEdition {
        let edition = try await fetchEditionJSON(isbn: isbn)
        var authors = await resolveAuthorNames(edition.authors?.map(\.key) ?? [])
        if authors.isEmpty { authors = ["Unknown Author"] }

        var subjects = edition.subjects ?? []
        let workKey = edition.works?.first?.key
        if subjects.isEmpty, let workKey {
            subjects = await fetchWorkSubjects(workKey: workKey)
        }
        if subjects.isEmpty { subjects = ["General"] }

        return ResolvedEdition(
            title: edition.title ?? edition.full_title ?? "Unknown Title",
            authors: authors,
            subjects: subjects,
            numberOfPages: edition.number_of_pages,
            coverId: edition.covers?.first,
            workKey: workKey,
            editionKey: edition.key,
            isbn: isbn
        )
    }

    private func fetchEditionJSON(isbn: String) async throws -> EditionJSON {
        guard let url = URL(string: "https://openlibrary.org/isbn/\(isbn).json") else {
            throw OrbitReadsOpenLibraryError.invalidISBN
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...399).contains(http.statusCode) else {
            throw OrbitReadsOpenLibraryError.notFound
        }
        return try JSONDecoder().decode(EditionJSON.self, from: data)
    }

    private func resolveAuthorNames(_ keys: [String]) async -> [String] {
        var names: [String] = []
        for key in keys.prefix(3) {
            guard let url = URL(string: "https://openlibrary.org\(key).json"),
                  let (data, response) = try? await URLSession.shared.data(from: url),
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let author = try? JSONDecoder().decode(AuthorJSON.self, from: data),
                  let name = author.name else { continue }
            names.append(name)
        }
        return names
    }

    private func fetchWorkSubjects(workKey: String) async -> [String] {
        guard let url = URL(string: "https://openlibrary.org\(workKey).json"),
              let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let work = try? JSONDecoder().decode(WorkJSON.self, from: data) else { return [] }
        return work.subjects ?? []
    }

    private func coverURL(isbn: String?, coverId: Int?) -> URL? {
        coverURLs(isbn: isbn, coverId: coverId, isbnCandidates: []).first
    }

    private func validISBNs(from list: [String]?) -> [String] {
        guard let list else { return [] }
        var seen = Set<String>()
        return list.compactMap { raw -> String? in
            let normalized = normalizeISBN(raw)
            guard normalized.count == 13 || normalized.count == 10 else { return nil }
            guard !seen.contains(normalized) else { return nil }
            seen.insert(normalized)
            return normalized
        }.sorted { lhs, rhs in
            if lhs.count == 13 && lhs.hasPrefix("978") { return true }
            if rhs.count == 13 && rhs.hasPrefix("978") { return false }
            return lhs.count > rhs.count
        }
    }

    private func normalizeISBN(_ raw: String) -> String {
        raw.uppercased().filter { $0.isNumber || $0 == "X" }
    }
}

private struct EditionJSON: Decodable {
    let title: String?
    let full_title: String?
    let number_of_pages: Int?
    let subjects: [String]?
    let authors: [KeyRef]?
    let works: [KeyRef]?
    let covers: [Int]?
    let key: String?
}

private struct KeyRef: Decodable {
    let key: String
}

private struct AuthorJSON: Decodable {
    let name: String?
}

private struct WorkJSON: Decodable {
    let subjects: [String]?
}

private struct ResolvedEdition: Sendable {
    let title: String
    let authors: [String]
    let subjects: [String]
    let numberOfPages: Int?
    let coverId: Int?
    let workKey: String?
    let editionKey: String?
    let isbn: String
}

struct OrbitReadsOpenLibrarySearchResponse: Decodable, Sendable {
    let docs: [OrbitReadsOpenLibrarySearchDoc]
}

struct OrbitReadsOpenLibrarySearchDoc: Decodable, Sendable {
    let key: String?
    let title: String?
    let author_name: [String]?
    let isbn: [String]?
    let cover_i: Int?
    let subject: [String]?
    let first_publish_year: Int?
}
