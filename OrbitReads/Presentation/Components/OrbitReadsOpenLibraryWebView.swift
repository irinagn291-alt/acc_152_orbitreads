import SwiftUI
import WebKit

struct OrbitReadsOpenLibraryWebView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            OrbitReadsOpenLibraryWebViewRepresentable(url: url)
                .ignoresSafeArea(edges: .bottom)
                .navigationTitle("Open Library")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
        }
    }
}

struct OrbitReadsOpenLibraryWebViewRepresentable: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct OrbitReadsViewAtSourceButton: View {
    let url: URL
    var title: String = "Chart at Open Library"
    @State private var showWebView = false

    var body: some View {
        Button {
            showWebView = true
        } label: {
            Label(title, systemImage: "globe")
        }
        .sheet(isPresented: $showWebView) {
            OrbitReadsOpenLibraryWebView(url: url)
        }
    }
}
