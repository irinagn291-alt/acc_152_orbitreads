import SwiftUI
import UIKit

@MainActor
@Observable
final class GalaxyCanvasViewModel {
    var books: [OrbitReadsBook] = []
    var sectors: [GalaxySector] = []
    var systems: [StarSystem] = []
    var deck: FlightDeckSnapshot?
    var sessions: [OrbitReadsReadingSession] = []
    var formation = false

    func load() async {
        let factory = OrbitReadsFactory.shared
        books = (try? await factory.bookRepository.fetchAll()) ?? []
        sectors = (try? await factory.bookRepository.fetchSectors()) ?? []
        sessions = (try? await factory.bookRepository.fetchSessions(for: nil)) ?? []
        deck = try? await factory.getFlightDeckUseCase.execute()
        systems = Self.buildSystems(from: books)
        if !formation {
            withAnimation(OrbitReadsFactory.shared.reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.7, dampingFraction: 0.75)) {
                formation = true
            }
        }
    }

    func scan(_ isbn: String) async {
        _ = try? await OrbitReadsFactory.shared.addBookUseCase.execute(isbn: isbn)
        await load()
    }

    var focusPoint: CGPoint {
        guard !books.isEmpty else {
            return CGPoint(x: OrbitReadsMetadata.mapWidth / 2, y: OrbitReadsMetadata.mapHeight / 2)
        }
        let x = books.map(\.positionX).reduce(0, +) / Double(books.count)
        let y = books.map(\.positionY).reduce(0, +) / Double(books.count)
        return CGPoint(x: x, y: y)
    }

    static func buildSystems(from books: [OrbitReadsBook]) -> [StarSystem] {
        Dictionary(grouping: books, by: \.author).map { author, group in
            let cx = group.map(\.positionX).reduce(0, +) / Double(max(group.count, 1))
            let cy = group.map(\.positionY).reduce(0, +) / Double(max(group.count, 1))
            return StarSystem(
                id: UUID(),
                author: author,
                sectorId: group.first?.sectorId ?? UUID(),
                centerX: cx,
                centerY: cy,
                bookIds: group.map(\.id)
            )
        }
    }
}

extension OrbitReadsFactory {
    var reduceMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
}

struct GalaxyCanvasView: View {
    @Bindable var coordinator: OrbitReadsCoordinator
    @State private var vm = GalaxyCanvasViewModel()
    @State private var scale: CGFloat = 0.7
    @State private var baseScale: CGFloat = 0.7
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragVelocity: CGSize = .zero
    @State private var didCenter = false
    @State private var viewport: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let mapSize = CGSize(width: OrbitReadsMetadata.mapWidth, height: OrbitReadsMetadata.mapHeight)

    var body: some View {
        ZStack {
            OrbitTheme.nebulaDark.ignoresSafeArea()
            mapLayer
            FlightDeckHUD(
                deck: vm.deck,
                onRoute: { coordinator.openRoutePlanner() },
                onTrajectory: { coordinator.toggleTrajectory() },
                onScan: { coordinator.openScanner() },
                onSettings: { coordinator.openSettings() }
            )
            if coordinator.overlay == .trajectory {
                TrajectoryAnalyticsOverlay(
                    sessions: vm.sessions,
                    books: vm.books,
                    onClose: { coordinator.dismissOverlay() }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .navigationBarHidden(true)
        .task {
            await vm.load()
            centerOnBooks(animated: !reduceMotion)
        }
        .onChange(of: vm.books.count) { _, _ in
            centerOnBooks(animated: !reduceMotion)
        }
        .sheet(item: $coordinator.activeSheet) { sheet in
            switch sheet {
            case .planetDetail(let id):
                if let book = vm.books.first(where: { $0.id == id }) {
                    PlanetDetailSheet(book: book, coordinator: coordinator) {
                        Task { await vm.load() }
                    }
                }
            case .routePlanner:
                RoutePlannerSheet(coordinator: coordinator) {
                    Task { await vm.load() }
                }
            case .scanner:
                OrbitScannerView { isbn in
                    Task { await vm.scan(isbn) }
                }
            case .asteroidDodge(let bookId):
                AsteroidDodgeView(bookId: bookId) {
                    Task { await vm.load() }
                }
            case .settings:
                OrbitReadsSettingsView()
            }
        }
        .navigationDestination(for: OrbitReadsRoute.self) { route in
            if route == .expeditionRun, let id = coordinator.expeditionRunId {
                ExpeditionRunView(expeditionId: id) {
                    Task { await vm.load() }
                }
            }
        }
    }

    private var mapLayer: some View {
        GeometryReader { geo in
            let centered = mapOrigin(in: geo.size)
            ZStack(alignment: .topLeading) {
                Canvas { context, size in
                    drawStars(context: context, size: size)
                    drawSectors(context: context)
                    drawSystemLinks(context: context)
                    drawOrbitPaths(context: context)
                }
                .frame(width: mapSize.width, height: mapSize.height)
                .scaleEffect(vm.formation ? scale : scale * 0.35)
                .opacity(vm.formation ? 1 : 0.25)
                .offset(centered)
                .gesture(panGesture)
                .simultaneousGesture(zoomGesture)

                ForEach(vm.books) { book in
                    planetNode(book)
                        .position(
                            x: centered.width + CGFloat(book.positionX) * scale,
                            y: centered.height + CGFloat(book.positionY) * scale
                        )
                        .scaleEffect(vm.formation ? 1 : 0.2)
                        .opacity(vm.formation ? 1 : 0)
                }
            }
            .clipped()
            .ignoresSafeArea()
            .onAppear {
                viewport = geo.size
                centerOnBooks(animated: false)
            }
            .onChange(of: geo.size) { _, newSize in
                viewport = newSize
                if !didCenter || vm.books.isEmpty == false {
                    centerOnBooks(animated: false)
                }
            }
        }
    }

    private func planetNode(_ book: OrbitReadsBook) -> some View {
        let diameter: CGFloat = 64
        let ring = diameter + 10
        return Button {
            coordinator.openPlanet(book.id)
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    OrbitReadsBookCoverImage(
                        book: book,
                        width: diameter,
                        height: diameter,
                        cornerRadius: diameter / 2,
                        placeholderFill: OrbitTheme.violet.opacity(0.45),
                        placeholderIconColor: OrbitTheme.cyan
                    )
                    .clipShape(Circle())

                    Circle()
                        .stroke(OrbitTheme.star.opacity(0.15), lineWidth: 3)
                        .frame(width: ring, height: ring)

                    Circle()
                        .trim(from: 0, to: max(0.02, book.progress))
                        .stroke(OrbitTheme.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: ring, height: ring)
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: ring, height: ring)

                Text(book.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(OrbitTheme.star)
                    .lineLimit(1)
                    .frame(width: 88)
                Text(book.author)
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(OrbitTheme.star.opacity(0.55))
                    .lineLimit(1)
                    .frame(width: 88)
            }
        }
        .buttonStyle(.plain)
    }

    private func mapOrigin(in size: CGSize) -> CGSize {
        CGSize(
            width: (size.width - mapSize.width * scale) / 2 + offset.width,
            height: (size.height - mapSize.height * scale) / 2 + offset.height
        )
    }

    private func centerOnBooks(animated: Bool = false) {
        let size = viewport
        guard size.width > 0, size.height > 0 else { return }
        let focus = vm.focusPoint
        let next = CGSize(
            width: (mapSize.width / 2 - focus.x) * scale,
            height: (mapSize.height / 2 - focus.y) * scale
        )
        let apply = {
            offset = next
            lastOffset = next
            didCenter = true
        }
        if animated {
            withAnimation(.easeOut(duration: 0.35), apply)
        } else {
            apply()
        }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
                dragVelocity = CGSize(width: value.velocity.width, height: value.velocity.height)
            }
            .onEnded { _ in
                lastOffset = offset
                guard !reduceMotion else { return }
                let inertia = CGSize(width: dragVelocity.width * 0.08, height: dragVelocity.height * 0.08)
                withAnimation(.interpolatingSpring(stiffness: 80, damping: 16)) {
                    offset = CGSize(width: offset.width + inertia.width, height: offset.height + inertia.height)
                    lastOffset = offset
                }
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(1.6, max(0.35, baseScale * value))
            }
            .onEnded { _ in
                baseScale = scale
            }
    }

    private func drawStars(context: GraphicsContext, size: CGSize) {
        var rng = SeededGenerator(seed: 42)
        for _ in 0..<180 {
            let x = CGFloat.random(in: 0...size.width, using: &rng)
            let y = CGFloat.random(in: 0...size.height, using: &rng)
            let r = CGFloat.random(in: 0.4...2.0, using: &rng)
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                with: .color(.white.opacity(Double.random(in: 0.12...0.65, using: &rng)))
            )
        }
    }

    private func drawSectors(context: GraphicsContext) {
        for sector in vm.sectors {
            let rect = CGRect(
                x: sector.centerX - sector.radius,
                y: sector.centerY - sector.radius,
                width: sector.radius * 2,
                height: sector.radius * 2
            )
            let color = OrbitTheme.sectorColor(hue: sector.hue, unlocked: sector.isUnlocked)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(sector.isUnlocked ? 0.12 : 0.05)))
            context.stroke(Path(ellipseIn: rect), with: .color(color.opacity(0.35)), lineWidth: 1.2)
            context.draw(
                Text(sector.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(color.opacity(0.85)),
                at: CGPoint(x: sector.centerX, y: sector.centerY - sector.radius + 18),
                anchor: .center
            )
        }
    }

    private func drawSystemLinks(context: GraphicsContext) {
        for system in vm.systems {
            let planets = vm.books.filter { system.bookIds.contains($0.id) }
            guard planets.count > 1 else { continue }
            var path = Path()
            for (i, book) in planets.enumerated() {
                let point = CGPoint(x: book.positionX, y: book.positionY)
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            context.stroke(path, with: .color(OrbitTheme.cyan.opacity(0.2)), style: StrokeStyle(lineWidth: 1, dash: [4, 6]))
        }
    }

    private func drawOrbitPaths(context: GraphicsContext) {
        for book in vm.books {
            let r = max(36, book.orbitRadius * 0.55)
            let rect = CGRect(x: book.positionX - r, y: book.positionY - r, width: r * 2, height: r * 2)
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(OrbitTheme.aqua.opacity(0.22)),
                style: StrokeStyle(lineWidth: 1, dash: [3, 5])
            )
        }
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1
        return state
    }
}
