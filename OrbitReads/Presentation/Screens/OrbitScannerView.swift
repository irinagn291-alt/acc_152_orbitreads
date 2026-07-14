import AVFoundation
import SwiftUI

struct OrbitScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var manualISBN = ""
    @State private var showManual = false
    @State private var warp = false
    @State private var tunnelPhase: CGFloat = 0
    @State private var cameraReady = OrbitReadsISBNScannerEngine.authorizationStatus == .authorized

    var body: some View {
        NavigationStack {
            ZStack {
                if cameraReady {
                    OrbitReadsBarcodeScannerRepresentable { isbn in
                        triggerWarp { onScan(isbn); dismiss() }
                    }
                    .ignoresSafeArea()
                }

                OrbitReadsCameraAccessView(prompt: OrbitReadsMetadata.cameraPrompt)

                warpTunnelOverlay

                if warp {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [OrbitTheme.cyan, OrbitTheme.violet.opacity(0.8), .clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 40
                            )
                        )
                        .scaleEffect(warp ? 28 : 0.2)
                        .opacity(warp ? 0.85 : 0)
                        .animation(reduceMotion ? .easeOut(duration: 0.25) : .easeIn(duration: 0.55), value: warp)
                        .allowsHitTesting(false)
                }

                if cameraReady {
                    VStack {
                        Spacer()
                        Text("Warp Tunnel — ISBN / QR")
                            .font(OrbitTheme.mono.weight(.semibold))
                            .foregroundStyle(OrbitTheme.cyan)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(OrbitTheme.glass)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(OrbitTheme.hudRing, lineWidth: 1))
                            .padding(.bottom, 56)
                    }
                }
            }
            .navigationTitle("Discover Planet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abort") { dismiss() } }
                ToolbarItem(placement: .primaryAction) { Button("Manual") { showManual = true } }
            }
            .alert("ISBN", isPresented: $showManual) {
                TextField("978...", text: $manualISBN)
                Button("Warp") {
                    if let isbn = OrbitReadsISBNScannerEngine.normalizedISBN(from: manualISBN) {
                        triggerWarp { onScan(isbn); dismiss() }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .task {
                cameraReady = await OrbitReadsISBNScannerEngine.ensureCameraAuthorized()
                withAnimation(reduceMotion ? .linear(duration: 0.01) : .linear(duration: 2.4).repeatForever(autoreverses: false)) {
                    tunnelPhase = 1
                }
            }
        }
    }

    private var warpTunnelOverlay: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let rings = 8
                for i in 0..<rings {
                    let t = (CGFloat(i) / CGFloat(rings) + tunnelPhase).truncatingRemainder(dividingBy: 1)
                    let radius = 20 + t * min(size.width, size.height) * 0.55
                    let rect = CGRect(
                        x: size.width / 2 - radius,
                        y: size.height / 2 - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.stroke(
                        Path(ellipseIn: rect),
                        with: .color(OrbitTheme.cyan.opacity(Double(1 - t) * 0.45)),
                        lineWidth: 1.5
                    )
                }
                var spokes = Path()
                for a in stride(from: 0.0, to: .pi * 2, by: .pi / 6) {
                    let inset = 24.0
                    spokes.move(to: CGPoint(x: size.width / 2 + cos(a) * inset, y: size.height / 2 + sin(a) * inset))
                    spokes.addLine(to: CGPoint(
                        x: size.width / 2 + cos(a + tunnelPhase) * min(size.width, size.height) * 0.48,
                        y: size.height / 2 + sin(a + tunnelPhase) * min(size.height, size.width) * 0.48
                    ))
                }
                context.stroke(spokes, with: .color(OrbitTheme.violet.opacity(0.2)), lineWidth: 1)
            }
            .allowsHitTesting(false)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
    }

    private func triggerWarp(_ finish: @escaping () -> Void) {
        withAnimation { warp = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.2 : 0.5), execute: finish)
    }
}

struct OrbitReadsBarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onDetect: (String) -> Void

    func makeUIViewController(context: Context) -> WarpTunnelScannerController {
        let controller = OrbitReadsISBNScannerEngine.makeCaptureController()
        controller.onDetect = onDetect
        return controller
    }

    func updateUIViewController(_ uiViewController: WarpTunnelScannerController, context: Context) {}
}
