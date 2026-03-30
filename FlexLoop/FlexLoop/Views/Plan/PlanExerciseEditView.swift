import SwiftUI

struct PlanExerciseEditView: View {
    @Binding var exercise: EditablePlanExercise
    let exerciseName: String
    let unitSymbol: String

    @State private var setTargets: [EditableSetTarget] = []

    init(exercise: Binding<EditablePlanExercise>, exerciseName: String, unitSymbol: String) {
        _exercise = exercise
        self.exerciseName = exerciseName
        self.unitSymbol = unitSymbol

        // Initialize set targets from setsJson or generate defaults (values are already in user's unit)
        if let setsJson = exercise.wrappedValue.setsJson, !setsJson.isEmpty {
            _setTargets = State(initialValue: setsJson.map { target in
                EditableSetTarget(
                    setNumber: target.setNumber,
                    targetWeightDisplay: target.targetWeight,
                    targetReps: target.targetReps,
                    targetRpe: target.targetRpe
                )
            })
        } else {
            let defaults = (1...exercise.wrappedValue.sets).map { num in
                EditableSetTarget(
                    setNumber: num,
                    targetWeightDisplay: exercise.wrappedValue.weight,
                    targetReps: exercise.wrappedValue.reps,
                    targetRpe: exercise.wrappedValue.rpeTarget
                )
            }
            _setTargets = State(initialValue: defaults)
        }
    }

    var body: some View {
        Form {
            Section(String(localized: "plan.edit.overview")) {
                LabeledContent(String(localized: "plan.edit.exerciseName"), value: exerciseName)

                Stepper(String(localized: "plan.edit.sets: \(setTargets.count)"),
                        value: Binding(
                            get: { setTargets.count },
                            set: { newCount in adjustSetCount(to: newCount) }
                        ),
                        in: 1...10)

                HStack {
                    Text(String(localized: "plan.edit.defaultReps"))
                    Spacer()
                    TextField("", value: $exercise.reps, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 60)
                }
            }

            Section(String(localized: "plan.edit.perSetTargets")) {
                ForEach($setTargets) { $target in
                    VStack(spacing: 8) {
                        HStack {
                            Text("Set \(target.setNumber)")
                                .font(.subheadline.bold())
                            Spacer()
                        }

                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(String(localized: "plan.edit.weight")) (\(unitSymbol))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("--", value: $target.targetWeightDisplay, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "plan.edit.reps"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("--", value: $target.targetReps, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("RPE")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("--", value: $target.targetRpe, format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section(String(localized: "plan.edit.notes")) {
                TextField(String(localized: "plan.edit.notesPlaceholder"),
                          text: Binding(
                            get: { exercise.notes ?? "" },
                            set: { exercise.notes = $0.isEmpty ? nil : $0 }
                          ),
                          axis: .vertical)
                    .lineLimit(3...6)
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Sync back to exercise (values are stored as-is, no conversion needed)
            exercise.sets = setTargets.count
            exercise.setsJson = setTargets.map { target in
                APISetTarget(
                    setNumber: target.setNumber,
                    targetWeight: target.targetWeightDisplay,
                    targetReps: target.targetReps,
                    targetRpe: target.targetRpe
                )
            }
            if let first = setTargets.first {
                exercise.weight = first.targetWeightDisplay
                exercise.rpeTarget = first.targetRpe
            }
        }
    }

    private func adjustSetCount(to newCount: Int) {
        while setTargets.count < newCount {
            let lastTarget = setTargets.last
            setTargets.append(EditableSetTarget(
                setNumber: setTargets.count + 1,
                targetWeightDisplay: lastTarget?.targetWeightDisplay,
                targetReps: lastTarget?.targetReps ?? exercise.reps,
                targetRpe: lastTarget?.targetRpe
            ))
        }
        while setTargets.count > newCount {
            setTargets.removeLast()
        }
    }
}

struct EditableSetTarget: Identifiable {
    let id = UUID()
    var setNumber: Int
    var targetWeightDisplay: Double?
    var targetReps: Int
    var targetRpe: Double?
}
