import SwiftUI

struct AsteroidDodgeView: View {
    let bookId: UUID
    var onFinished: () -> Void = {}
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shipX: CGFloat = 0
    @State private var dragOriginX: CGFloat = 0
    @State private var asteroids: [Asteroid] = []
    @State private var timeLeft = 30
    @State private var nearMisses = 0
    @State private var hits = 0
    @State private var accurateFrames = 0
    @State private var totalFrames = 0
    @State private var tickTask: Task<Void, Never>?
    @State private var secondTask: Task<Void, Never>?
    @State private var ended = false
    @State private var fieldSize: CGSize = .zero
    @State private var hitFlash = false
    @State private var invulnerableUntil: Date = .distantPast
    @State private var showResult = false
    @State private var earnedFuel = 0

    private let shipRadius: CGFloat = 18
    private let asteroidRadius: CGFloat = 13
    private let maxHits = 3

    struct Asteroid: Identifiable {
        let id: UUID
        var x: CGFloat
        var y: CGFloat
        var speed: CGFloat
        var scoredNearMiss: Bool
    }

    private var accuracy: Double {
        guard totalFrames > 0 else { return 1 }
        return Double(accurateFrames) / Double(totalFrames)
    }

    private var projectedFuel: Int {
        let base = nearMisses * 3
        let accuracyBonus = Int(accuracy * 35)
        return max(0, base + accuracyBonus - hits * 8)
    }

    var body: some View {
        ZStack {
            OrbitTheme.nebulaDark.ignoresSafeArea()

            VStack(spacing: 0) {
                hud
                playfield
                Text("Drag to steer · \(max(0, maxHits - hits)) hull left")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(OrbitTheme.star.opacity(0.5))
                    .padding(.bottom, 16)
            }

            if showResult {
                resultOverlay
            }
        }
        .onAppear { startGame() }
        .onDisappear {
            tickTask?.cancel()
            secondTask?.cancel()
        }
    }

    private var hud: some View {
        HStack {
            Text("\(timeLeft)s")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(OrbitTheme.cyan)
            Spacer()
            Text(String(format: "ACC %.0f%%", accuracy * 100))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(OrbitTheme.aqua)
            Spacer()
            Text("Hits \(hits)/\(maxHits)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(hits > 0 ? Color.orange : OrbitTheme.star)
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var playfield: some View {
        GeometryReader { geo in
            let shipPoint = CGPoint(
                x: geo.size.width / 2 + shipX,
                y: geo.size.height - 70
            )
            ZStack {
                ForEach(asteroids) { a in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(white: 0.75), Color(white: 0.25)],
                                center: .topLeading,
                                startRadius: 1,
                                endRadius: 16
                            )
                        )
                        .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))
                        .frame(width: asteroidRadius * 2, height: asteroidRadius * 2)
                        .position(x: a.x, y: a.y)
                }

                Image(systemName: "airplane")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(hitFlash ? Color.orange : OrbitTheme.cyan)
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(hitFlash ? 1.15 : 1)
                    .shadow(color: (hitFlash ? Color.orange : OrbitTheme.cyan).opacity(0.55), radius: 10)
                    .position(shipPoint)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(OrbitTheme.nebula.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let half = geo.size.width / 2 - 28
                        shipX = max(-half, min(half, dragOriginX + value.translation.width))
                    }
                    .onEnded { _ in
                        dragOriginX = shipX
                    }
            )
            .onAppear { fieldSize = geo.size }
            .onChange(of: geo.size) { _, newSize in
                fieldSize = newSize
            }
        }
        .padding(.horizontal, 12)
    }

    private var resultOverlay: some View {
        VStack(spacing: 14) {
            Text(hits >= maxHits ? "Hull breached" : "Approach complete")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(OrbitTheme.cyan)
            Text("+\(earnedFuel) expedition fuel")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(OrbitTheme.star)
            Text("Hits \(hits) · near misses \(nearMisses)")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(OrbitTheme.star.opacity(0.55))
            Button("Return to planet") {
                onFinished()
                dismiss()
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(OrbitTheme.nebulaDark)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(OrbitTheme.cyan)
            .clipShape(Capsule())
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(OrbitTheme.nebulaDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(OrbitTheme.cyan.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private func startGame() {
        secondTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled, !ended else { return }
                timeLeft -= 1
                if timeLeft <= 0 {
                    await endGame()
                    return
                }
            }
        }
        tickTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: reduceMotion ? 70_000_000 : 33_000_000)
                guard !Task.isCancelled, !ended else { return }
                tick()
            }
        }
    }

    private func tick() {
        guard fieldSize.width > 0, fieldSize.height > 0 else { return }

        let shipPoint = CGPoint(
            x: fieldSize.width / 2 + shipX,
            y: fieldSize.height - 70
        )
        let now = Date()
        let invulnerable = now < invulnerableUntil
        var clear = true
        var doomed: Set<UUID> = []

        for i in asteroids.indices {
            asteroids[i].y += asteroids[i].speed
            let dx = asteroids[i].x - shipPoint.x
            let dy = asteroids[i].y - shipPoint.y
            let dist = hypot(dx, dy)
            let hitDistance = shipRadius + asteroidRadius

            if dist < hitDistance {
                clear = false
                if !invulnerable {
                    hits += 1
                    doomed.insert(asteroids[i].id)
                    invulnerableUntil = now.addingTimeInterval(0.9)
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    withAnimation(.easeOut(duration: 0.12)) { hitFlash = true }
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 180_000_000)
                        withAnimation(.easeOut(duration: 0.2)) { hitFlash = false }
                    }
                    if hits >= maxHits {
                        Task { await endGame() }
                    }
                }
            } else if dist < hitDistance + 28, !asteroids[i].scoredNearMiss {
                asteroids[i].scoredNearMiss = true
                nearMisses += 1
            }
        }

        if !doomed.isEmpty {
            asteroids.removeAll { doomed.contains($0.id) }
        }
        asteroids.removeAll { $0.y > fieldSize.height + 40 }

        let spawnChance = reduceMotion ? 14 : 9
        if Int.random(in: 0...spawnChance) == 0 {
            let maxX = max(37, fieldSize.width - 36)
            asteroids.append(Asteroid(
                id: UUID(),
                x: CGFloat.random(in: 36...maxX),
                y: -20,
                speed: CGFloat.random(in: 4...8),
                scoredNearMiss: false
            ))
        }

        totalFrames += 1
        if clear { accurateFrames += 1 }
    }

    private func endGame() async {
        guard !ended else { return }
        ended = true
        tickTask?.cancel()
        secondTask?.cancel()
        earnedFuel = projectedFuel
        if earnedFuel > 0 {
            _ = try? await OrbitReadsFactory.shared.contributeFuelUseCase.execute(
                amount: earnedFuel,
                source: .asteroidBonus
            )
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            showResult = true
        }
    }
}

#Preview { AsteroidDodgeView(bookId: UUID()) }
