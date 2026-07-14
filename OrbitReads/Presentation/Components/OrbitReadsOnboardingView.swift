import SwiftUI

struct OrbitReadsOnboardingView: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            OrbitTheme.nebula.ignoresSafeArea()
            VStack(spacing: 18) {
                Text("Chart your galaxy")
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundStyle(OrbitTheme.cyan)
                Text("Pinch and drag the map. Planets are books. Expeditions unlock sectors with fuel from real pages.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.85))
                Button("Engage thrusters") {
                    UserDefaults.standard.set(true, forKey: "orbitreads.onboarded.v1")
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .tint(OrbitTheme.cyan)
            }
            .padding()
        }
    }
}
