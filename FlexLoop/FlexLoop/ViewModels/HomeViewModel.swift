import Foundation
import SwiftData
import Observation

@Observable
final class HomeViewModel {
    var recentSessions: [CachedWorkoutSession] = []
    var weeklySessionCount = 0
    var isLoading = false

    func loadDashboard(context: ModelContext) {
        let descriptor = FetchDescriptor<CachedWorkoutSession>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        recentSessions = Array((try? context.fetch(descriptor))?.prefix(5) ?? [])

        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents(
            [.yearForWeekOfYear, .weekOfYear], from: Date()
        ))!
        let weekDescriptor = FetchDescriptor<CachedWorkoutSession>(
            predicate: #Predicate { $0.startedAt >= weekStart }
        )
        weeklySessionCount = (try? context.fetchCount(weekDescriptor)) ?? 0
    }
}
