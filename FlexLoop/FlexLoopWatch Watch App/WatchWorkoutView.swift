import SwiftUI

struct WatchWorkoutView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @Environment(\.dismiss) private var dismiss

    @State private var weight: Double = 0
    @State private var reps: Int = 8
    @State private var rpe: Double = 7.0
    @State private var showRestTimer = false
    @State private var restSeconds = 120

    private let unit = WeightUnit.current

    private var state: WorkoutSyncState? { sessionManager.workoutState }

    private var currentExercise: SyncExercise? {
        guard let state, state.exercises.indices.contains(state.currentExerciseIndex) else { return nil }
        return state.exercises[state.currentExerciseIndex]
    }

    private var currentSetNumber: Int {
        guard let exercise = currentExercise else { return 1 }
        return min(exercise.completedSets.count + 1, exercise.targets.count)
    }

    private var allSetsDone: Bool {
        guard let exercise = currentExercise else { return false }
        return exercise.completedSets.count >= exercise.targets.count
    }

    private var totalSetsCompleted: Int {
        state?.exercises.flatMap(\.completedSets).count ?? 0
    }

    var body: some View {
        Group {
            if let exercise = currentExercise {
                exerciseView(exercise)
            } else if let state, !state.isActive {
                workoutEndedView
            } else {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showRestTimer) {
            WatchRestTimerView(seconds: restSeconds) {
                showRestTimer = false
            }
        }
        .onChange(of: sessionManager.workoutState?.isActive) { _, isActive in
            if isActive == false || isActive == nil {
                dismiss()
            }
        }
        .onChange(of: sessionManager.workoutState?.currentExerciseIndex) { _, _ in
            loadCurrentExerciseDefaults()
        }
        .onAppear {
            loadCurrentExerciseDefaults()
        }
    }

    private func exerciseView(_ exercise: SyncExercise) -> some View {
        ScrollView {
            VStack(spacing: 6) {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.center)

                if allSetsDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("All sets done")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Next exercise on iPhone")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Button {
                        dismiss()
                    } label: {
                        Text("Back")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text("Set \(currentSetNumber) of \(exercise.targets.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Weight — Digital Crown
                    let displayWeight = unit.fromKgRounded(weight)
                    Text("\(displayWeight, specifier: "%.1f") \(unit.label)")
                        .font(.title3.monospacedDigit().bold())
                        .focusable()
                        .digitalCrownRotation($weight, from: 0, through: 250,
                                              by: unit == .metric ? 2.5 : 2.26796)

                    // Reps — +/- buttons
                    HStack {
                        Button { if reps > 1 { reps -= 1 } } label: {
                            Image(systemName: "minus").font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 36)

                        Text("\(reps) reps")
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 60)

                        Button { if reps < 99 { reps += 1 } } label: {
                            Image(systemName: "plus").font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 36)
                    }

                    // RPE — +/- buttons
                    HStack {
                        Button { if rpe > 1 { rpe -= 0.5 } } label: {
                            Image(systemName: "minus").font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 36)

                        Text("RPE \(rpe, specifier: "%.1f")")
                            .font(.subheadline.monospacedDigit())
                            .frame(width: 70)

                        Button { if rpe < 10 { rpe += 0.5 } } label: {
                            Image(systemName: "plus").font(.caption2)
                        }
                        .buttonStyle(.bordered)
                        .frame(width: 36)
                    }

                    // Action buttons
                    HStack(spacing: 12) {
                        Button {
                            completeSet(exercise)
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
                }

                Text("\(totalSetsCompleted) sets done")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    private var workoutEndedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.green)
            Text("Workout Complete!")
                .font(.headline)
            Text("\(totalSetsCompleted) total sets")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
    }

    private func loadCurrentExerciseDefaults() {
        guard let exercise = currentExercise else { return }
        let setIndex = exercise.completedSets.count
        let target = exercise.targets.indices.contains(setIndex)
            ? exercise.targets[setIndex] : exercise.targets.first

        weight = target?.weightKg ?? 0
        reps = target?.reps ?? 8
        rpe = target?.rpe ?? 7.0
        restSeconds = exercise.restSeconds
    }

    private func completeSet(_ exercise: SyncExercise) {
        guard let state else { return }

        sessionManager.sendCompleteSet(
            exerciseIndex: state.currentExerciseIndex,
            setNumber: currentSetNumber,
            weightKg: weight,
            reps: reps,
            rpe: rpe
        )

        showRestTimer = true
    }
}
