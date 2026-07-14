import SwiftUI

struct RoutePlannerSheet: View {
    let coordinator: OrbitReadsCoordinator
    let onChanged: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var expeditions: [Expedition] = []
    @State private var sectors: [GalaxySector] = []
    @State private var books: [OrbitReadsBook] = []
    @State private var selectedRoute: Set<UUID> = []
    @State private var trace: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Unlock sectors with expedition fuel from reading and Asteroid Dodge bonus.")
                        .font(OrbitTheme.sans)
                        .foregroundStyle(OrbitTheme.star.opacity(0.7))

                    ForEach(expeditions) { expedition in
                        expeditionCard(expedition)
                    }

                    Text("Route planets")
                        .font(OrbitTheme.title)
                        .foregroundStyle(OrbitTheme.cyan)
                    ForEach(books) { book in
                        Button {
                            if selectedRoute.contains(book.id) { selectedRoute.remove(book.id) }
                            else { selectedRoute.insert(book.id) }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(selectedRoute.contains(book.id) ? OrbitTheme.cyan : OrbitTheme.glass)
                                    .frame(width: 12, height: 12)
                                VStack(alignment: .leading) {
                                    Text(book.title).foregroundStyle(OrbitTheme.star).lineLimit(1)
                                    Text(book.author).font(.caption).foregroundStyle(OrbitTheme.star.opacity(0.5))
                                }
                                Spacer()
                            }
                            .padding(10)
                            .background(OrbitTheme.glass)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding()
            }
            .orbitScreenStyle()
            .navigationTitle("Route Planner")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await load() }
            .onAppear {
                withAnimation(reduceMotion ? .linear(duration: 0.1) : .easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    trace = 1
                }
            }
        }
    }

    private func expeditionCard(_ expedition: Expedition) -> some View {
        let sector = sectors.first { $0.id == expedition.targetSectorId }
        return NebulaGlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(expedition.name).font(OrbitTheme.sans.bold()).foregroundStyle(OrbitTheme.cyan)
                    Spacer()
                    Text(sector?.name ?? "Sector")
                        .font(OrbitTheme.mono)
                        .foregroundStyle(OrbitTheme.star.opacity(0.6))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(OrbitTheme.glassStroke).frame(height: 8)
                        Capsule()
                            .fill(LinearGradient(colors: [OrbitTheme.violet, OrbitTheme.cyan], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * expedition.progress * (0.7 + 0.3 * trace), height: 8)
                    }
                }
                .frame(height: 8)
                Text("\(expedition.fuelCollected)/\(expedition.fuelRequired) fuel")
                    .font(OrbitTheme.mono)
                    .foregroundStyle(OrbitTheme.star.opacity(0.7))
                HStack {
                    Button("Set Route") {
                        Task {
                            _ = try? await OrbitReadsFactory.shared.startExpeditionUseCase.execute(
                                expeditionId: expedition.id,
                                routeBookIds: Array(selectedRoute)
                            )
                            await load()
                            onChanged()
                        }
                    }
                    .font(OrbitTheme.mono.weight(.bold))
                    .foregroundStyle(OrbitTheme.nebulaDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(OrbitTheme.cyan)
                    .clipShape(Capsule())

                    if expedition.isReady && !expedition.isUnlocked {
                        Button("Unlock Sector") {
                            Task {
                                _ = try? await OrbitReadsFactory.shared.unlockSectorUseCase.execute(expeditionId: expedition.id)
                                await load()
                                onChanged()
                            }
                        }
                        .font(OrbitTheme.mono.weight(.bold))
                        .foregroundStyle(OrbitTheme.cyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(Capsule().stroke(OrbitTheme.cyan, lineWidth: 1))
                    }

                    Button("Run") {
                        dismiss()
                        coordinator.openExpeditionRun(expedition.id)
                    }
                    .font(OrbitTheme.mono)
                    .foregroundStyle(OrbitTheme.magenta)
                }
            }
        }
    }

    private func load() async {
        let repo = OrbitReadsFactory.shared.bookRepository
        expeditions = (try? await repo.fetchExpeditions()) ?? []
        sectors = (try? await repo.fetchSectors()) ?? []
        books = (try? await repo.fetchAll()) ?? []
        if let route = expeditions.first?.routeBookIds {
            selectedRoute = Set(route)
        }
    }
}
