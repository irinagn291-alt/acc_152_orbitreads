import SwiftUI

struct OrbitReadsRootView: View {
    @State private var coordinator = OrbitReadsFactory.shared.makeCoordinator()
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "orbitreads.onboarded.v1")

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            GalaxyCanvasView(coordinator: coordinator)
        }
        .tint(OrbitTheme.cyan)
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showOnboarding) {
            OrbitReadsOnboardingView(isPresented: $showOnboarding)
        }
        .task { await OrbitReadsFactory.shared.bootstrap() }
    }
}

@main
struct OrbitReadsApp: App {
    var body: some Scene {
        WindowGroup {
            OrbitReadsRootView()
        }
    }
}
