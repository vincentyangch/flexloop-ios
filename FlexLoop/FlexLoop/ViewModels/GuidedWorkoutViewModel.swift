import Foundation
import SwiftUI
import SwiftData
import Observation
import UIKit

struct PRAlert: Identifiable {
    let id = UUID()
    let type: String
    let value: Double
    let previous: Double
    let detail: String

    var title: String {
        switch type {
        case "estimated_1rm": return "New 1RM PR!"
        case "rep_at_weight": return "Rep PR!"
        case "volume": return "Volume PR!"
        default: return "New PR!"
        }
    }
}

struct GuidedExercise: Identifiable {
    let id = UUID()
    let exerciseId: Int
    let planExerciseId: Int?
    let name: String
    let restSeconds: Int
    var targetSets: [GuidedSetTarget]
    var completedSets: [CompletedSet] = []
    var isSkipped = false
    var notes: String?
}

struct GuidedSetTarget: Identifiable {
    let id = UUID()
    let setNumber: Int
    var targetWeightKg: Double?
    var targetReps: Int
    var targetRpe: Double?
}

struct CompletedSet: Identifiable {
    let id = UUID()
    let setNumber: Int
    var weightKg: Double?
    var reps: Int?
    var rpe: Double?
    var setType: SetType
    var completedAt: Date = Date()
}

struct WorkoutSummary {
    let exercisesCompleted: Int
    let exercisesSkipped: Int
    let totalSets: Int
    let duration: TimeInterval
    let newPRs: [PRAlert]
}

@Observable
final class GuidedWorkoutViewModel {
    var exercises: [GuidedExercise] = []
    var currentExerciseIndex = 0
    var isWorkoutActive = false
    var startedAt: Date?

    // Rest timer
    var isRestTimerActive = false
    var restTimeRemaining = 0
    private var restTimer: Timer?

    // PR alerts
    var currentPRAlert: PRAlert?
    var showPRAlert = false
    var detectedPRs: [PRAlert] = []

    // User
    var userId: Int = 0

    // Exercise sidebar
    var showExerciseList = false

    // Summary
    var workoutSummary: WorkoutSummary?
    var showSummary = false

    var currentExercise: GuidedExercise? {
        guard exercises.indices.contains(currentExerciseIndex) else { return nil }
        return exercises[currentExerciseIndex]
    }

    var progress: String {
        guard !exercises.isEmpty else { return "" }
        let nonSkipped = exercises.filter { !$0.isSkipped }
        let completed = nonSkipped.filter { !$0.completedSets.isEmpty }
        return "\(completed.count)/\(nonSkipped.count)"
    }

    var isLastExercise: Bool {
        currentExerciseIndex >= exercises.count - 1
    }

    // MARK: - Setup

    func loadFromPlanDay(_ day: APIPlanDay, exerciseNames: [Int: String]) {
        exercises = day.exerciseGroups.flatMap { group in
            group.exercises.map { ex in
                let targets: [GuidedSetTarget]
                if let setsJson = ex.setsJson, !setsJson.isEmpty {
                    targets = setsJson.enumerated().map { idx, target in
                        GuidedSetTarget(
                            setNumber: idx + 1,
                            targetWeightKg: target.targetWeightKg,
                            targetReps: target.targetReps,
                            targetRpe: target.targetRpe
                        )
                    }
                } else {
                    targets = (1...ex.sets).map { num in
                        GuidedSetTarget(
                            setNumber: num,
                            targetWeightKg: ex.weight,
                            targetReps: ex.reps,
                            targetRpe: ex.rpeTarget
                        )
                    }
                }

                return GuidedExercise(
                    exerciseId: ex.exerciseId,
                    planExerciseId: ex.id,
                    name: exerciseNames[ex.exerciseId] ?? "Exercise #\(ex.exerciseId)",
                    restSeconds: group.restAfterGroupSec,
                    targetSets: targets,
                    notes: ex.notes
                )
            }
        }
        currentExerciseIndex = 0
        isWorkoutActive = true
        startedAt = Date()
        // Task 4: PhoneConnectivityManager.shared.sendWorkoutStarted(stateSnapshot())
        PhoneConnectivityManager.shared.sendWorkoutStarted(stateSnapshot())
    }

    // MARK: - Set Completion

    func completeSet(
        exerciseIndex: Int,
        setNumber: Int,
        weightKg: Double?,
        reps: Int?,
        rpe: Double?,
        setType: SetType = .working
    ) {
        guard exercises.indices.contains(exerciseIndex) else { return }

        let completed = CompletedSet(
            setNumber: setNumber,
            weightKg: weightKg,
            reps: reps,
            rpe: rpe,
            setType: setType
        )
        exercises[exerciseIndex].completedSets.append(completed)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Auto-start rest timer
        startRestTimer(seconds: 120)

        // Check for PRs asynchronously
        Task {
            await checkPR(exerciseId: exercises[exerciseIndex].exerciseId,
                          weight: weightKg, reps: reps)
        }

        // Auto-advance to next exercise when all sets are done
        let targetCount = exercises[exerciseIndex].targetSets.count
        if exercises[exerciseIndex].completedSets.count >= targetCount {
            nextExercise()
        }

        PhoneConnectivityManager.shared.sendStateUpdate(stateSnapshot())
    }

    private func checkPR(exerciseId: Int, weight: Double?, reps: Int?) async {
        let apiClient = APIClient(config: .current)

        struct PRCheckBody: Codable {
            let userId: Int
            let exerciseId: Int
            let weight: Double?
            let reps: Int?

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case exerciseId = "exercise_id"
                case weight, reps
            }
        }

        struct PRCheckResponse: Codable {
            let newPrs: [PRData]
            enum CodingKeys: String, CodingKey {
                case newPrs = "new_prs"
            }
        }

        struct PRData: Codable {
            let type: String
            let value: Double
            let previous: Double
            let detail: String
        }

        do {
            guard let url = await apiClient.buildURL(path: "/api/check-pr") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(
                PRCheckBody(userId: userId, exerciseId: exerciseId, weight: weight, reps: reps)
            )
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(PRCheckResponse.self, from: data)

            if let firstPR = response.newPrs.first {
                await MainActor.run {
                    let alert = PRAlert(
                        type: firstPR.type,
                        value: firstPR.value,
                        previous: firstPR.previous,
                        detail: firstPR.detail
                    )
                    currentPRAlert = alert
                    detectedPRs.append(alert)
                    showPRAlert = true

                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)
                }
            }
        } catch {
            // PR check is non-critical
        }
    }

    func editCompletedSet(exerciseIndex: Int, setId: UUID, weightKg: Double?, reps: Int?, rpe: Double?) {
        guard exercises.indices.contains(exerciseIndex),
              let setIdx = exercises[exerciseIndex].completedSets.firstIndex(where: { $0.id == setId })
        else { return }

        exercises[exerciseIndex].completedSets[setIdx].weightKg = weightKg
        exercises[exerciseIndex].completedSets[setIdx].reps = reps
        exercises[exerciseIndex].completedSets[setIdx].rpe = rpe
    }

    // MARK: - Exercise Navigation

    func nextExercise() {
        stopRestTimer()
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            // Skip already-skipped exercises
            while currentExerciseIndex < exercises.count - 1 && exercises[currentExerciseIndex].isSkipped {
                currentExerciseIndex += 1
            }
        }
    }

    func previousExercise() {
        stopRestTimer()
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            while currentExerciseIndex > 0 && exercises[currentExerciseIndex].isSkipped {
                currentExerciseIndex -= 1
            }
        }
    }

    func jumpToExercise(_ index: Int) {
        guard exercises.indices.contains(index) else { return }
        stopRestTimer()
        currentExerciseIndex = index
    }

    func skipExercise() {
        guard exercises.indices.contains(currentExerciseIndex) else { return }
        exercises[currentExerciseIndex].isSkipped = true
        nextExercise()
        // Task 4: PhoneConnectivityManager.shared.sendStateUpdate(stateSnapshot())
        PhoneConnectivityManager.shared.sendStateUpdate(stateSnapshot())
    }

    func reorderExercise(from: IndexSet, to: Int) {
        exercises.move(fromOffsets: from, toOffset: to)
    }

    // MARK: - Rest Timer

    func startRestTimer(seconds: Int) {
        stopRestTimer()
        restTimeRemaining = seconds
        isRestTimerActive = true

        restTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            if self.restTimeRemaining > 0 {
                self.restTimeRemaining -= 1
            } else {
                self.isRestTimerActive = false
                timer.invalidate()
                let notification = UINotificationFeedbackGenerator()
                notification.notificationOccurred(.success)
            }
        }
    }

    func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isRestTimerActive = false
        restTimeRemaining = 0
    }

    // MARK: - Workout Completion

    func finishWorkout(context: ModelContext, userId: Int, planDayId: Int?) {
        stopRestTimer()
        isWorkoutActive = false

        let session = CachedWorkoutSession(
            userId: userId,
            planDayId: planDayId,
            source: .plan,
            startedAt: startedAt ?? Date()
        )
        session.completedAt = Date()
        context.insert(session)

        var setCounter = 0
        for exercise in exercises where !exercise.isSkipped {
            for completed in exercise.completedSets {
                setCounter += 1
                let workoutSet = CachedWorkoutSet(
                    session: session,
                    exerciseServerId: exercise.exerciseId,
                    setNumber: setCounter,
                    setType: completed.setType,
                    weight: completed.weightKg,
                    reps: completed.reps,
                    rpe: completed.rpe
                )
                context.insert(workoutSet)
            }
        }

        try? context.save()

        // Save workout to HealthKit
        let completedAt = session.completedAt ?? Date()
        if let start = startedAt {
            Task {
                try? await HealthKitManager.shared.saveWorkout(
                    startDate: start, endDate: completedAt, caloriesBurned: nil
                )
            }
        }

        let duration = Date().timeIntervalSince(startedAt ?? Date())
        workoutSummary = WorkoutSummary(
            exercisesCompleted: exercises.filter { !$0.isSkipped && !$0.completedSets.isEmpty }.count,
            exercisesSkipped: exercises.filter { $0.isSkipped }.count,
            totalSets: exercises.flatMap(\.completedSets).count,
            duration: duration,
            newPRs: detectedPRs
        )
        // Task 4: PhoneConnectivityManager.shared.sendWorkoutEnded(reason: "finished")
        PhoneConnectivityManager.shared.sendWorkoutEnded(reason: "finished")
        showSummary = true
    }

    // MARK: - Watch Sync

    func stateSnapshot() -> WorkoutSyncState {
        WorkoutSyncState(
            isActive: isWorkoutActive,
            currentExerciseIndex: currentExerciseIndex,
            exercises: exercises.map { ex in
                SyncExercise(
                    exerciseId: ex.exerciseId,
                    name: ex.name,
                    isSkipped: ex.isSkipped,
                    restSeconds: ex.restSeconds,
                    targets: ex.targetSets.map { t in
                        SyncSetTarget(
                            setNumber: t.setNumber,
                            weightKg: t.targetWeightKg,
                            reps: t.targetReps,
                            rpe: t.targetRpe
                        )
                    },
                    completedSets: ex.completedSets.map { c in
                        SyncCompletedSet(
                            setNumber: c.setNumber,
                            weightKg: c.weightKg,
                            reps: c.reps,
                            rpe: c.rpe
                        )
                    }
                )
            },
            restTimerRemaining: isRestTimerActive ? restTimeRemaining : nil,
            startedAt: startedAt ?? Date()
        )
    }

    func advanceCycle(apiClient: APIClient, userId: Int) async {
        do {
            _ = try await apiClient.completeWorkout(userId: userId)
        } catch {
            // Non-critical — cycle will be advanced on next sync
        }
    }
}
