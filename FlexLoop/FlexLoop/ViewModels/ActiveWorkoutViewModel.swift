import Foundation
import SwiftData
import Observation
import UIKit

@Observable
final class ActiveWorkoutViewModel {
    var currentSession: CachedWorkoutSession?
    var loggedSets: [CachedWorkoutSet] = []
    var isRestTimerActive = false
    var restTimeRemaining = 0
    var isWorkoutActive = false

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
    }

    func completeWorkout(context: ModelContext) {
        currentSession?.completedAt = Date()
        try? context.save()
        isWorkoutActive = false
        stopRestTimer()
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
