import SwiftUI

struct OrbitReadsBookRecommendationsView: View {
    private let cardWidth: CGFloat = 110
    private let coverWidth: CGFloat = 90
    private let coverHeight: CGFloat = 130
    private let cardHeight: CGFloat = 218

    var onBookAdded: () -> Void = {}
    @State private var feed: OrbitReadsRecommendationFeed?
    @State private var addingID: String?
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let feed {
                if !feed.curated.isEmpty {
                    section(OrbitReadsMetadata.curatedTitle, "Based on your library", feed.curated)
                }
                if !feed.discover.isEmpty {
                    section(OrbitReadsMetadata.discoverTitle, "From Open Library", feed.discover)
                }
            } else {
                HStack {
                    ProgressView().tint(OrbitTheme.cyan)
                    Text("Scanning galaxy…")
                        .font(OrbitTheme.sans)
                        .foregroundStyle(OrbitTheme.star.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(OrbitTheme.glass)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .task { feed = await OrbitReadsFactory.shared.fetchBookRecommendationsUseCase.execute() }
        .alert(
            "Could not add book",
            isPresented: .init(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func section(_ title: String, _ subtitle: String, _ items: [OrbitReadsBookRecommendation]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(OrbitTheme.sans.bold())
                .foregroundStyle(OrbitTheme.cyan)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(OrbitTheme.star.opacity(0.5))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(items) { card($0) }
                }
            }
        }
        .padding(14)
        .background(OrbitTheme.glass)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(OrbitTheme.glassStroke, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func card(_ item: OrbitReadsBookRecommendation) -> some View {
        Button {
            Task { await add(item) }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                OrbitReadsOpenLibraryCoverImage(
                    urls: item.coverURLs,
                    width: coverWidth,
                    height: coverHeight,
                    cornerRadius: 8,
                    placeholderFill: OrbitTheme.violet.opacity(0.4),
                    placeholderIconColor: OrbitTheme.cyan.opacity(0.5)
                )
                Text(item.title)
                    .font(OrbitTheme.sans)
                    .foregroundStyle(OrbitTheme.star)
                    .lineLimit(2)
                    .frame(width: cardWidth, height: 34, alignment: .topLeading)
                Text(item.author)
                    .font(.caption2)
                    .foregroundStyle(OrbitTheme.cyan)
                    .lineLimit(1)
                    .frame(width: cardWidth, height: 14, alignment: .topLeading)
                Text(metaLine(item))
                    .font(.caption2)
                    .foregroundStyle(OrbitTheme.star.opacity(0.5))
                    .lineLimit(1)
                    .frame(width: cardWidth, height: 14, alignment: .topLeading)
                Text("Discover")
                    .font(.caption2)
                    .foregroundStyle(OrbitTheme.cyan.opacity(0.7))
                    .frame(width: cardWidth, height: 14, alignment: .topLeading)
            }
            .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
        }
        .buttonStyle(.plain)
        .disabled(addingID != nil)
    }

    private func metaLine(_ item: OrbitReadsBookRecommendation) -> String {
        if let year = item.publishYear { return "\(year) · \(item.subject)" }
        return item.subject
    }

    private func add(_ item: OrbitReadsBookRecommendation) async {
        guard item.isbn != nil || !item.isbnCandidates.isEmpty else { return }
        addingID = item.id
        defer { addingID = nil }
        do {
            _ = try await OrbitReadsFactory.shared.addBookUseCase.execute(recommendation: item)
            feed = await OrbitReadsFactory.shared.fetchBookRecommendationsUseCase.execute()
            onBookAdded()
        } catch {
            errorMessage = "Could not fetch book from Open Library"
        }
    }
}
