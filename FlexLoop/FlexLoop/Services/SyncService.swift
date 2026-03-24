import Foundation
import SwiftData

struct SyncService {
    static func findUnsyncedSessions(in context: ModelContext) -> [CachedWorkoutSession] {
        let descriptor = FetchDescriptor<CachedWorkoutSession>(
            predicate: #Predicate { $0.isSynced == false }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    static func buildSyncRequest(userId: Int,
                                  sessions: [CachedWorkoutSession]) -> APISyncRequest {
        let formatter = ISO8601DateFormatter()

        let workouts = sessions.map { session in
            let sets = (session.sets ?? []).map { set in
                APISyncSet(
                    exerciseId: set.exerciseServerId,
                    exerciseGroupId: set.exerciseGroupId,
                    setNumber: set.setNumber,
                    setType: set.setType.rawValue,
                    weight: set.weight,
                    reps: set.reps,
                    rpe: set.rpe,
                    durationSec: set.durationSec,
                    distanceM: set.distanceM,
                    restSec: set.restSec
                )
            }

            return APISyncWorkout(
                planDayId: session.planDayId,
                templateId: session.templateId,
                source: session.source.rawValue,
                startedAt: formatter.string(from: session.startedAt),
                completedAt: session.completedAt.map { formatter.string(from: $0) },
                notes: session.notes,
                sets: sets
            )
        }

        return APISyncRequest(userId: userId, workouts: workouts)
    }

    static func performSync(apiClient: APIClient, context: ModelContext,
                             userId: Int) async throws -> Int {
        let unsyncedSessions = findUnsyncedSessions(in: context)
        guard !unsyncedSessions.isEmpty else { return 0 }

        let request = buildSyncRequest(userId: userId, sessions: unsyncedSessions)
        let response = try await apiClient.syncWorkouts(request: request)

        for session in unsyncedSessions {
            session.isSynced = true
        }
        try context.save()

        return response.workoutsSynced
    }
}
