import Foundation
import SwiftData
import Observation

struct DeloadAlert {
    let recommended: Bool
    let confidence: String
    let reason: String
    let signals: [String]
}

@Observable
final class HomeViewModel {
    var recentSessions: [CachedWorkoutSession] = []
    var weeklySessionCount = 0
    var isLoading = false
    var deloadAlert: DeloadAlert?

    // Next workout from cycle tracker
    var nextWorkout: APINextWorkoutResponse?
    var exerciseNames: [Int: String] = [:]
    var nextWorkoutError: String?

    func loadNextWorkout(apiClient: APIClient, userId: Int) async {
        do {
            nextWorkout = try await apiClient.fetchNextWorkout(userId: userId)

            // Load exercise names if needed
            if exerciseNames.isEmpty {
                let exerciseList = try await apiClient.fetchExercises()
                for ex in exerciseList.exercises {
                    exerciseNames[ex.id] = ex.name
                }
            }
        } catch {
            print("loadNextWorkout error: \(error)")
            nextWorkoutError = nil // Not having a next workout is fine (no plan yet)
            nextWorkout = nil
        }
    }

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

    func checkDeload(apiClient: APIClient, userId: Int) async {
        struct DeloadSignal: Codable {
            let signal: String
            let description: String
            let severity: String
        }

        struct DeloadResponse: Codable {
            let deloadRecommended: Bool
            let confidence: String
            let reason: String
            let signals: [DeloadSignal]

            enum CodingKeys: String, CodingKey {
                case confidence, reason, signals
                case deloadRecommended = "deload_recommended"
            }
        }

        do {
            let response: DeloadResponse = try await apiClient.get(
                "/api/deload/\(userId)/check"
            )
            if response.deloadRecommended {
                deloadAlert = DeloadAlert(
                    recommended: true,
                    confidence: response.confidence,
                    reason: response.reason,
                    signals: response.signals.map { $0.description }
                )
            } else {
                deloadAlert = nil
            }
        } catch {
            // Non-critical — don't show error
        }
    }
}
