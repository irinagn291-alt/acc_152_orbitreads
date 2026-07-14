import SwiftUI

struct PlanetDetailSheet: View {
    let book: OrbitReadsBook
    let coordinator: OrbitReadsCoordinator
    let onChanged: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var current: OrbitReadsBook

    init(book: OrbitReadsBook, coordinator: OrbitReadsCoordinator, onChanged: @escaping () -> Void) {
        self.book = book
        self.coordinator = coordinator
        self.onChanged = onChanged
        _current = State(initialValue: book)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(OrbitTheme.cyan.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [4, 6]))
                            .frame(width: 150, height: 150)
                        OrbitReadsBookCoverImage(
                            book: current,
                            width: 110,
                            height: 110,
                            cornerRadius: 55,
                            placeholderFill: OrbitTheme.violet,
                            placeholderIconColor: OrbitTheme.cyan
                        )
                    }
                    Text(current.title).font(OrbitTheme.title).foregroundStyle(OrbitTheme.cyan)
                    Text(current.author).font(OrbitTheme.sans).foregroundStyle(OrbitTheme.star.opacity(0.7))
                    Text("\(current.planetClass) · orbit \(Int(current.orbitRadius))")
                        .font(OrbitTheme.mono)
                        .foregroundStyle(OrbitTheme.aqua)
                    ProgressView(value: current.progress).tint(OrbitTheme.cyan).padding(.horizontal, 36)
                    Text("\(current.currentPage)/\(current.totalPages) · \(current.fuelGenerated) fuel")
                        .font(OrbitTheme.sans)
                        .foregroundStyle(OrbitTheme.star.opacity(0.6))

                    HStack(spacing: 10) {
                        fuelButton("+10") { Task { await log(10) } }
                        fuelButton("+25") { Task { await log(25) } }
                        fuelButton("+50") { Task { await log(50) } }
                    }

                    Button("Asteroid Dodge") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            coordinator.openAsteroidDodge(bookId: current.id)
                        }
                    }
                    .font(OrbitTheme.sans.bold())
                    .foregroundStyle(OrbitTheme.nebulaDark)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(OrbitTheme.cyan)
                    .clipShape(Capsule())

                    OrbitReadsViewAtSourceButton(url: current.openLibrarySourceURL)
                        .font(OrbitTheme.sans)
                        .foregroundStyle(OrbitTheme.cyan)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(OrbitTheme.glass)
                        .clipShape(Capsule())
                }
                .padding()
            }
            .orbitScreenStyle()
            .navigationTitle("Planet")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func log(_ pages: Int) async {
        try? await OrbitReadsFactory.shared.logPagesUseCase.execute(bookId: current.id, pages: pages)
        current = (try? await OrbitReadsFactory.shared.bookRepository.fetch(by: current.id)) ?? current
        onChanged()
    }

    private func fuelButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .font(OrbitTheme.sans.bold())
            .foregroundStyle(OrbitTheme.cyan)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .overlay(Capsule().stroke(OrbitTheme.cyan, lineWidth: 1))
    }
}

struct ExpeditionRunView: View {
    let expeditionId: UUID
    let onChanged: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var expedition: Expedition?
    @State private var books: [OrbitReadsBook] = []
    @State private var trace: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            Text(expedition?.name ?? "Expedition")
                .font(OrbitTheme.title)
                .foregroundStyle(OrbitTheme.cyan)
            GeometryReader { geo in
                Canvas { context, size in
                    guard let expedition else { return }
                    let route = books.filter { expedition.routeBookIds.contains($0.id) }
                    guard route.count > 1 else { return }
                    var path = Path()
                    for (i, book) in route.enumerated() {
                        let x = CGFloat(i) / CGFloat(route.count - 1) * size.width
                        let y = size.height * 0.5 + sin(Double(i)) * 40
                        let p = CGPoint(x: x, y: y)
                        if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                    }
                    context.stroke(
                        path.trimmedPath(from: 0, to: trace),
                        with: .color(OrbitTheme.cyan),
                        style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                    )
                }
            }
            .frame(height: 160)
            .background(OrbitTheme.glass)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            if let expedition {
                Text("\(expedition.fuelCollected)/\(expedition.fuelRequired) fuel collected")
                    .font(OrbitTheme.mono)
                    .foregroundStyle(OrbitTheme.star.opacity(0.7))
                if expedition.isReady && !expedition.isUnlocked {
                    Button("Complete Unlock") {
                        Task {
                            _ = try? await OrbitReadsFactory.shared.unlockSectorUseCase.execute(expeditionId: expedition.id)
                            onChanged()
                            dismiss()
                        }
                    }
                    .font(OrbitTheme.sans.bold())
                    .foregroundStyle(OrbitTheme.nebulaDark)
                    .padding()
                    .background(OrbitTheme.cyan)
                    .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding()
        .orbitScreenStyle()
        .task {
            expedition = try? await OrbitReadsFactory.shared.bookRepository.fetchExpeditions().first { $0.id == expeditionId }
            books = (try? await OrbitReadsFactory.shared.bookRepository.fetchAll()) ?? []
            withAnimation(reduceMotion ? .linear(duration: 0.2) : .easeInOut(duration: 1.6)) {
                trace = 1
            }
        }
    }
}
