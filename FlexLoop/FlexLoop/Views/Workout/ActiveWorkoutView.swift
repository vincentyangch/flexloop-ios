import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActiveWorkoutViewModel()

    @State private var currentWeight: Double?
    @State private var currentReps: Int?
    @State private var currentRPE: Double?
    @State private var currentSetType: SetType = .working
    @State private var selectedExerciseId: Int?

    @Query(sort: \CachedExercise.name) private var exercises: [CachedExercise]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                RestTimerView(
                    timeRemaining: viewModel.restTimeRemaining,
                    isActive: viewModel.isRestTimerActive,
                    onStop: { viewModel.stopRestTimer() }
                )
                .padding(.horizontal)

                List {
                    Section("Exercise") {
                        Picker("Select Exercise", selection: $selectedExerciseId) {
                            Text("Select...").tag(nil as Int?)
                            ForEach(exercises) { exercise in
                                Text(exercise.name).tag(exercise.serverId as Int?)
                            }
                        }
                    }

                    if selectedExerciseId != nil {
                        Section("Log Set") {
                            SetEntryRow(
                                setNumber: viewModel.loggedSets.count + 1,
                                previousWeight: viewModel.loggedSets.last?.weight,
                                previousReps: viewModel.loggedSets.last?.reps,
                                weight: $currentWeight,
                                reps: $currentReps,
                                rpe: $currentRPE,
                                setType: $currentSetType
                            )

                            Button("Log Set") {
                                guard let exerciseId = selectedExerciseId else { return }
                                viewModel.logSet(
                                    exerciseId: exerciseId,
                                    weight: currentWeight,
                                    reps: currentReps,
                                    rpe: currentRPE,
                                    setType: currentSetType,
                                    context: context
                                )

                                let restTime = currentSetType == .warmUp ? 30 : 90
                                viewModel.startRestTimer(seconds: restTime)

                                currentReps = nil
                                currentRPE = nil
                            }
                            .disabled(currentWeight == nil && currentReps == nil)
                        }
                    }

                    if !viewModel.loggedSets.isEmpty {
                        Section("Completed Sets (\(viewModel.loggedSets.count))") {
                            ForEach(viewModel.loggedSets, id: \.setNumber) { set in
                                HStack {
                                    Text("Set \(set.setNumber)")
                                        .font(.subheadline)
                                    Spacer()
                                    if let w = set.weight, let r = set.reps {
                                        Text("\(w, specifier: "%.1f") x \(r)")
                                    }
                                    if let rpe = set.rpe {
                                        Text("RPE \(rpe, specifier: "%.1f")")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        viewModel.completeWorkout(context: context)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if viewModel.currentSession == nil {
                    viewModel.startWorkout(context: context)
                }
            }
        }
    }
}
