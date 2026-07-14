import SwiftUI

struct OrbitReadsOpenLibraryCoverImage: View {
    let urls: [URL]
    var width: CGFloat = 90
    var height: CGFloat = 130
    var cornerRadius: CGFloat = 6
    var placeholderFill: Color = .gray.opacity(0.25)
    var placeholderIconColor: Color = .secondary

    @State private var image: UIImage?
    @State private var finished = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(placeholderFill)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if !finished {
                ProgressView()
            } else {
                Image(systemName: "book.closed")
                    .font(.title2)
                    .foregroundStyle(placeholderIconColor)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .task(id: urls.map(\.absoluteString).joined()) {
            await load()
        }
    }

    private func load() async {
        image = nil
        finished = false
        for url in urls {
            if let loaded = await fetchValidCover(from: url) {
                image = loaded
                finished = true
                return
            }
        }
        finished = true
    }

    private func fetchValidCover(from url: URL) async -> UIImage? {
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              data.count > 3_000,
              let uiImage = UIImage(data: data),
              uiImage.size.width > 20,
              uiImage.size.height > 20 else { return nil }
        return uiImage
    }
}

struct OrbitReadsBookCoverImage: View {
    let book: OrbitReadsBook
    var width: CGFloat = 90
    var height: CGFloat = 130
    var cornerRadius: CGFloat = 6
    var placeholderFill: Color = .gray.opacity(0.25)
    var placeholderIconColor: Color = .secondary

    var body: some View {
        OrbitReadsOpenLibraryCoverImage(
            urls: book.coverCandidateURLs,
            width: width,
            height: height,
            cornerRadius: cornerRadius,
            placeholderFill: placeholderFill,
            placeholderIconColor: placeholderIconColor
        )
    }
}
