import AVFoundation
import SwiftUI

struct OrbitReadsCameraAccessView: View {
    let prompt: String
    @State private var authorized = OrbitReadsISBNScannerEngine.authorizationStatus == .authorized
    @State private var denied = OrbitReadsISBNScannerEngine.authorizationStatus == .denied

    var body: some View {
        ZStack {
            if authorized {
                Color.clear
            } else if denied {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                        .foregroundStyle(OrbitTheme.cyan)
                    Text("Camera access required")
                        .font(OrbitTheme.sans)
                        .foregroundStyle(OrbitTheme.star)
                    Text(prompt)
                        .font(OrbitTheme.sans)
                        .foregroundStyle(OrbitTheme.star.opacity(0.75))
                        .multilineTextAlignment(.center)
                    Button("Open Settings") { openSettings() }
                        .font(OrbitTheme.sans)
                        .foregroundStyle(OrbitTheme.nebulaDark)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(OrbitTheme.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.92))
            } else {
                ProgressView("Requesting camera access…")
                    .font(OrbitTheme.sans)
                    .tint(OrbitTheme.cyan)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.92))
                    .task {
                        let granted = await OrbitReadsISBNScannerEngine.ensureCameraAuthorized()
                        authorized = granted
                        denied = !granted
                    }
            }
        }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
