import SwiftUI

struct TrajectoryAnalyticsOverlay: View {
    let sessions: [OrbitReadsReadingSession]
    let books: [OrbitReadsBook]
    let onClose: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appearBars = false

    private var sortedSessions: [OrbitReadsReadingSession] {
        sessions.sorted { $0.date < $1.date }
    }

    private var recentSessions: [OrbitReadsReadingSession] {
        Array(sortedSessions.suffix(8).reversed())
    }

    private var maxPages: Int {
        max(sortedSessions.map(\.pagesRead).max() ?? 1, 1)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)

            VStack(spacing: 0) {
                header
                if sortedSessions.isEmpty {
                    emptyState
                } else {
                    barsChart
                        .padding(.horizontal, 18)
                        .padding(.bottom, 12)
                    sessionList
                }
                statsRow
                    .padding(18)
            }
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(OrbitTheme.nebulaDark)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(OrbitTheme.cyan.opacity(0.35), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 40)
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : .spring(response: 0.55, dampingFraction: 0.82)) {
                appearBars = true
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Trajectory")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(OrbitTheme.cyan)
                Text("Reading path across spacetime")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(OrbitTheme.star.opacity(0.55))
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(OrbitTheme.star.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(OrbitTheme.nebulaMid)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 14)
    }

    private var emptyState: some View {
        Text("Log pages on a planet to chart a trajectory.")
            .font(.system(size: 14, design: .rounded))
            .foregroundStyle(OrbitTheme.star.opacity(0.5))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
            .padding(.vertical, 36)
    }

    private var barsChart: some View {
        let chartSessions = Array(sortedSessions.suffix(7))
        return VStack(alignment: .leading, spacing: 10) {
            Text("Pages per hop")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(OrbitTheme.star.opacity(0.45))

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(chartSessions.enumerated()), id: \.element.id) { _, session in
                    let ratio = CGFloat(session.pagesRead) / CGFloat(maxPages)
                    let height = appearBars ? max(18, 110 * ratio) : 8
                    VStack(spacing: 6) {
                        Text("\(session.pagesRead)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(OrbitTheme.cyan)
                            .opacity(appearBars ? 1 : 0)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [OrbitTheme.violet, OrbitTheme.cyan],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: height)
                    }
                }
            }
            .frame(height: 140)
            .padding(12)
            .background(OrbitTheme.nebula)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var sessionList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(recentSessions) { session in
                    let book = books.first { $0.id == session.bookId }
                    HStack(spacing: 12) {
                        if let book {
                            OrbitReadsBookCoverImage(
                                book: book,
                                width: 36,
                                height: 52,
                                cornerRadius: 4,
                                placeholderFill: OrbitTheme.violet.opacity(0.4),
                                placeholderIconColor: OrbitTheme.cyan
                            )
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(OrbitTheme.nebulaMid)
                                .frame(width: 36, height: 52)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(book?.title ?? "Unknown planet")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(OrbitTheme.star)
                                .lineLimit(1)
                            Text(session.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(OrbitTheme.star.opacity(0.45))
                        }
                        Spacer(minLength: 0)
                        Text("+\(session.pagesRead)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(OrbitTheme.cyan)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(OrbitTheme.nebula.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(.horizontal, 18)
        }
        .frame(maxHeight: 220)
    }

    private var statsRow: some View {
        HStack {
            metric("Sessions", "\(sessions.count)")
            metric("Planets", "\(books.count)")
            metric("Pages", "\(sessions.reduce(0) { $0 + $1.pagesRead })")
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(OrbitTheme.cyan)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(OrbitTheme.star.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}
