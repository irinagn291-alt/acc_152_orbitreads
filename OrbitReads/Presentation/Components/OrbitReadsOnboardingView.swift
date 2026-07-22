import SwiftUI

struct OrbitReadsOnboardingView: View {
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var warp = false
    @State private var planetScale: CGFloat = 0.2
    @State private var step = 0
    @State private var dragHint: CGSize = .zero

    private let flightPlan: [(title: String, body: String)] = [
        ("Your library is a galaxy", "Each book lands as a planet. Pinch to zoom, drag to chart sectors — this is a flight deck, not a shelf."),
        ("Pages burn as fuel", "Logging sessions fills tanks. Expeditions spend fuel to unlock cold sectors of the map."),
        ("Plot the first jump", "Route planner links planets into a crossing. Asteroid runs reward real progress on the active world.")
    ]

    var body: some View {
        ZStack {
            OrbitTheme.nebulaDark.ignoresSafeArea()
            starfield
            VStack(spacing: 0) {
                Text("ORBIT READS")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(OrbitTheme.cyan)
                    .padding(.top, 48)

                Spacer()

                ZStack {
                    Circle()
                        .stroke(OrbitTheme.cyan.opacity(0.25), lineWidth: 1)
                        .frame(width: 220, height: 220)
                        .scaleEffect(warp ? 1.15 : 0.85)
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [OrbitTheme.cyan, OrbitTheme.violet.opacity(0.8), OrbitTheme.nebula],
                                center: .center,
                                startRadius: 4,
                                endRadius: 70
                            )
                        )
                        .frame(width: 88, height: 88)
                        .scaleEffect(planetScale)
                        .offset(dragHint)
                        .shadow(color: OrbitTheme.cyan.opacity(0.45), radius: 18)
                        .gesture(
                            DragGesture()
                                .onChanged { dragHint = $0.translation }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                                        dragHint = .zero
                                    }
                                }
                        )
                    ForEach(0..<6, id: \.self) { i in
                        Circle()
                            .fill(OrbitTheme.star.opacity(0.7))
                            .frame(width: 4, height: 4)
                            .offset(
                                x: cos(Double(i) / 6 * .pi * 2) * 100,
                                y: sin(Double(i) / 6 * .pi * 2) * 100
                            )
                    }
                }
                .frame(height: 260)

                Spacer()

                VStack(spacing: 10) {
                    Text(flightPlan[step].title)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(OrbitTheme.star)
                        .multilineTextAlignment(.center)
                    Text(flightPlan[step].body)
                        .font(.system(size: 15, design: .rounded))
                        .foregroundStyle(OrbitTheme.star.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .fixedSize(horizontal: false, vertical: true)
                    if step == 0 {
                        Text("Drag the planet — feel the deck")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(OrbitTheme.cyan)
                            .padding(.top, 4)
                    }
                }
                .id(step)

                HStack(spacing: 8) {
                    ForEach(0..<flightPlan.count, id: \.self) { i in
                        Capsule()
                            .fill(i == step ? OrbitTheme.cyan : OrbitTheme.star.opacity(0.2))
                            .frame(width: i == step ? 20 : 8, height: 8)
                    }
                }
                .padding(.top, 18)

                Button(action: advance) {
                    Text(step < flightPlan.count - 1 ? "Next waypoint" : "Engage thrusters")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(OrbitTheme.nebulaDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(OrbitTheme.cyan)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.9)) { planetScale = 1 }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                warp = true
            }
        }
    }

    private var starfield: some View {
        Canvas { context, size in
            for i in 0..<80 {
                let x = CGFloat((i * 73) % max(Int(size.width), 1))
                let y = CGFloat((i * 131) % max(Int(size.height), 1))
                let r = CGFloat(1 + i % 3)
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(.white.opacity(0.15 + Double(i % 5) * 0.08))
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func advance() {
        if step < flightPlan.count - 1 {
            withAnimation { step += 1 }
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.7)) {
                planetScale = step == 1 ? 1.12 : 0.92
            }
        } else {
            UserDefaults.standard.set(true, forKey: "orbitreads.onboarded.v2")
            isPresented = false
        }
    }
}
