import Foundation

extension OrbitReadsBook {
    var openLibrarySourceURL: URL {
        if !isbn.isEmpty, let url = URL(string: "https://openlibrary.org/isbn/\(isbn)") {
            return url
        }
        return URL(string: "https://openlibrary.org")!
    }

    var coverCandidateURLs: [URL] {
        var urls: [URL] = []
        if let coverURL { urls.append(coverURL) }
        let normalized = isbn.uppercased().filter { $0.isNumber || $0 == "X" }
        if normalized.count == 10 || normalized.count == 13 {
            urls.append(URL(string: "https://covers.openlibrary.org/b/isbn/\(normalized)-L.jpg")!)
            urls.append(URL(string: "https://covers.openlibrary.org/b/isbn/\(normalized)-M.jpg")!)
        }
        var seen = Set<String>()
        return urls.filter { seen.insert($0.absoluteString).inserted }
    }
}

extension OrbitReadsBookRecommendation {
    var sourceURL: URL {
        if let isbn, !isbn.isEmpty, let url = URL(string: "https://openlibrary.org/isbn/\(isbn)") {
            return url
        }
        if let workKey, let url = URL(string: "https://openlibrary.org\(workKey)") {
            return url
        }
        return URL(string: "https://openlibrary.org")!
    }
}
