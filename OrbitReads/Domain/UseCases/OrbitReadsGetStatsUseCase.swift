import Foundation

struct OrbitReadsGetStatsUseCase: Sendable {
    private let repository: OrbitReadsBookRepositoryProtocol

    init(repository: OrbitReadsBookRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> OrbitReadsReadingStats {
        let sessions = try await repository.fetchSessions(for: nil)
        let calendar = Calendar.current
        let dailyPages = Dictionary(
            grouping: sessions,
            by: { calendar.startOfDay(for: $0.date) }
        ).mapValues { $0.reduce(0) { $0 + $1.pagesRead } }

        let totalPages = sessions.reduce(0) { $0 + $1.pagesRead }
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let pagesThisWeek = sessions
            .filter { $0.date >= weekAgo }
            .reduce(0) { $0 + $1.pagesRead }

        let sessionCount = max(sessions.count, 1)
        let avgPages = Double(totalPages) / Double(sessionCount)

        let (current, best) = calculateStreaks(dailyPages: dailyPages, calendar: calendar)
        let consistency = min(100, current * 10 + min(pagesThisWeek / 7, 30))

        return OrbitReadsReadingStats(
            currentStreak: current,
            bestStreak: best,
            totalPages: totalPages,
            pagesThisWeek: pagesThisWeek,
            averagePagesPerSession: avgPages,
            consistencyScore: consistency,
            dailyPages: dailyPages
        )
    }

    private func calculateStreaks(dailyPages: [Date: Int], calendar: Calendar) -> (Int, Int) {
        var current = 0
        var best = 0
        var day = calendar.startOfDay(for: Date())

        while dailyPages[day, default: 0] > 0 {
            current += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }

        let sortedDays = dailyPages.keys.sorted()
        var streak = 0
        for (index, d) in sortedDays.enumerated() {
            if dailyPages[d, default: 0] > 0 {
                if index == 0 { streak = 1 }
                else if let prev = calendar.date(byAdding: .day, value: -1, to: d),
                        sortedDays.contains(prev) {
                    streak += 1
                } else { streak = 1 }
                best = max(best, streak)
            }
        }
        return (current, max(best, current))
    }
}
