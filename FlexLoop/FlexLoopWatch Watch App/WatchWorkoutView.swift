import SwiftUI

struct WatchWorkoutView: View {
    let exercises: [WatchExerciseData]
    @EnvironmentObject var sessionManager: WatchSessionManager

    @State private var currentIndex = 0
    @State private var setNumber = 1
    @State private var weight = 0.0
    @State private var reps = 8
    @State private var showRestTimer = false
    @State private var totalSets = 0
    @Environment(\.dismiss) private var dismiss

    private var currentExercise: WatchExerciseData? {
        guard currentIndex < exercises.count else { return nil }
        return exercises[currentIndex]
    }

    var body: some View {
        if let exercise = currentExercise {
            exerciseView(exercise)
                .onAppear { loadExerciseDefaults(exercise) }
                .navigationBarBackButtonHidden(true)
                .sheet(isPresented: $showRestTimer) {
                    WatchRestTimerView(seconds: exercise.restSec) {
                        showRestTimer = false
                    }
                }
        } else {
            workoutCompleteView
        }
    }

    private func exerciseView(_ exercise: WatchExerciseData) -> some View {
        VStack(spacing: 6) {
            Text(exercise.name)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)

            Text("Set \(setNumber) of \(exercise.sets)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                VStack {
                    Text("\(weight, specifier: "%.1f")")
                        .font(.title3.monospacedDigit().bold())
                    Text("kg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .focusable()
                .digitalCrownRotation($weight, from: 0, through: 500, by: 2.5)

                Text("x")
                    .foregroundStyle(.secondary)

                VStack {
                    Text("\(reps)")
                        .font(.title3.monospacedDigit().bold())
                    Text("reps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button {
                    logSet(exercise)
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Text("\(totalSets) sets done")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var workoutCompleteView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Workout Complete!")
                .font(.headline)
            Text("\(totalSets) total sets")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func loadExerciseDefaults(_ exercise: WatchExerciseData) {
        weight = exercise.weight ?? 0
        reps = exercise.reps
        setNumber = 1
    }

    private func logSet(_ exercise: WatchExerciseData) {
        totalSets += 1

        if setNumber >= exercise.sets {
            // Move to next exercise
            setNumber = 1
            currentIndex += 1
            if let next = currentExercise {
                loadExerciseDefaults(next)
            }
        } else {
            setNumber += 1
        }

        showRestTimer = true
    }
}

#Preview {
    WatchWorkoutView(exercises: [
        WatchExerciseData(name: "Bench Press", sets: 4, reps: 8, weight: 80,
                          rpeTarget: 8, groupType: "straight", restSec: 90),
    ])
    .environmentObject(WatchSessionManager.shared)
}
