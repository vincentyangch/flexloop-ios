import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if let state = sessionManager.workoutState, state.isActive {
                    activeWorkoutView(state)
                } else {
                    inactiveView
                }
            }
            .navigationTitle("FlexLoop")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                sessionManager.requestState()
            }
        }
    }

    private func activeWorkoutView(_ state: WorkoutSyncState) -> some View {
        let exercise = state.exercises.indices.contains(state.currentExerciseIndex)
            ? state.exercises[state.currentExerciseIndex] : nil

        return VStack(spacing: 8) {
            Text("Workout Active")
                .font(.caption)
                .foregroundStyle(.green)

            if let exercise {
                Text(exercise.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)

                let completed = exercise.completedSets.count
                let total = exercise.targets.count
                Text("Set \(completed + 1) of \(total)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            NavigationLink("Continue") {
                WatchWorkoutView()
                    .environmentObject(sessionManager)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }

    private var inactiveView: some View {
        VStack(spacing: 8) {
            Text("No Active Workout")
                .font(.headline)

            Text("Start a workout\nfrom iPhone")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
