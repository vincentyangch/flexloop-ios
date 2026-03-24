import Foundation
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

@Observable
final class ActiveWorkoutViewModel {
    var currentSession: CachedWorkoutSession?
    var loggedSets: [CachedWorkoutSet] = []
    var isRestTimerActive = false
    var restTimeRemaining = 0
    var isWorkoutActive = false
    var currentPRAlert: PRAlert?
    var showPRAlert = false

    private var restTimer: Timer?

    func startWorkout(context: ModelContext, source: WorkoutSource = .adHoc,
                      planDayId: Int? = nil, templateId: Int? = nil) {
        let session = CachedWorkoutSession(
            planDayId: planDayId,
            templateId: templateId,
            source: source,
            startedAt: Date()
        )
        context.insert(session)
        try? context.save()

        currentSession = session
        loggedSets = []
        isWorkoutActive = true
    }

    func logSet(exerciseId: Int, weight: Double?, reps: Int?,
                rpe: Double? = nil, setType: SetType = .working,
                context: ModelContext) {
        guard let session = currentSession else { return }

        let setNumber = (loggedSets.last?.setNumber ?? 0) + 1

        let workoutSet = CachedWorkoutSet(
            session: session,
            exerciseServerId: exerciseId,
            setNumber: setNumber,
            setType: setType,
            weight: weight,
            reps: reps,
            rpe: rpe
        )
        context.insert(workoutSet)
        try? context.save()

        loggedSets.append(workoutSet)

        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Check for PRs asynchronously
        if let sessionId = currentSession?.serverId {
            Task {
                await checkPR(exerciseId: exerciseId, weight: weight, reps: reps,
                              sessionId: sessionId)
            }
        }
    }

    private func checkPR(exerciseId: Int, weight: Double?, reps: Int?,
                         sessionId: Int) async {
        let apiClient = await APIClient(config: .current)

        struct PRCheckBody: Codable {
            let exerciseId: Int
            let weight: Double?
            let reps: Int?

            enum CodingKeys: String, CodingKey {
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
            guard let url = await apiClient.buildURL(path: "/api/workouts/\(sessionId)/check-pr") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(
                PRCheckBody(exerciseId: exerciseId, weight: weight, reps: reps)
            )

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(PRCheckResponse.self, from: data)

            if let firstPR = response.newPrs.first {
                await MainActor.run {
                    currentPRAlert = PRAlert(
                        type: firstPR.type,
                        value: firstPR.value,
                        previous: firstPR.previous,
                        detail: firstPR.detail
                    )
                    showPRAlert = true

                    // Extra strong haptic for PR!
                    let notification = UINotificationFeedbackGenerator()
                    notification.notificationOccurred(.success)
                }
            }
        } catch {
            // PR check is non-critical — don't interrupt the workout
        }
    }

    func completeWorkout(context: ModelContext) {
        let completedAt = Date()
        currentSession?.completedAt = completedAt
        try? context.save()
        isWorkoutActive = false
        stopRestTimer()

        // Save workout to HealthKit
        if let startedAt = currentSession?.startedAt {
            Task {
                try? await HealthKitManager.shared.saveWorkout(
                    startDate: startedAt, endDate: completedAt, caloriesBurned: nil
                )
            }
        }
    }

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
}
