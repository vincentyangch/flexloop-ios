import SwiftUI
import SwiftData

struct GuidedWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GuidedWorkoutViewModel()

    let planDay: APIPlanDay
    let planDayId: Int?
    let userId: Int
    let exerciseNames: [Int: String]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress bar
                progressHeader

                if let exercise = viewModel.currentExercise {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Exercise header
                            exerciseHeader(exercise)

                            // Rest timer
                            RestTimerView(
                                timeRemaining: viewModel.restTimeRemaining,
                                isActive: viewModel.isRestTimerActive,
                                onStop: { viewModel.stopRestTimer() }
                            )
                            .padding(.horizontal)

                            // Sets
                            setsSection(exercise)
                        }
                        .padding(.vertical)
                    }

                    // Bottom navigation
                    navigationBar
                } else {
                    ContentUnavailableView("No exercises", systemImage: "figure.strengthtraining.traditional")
                }
            }
            .navigationTitle(planDay.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "workout.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            viewModel.skipExercise()
                        } label: {
                            Label(String(localized: "workout.skipExercise"), systemImage: "forward.fill")
                        }
                        Button {
                            viewModel.showExerciseList = true
                        } label: {
                            Label(String(localized: "workout.exerciseList"), systemImage: "list.bullet")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showExerciseList) {
                exerciseListSheet
            }
            .sheet(isPresented: $viewModel.showSummary) {
                if let summary = viewModel.workoutSummary {
                    WorkoutSummaryView(summary: summary) {
                        dismiss()
                    }
                }
            }
            .alert(String(localized: "workout.newPR"), isPresented: $viewModel.showPRAlert) {
                Button(String(localized: "common.ok")) {}
            } message: {
                if let pr = viewModel.currentPRAlert {
                    Text("\(pr.title)\n\(pr.detail)")
                }
            }
            .onAppear {
                viewModel.userId = userId
                viewModel.loadFromPlanDay(planDay, exerciseNames: exerciseNames)
            }
        }
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Text(String(localized: "workout.exercise \(viewModel.currentExerciseIndex + 1) \(viewModel.exercises.count)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel.progress)
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal)

            GeometryReader { geo in
                let fraction = viewModel.exercises.isEmpty ? 0 :
                    Double(viewModel.currentExerciseIndex + 1) / Double(viewModel.exercises.count)
                RoundedRectangle(cornerRadius: 2)
                    .fill(.blue)
                    .frame(width: geo.size.width * fraction, height: 4)
            }
            .frame(height: 4)
            .background(Color(.systemGray5))
        }
        .padding(.vertical, 8)
    }

    // MARK: - Exercise Header

    private func exerciseHeader(_ exercise: GuidedExercise) -> some View {
        VStack(spacing: 4) {
            Text(exerciseNames[exercise.exerciseId] ?? "Exercise #\(exercise.exerciseId)")
                .font(.title2.bold())

            if let notes = exercise.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Sets Section

    private func setsSection(_ exercise: GuidedExercise) -> some View {
        VStack(spacing: 8) {
            // Header row
            HStack {
                Text("Set")
                    .frame(width: 35, alignment: .leading)
                Text("\(String(localized: "workout.weight")) (\(WeightUnit.current.symbol))")
                    .frame(maxWidth: .infinity)
                Text(String(localized: "workout.reps"))
                    .frame(width: 50)
                Text("RPE")
                    .frame(width: 45)
                Spacer()
                    .frame(width: 44)
            }
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal)

            ForEach(Array(exercise.targetSets.enumerated()), id: \.element.id) { idx, target in
                let completedSet = exercise.completedSets.first(where: { $0.setNumber == target.setNumber })
                GuidedSetRow(
                    setNumber: target.setNumber,
                    targetWeightKg: target.targetWeightKg,
                    targetReps: target.targetReps,
                    targetRpe: target.targetRpe,
                    completedSet: completedSet,
                    onComplete: { weight, reps, rpe in
                        viewModel.completeSet(
                            exerciseIndex: viewModel.currentExerciseIndex,
                            setNumber: target.setNumber,
                            weightKg: weight,
                            reps: reps,
                            rpe: rpe
                        )
                    },
                    onEdit: { weight, reps, rpe in
                        if let setId = completedSet?.id {
                            viewModel.editCompletedSet(
                                exerciseIndex: viewModel.currentExerciseIndex,
                                setId: setId,
                                weightKg: weight,
                                reps: reps,
                                rpe: rpe
                            )
                        }
                    }
                )
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.previousExercise()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .disabled(viewModel.currentExerciseIndex == 0)

            if viewModel.isLastExercise {
                Button {
                    viewModel.finishWorkout(context: context, userId: userId, planDayId: planDayId)
                    Task {
                        let apiClient = APIClient(config: .current)
                        await viewModel.advanceCycle(apiClient: apiClient, userId: userId)
                    }
                } label: {
                    Text(String(localized: "workout.finishWorkout"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            } else {
                Button {
                    viewModel.nextExercise()
                } label: {
                    Text(String(localized: "workout.nextExercise"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }

            Button {
                viewModel.nextExercise()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .disabled(viewModel.isLastExercise)
        }
        .padding()
        .background(.bar)
    }

    // MARK: - Exercise List Sheet

    private var exerciseListSheet: some View {
        NavigationStack {
            List {
                ForEach(Array(viewModel.exercises.enumerated()), id: \.element.id) { idx, exercise in
                    Button {
                        viewModel.jumpToExercise(idx)
                        viewModel.showExerciseList = false
                    } label: {
                        HStack {
                            if exercise.isSkipped {
                                Image(systemName: "forward.fill")
                                    .foregroundStyle(.secondary)
                            } else if !exercise.completedSets.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary)
                            }

                            Text(exerciseNames[exercise.exerciseId] ?? "Exercise #\(exercise.exerciseId)")
                                .font(.subheadline)
                                .strikethrough(exercise.isSkipped)
                                .foregroundStyle(exercise.isSkipped ? .secondary : .primary)

                            Spacer()

                            if idx == viewModel.currentExerciseIndex {
                                Text(String(localized: "workout.current"))
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }

                            Text("\(exercise.completedSets.count)/\(exercise.targetSets.count)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onMove { viewModel.reorderExercise(from: $0, to: $1) }
            }
            .navigationTitle(String(localized: "workout.exerciseList"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.done")) {
                        viewModel.showExerciseList = false
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    EditButton()
                }
            }
        }
    }
}

// MARK: - Guided Set Row

struct GuidedSetRow: View {
    let setNumber: Int
    let targetWeightKg: Double?
    let targetReps: Int
    let targetRpe: Double?
    let completedSet: CompletedSet?

    let onComplete: (Double?, Int?, Double?) -> Void
    let onEdit: (Double?, Int?, Double?) -> Void

    private let unit = WeightUnit.current

    // Display weight in user's preferred unit
    @State private var editWeightDisplay: Double?
    @State private var editReps: Int?
    @State private var editRpe: Double?
    @State private var isEditing = false

    var isCompleted: Bool { completedSet != nil }

    init(setNumber: Int, targetWeightKg: Double?, targetReps: Int, targetRpe: Double?,
         completedSet: CompletedSet?,
         onComplete: @escaping (Double?, Int?, Double?) -> Void,
         onEdit: @escaping (Double?, Int?, Double?) -> Void) {
        self.setNumber = setNumber
        self.targetWeightKg = targetWeightKg
        self.targetReps = targetReps
        self.targetRpe = targetRpe
        self.completedSet = completedSet
        self.onComplete = onComplete
        self.onEdit = onEdit
        let u = WeightUnit.current
        let weightKg = completedSet?.weightKg ?? targetWeightKg
        _editWeightDisplay = State(initialValue: weightKg.map { u.fromKgRounded($0) })
        _editReps = State(initialValue: completedSet?.reps ?? targetReps)
        _editRpe = State(initialValue: completedSet?.rpe ?? targetRpe)
    }

    /// Convert display weight back to kg for storage
    private var editWeightKg: Double? {
        editWeightDisplay.map { unit.toKg($0) }
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("\(setNumber)")
                .font(.subheadline.bold())
                .frame(width: 35, alignment: .leading)

            TextField("--", value: $editWeightDisplay, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
                .disabled(isCompleted && !isEditing)

            TextField("--", value: $editReps, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
                .disabled(isCompleted && !isEditing)

            TextField("--", value: $editRpe, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 45)
                .disabled(isCompleted && !isEditing)

            if isCompleted {
                if isEditing {
                    Button {
                        onEdit(editWeightKg, editReps, editRpe)
                        isEditing = false
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.title3)
                    }
                    .frame(width: 44)
                } else {
                    Button {
                        isEditing = true
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                    }
                    .frame(width: 44)
                }
            } else {
                Button {
                    onComplete(editWeightKg, editReps, editRpe)
                } label: {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .frame(width: 44)
            }
        }
        .padding(.vertical, 4)
        .background(isCompleted ? Color.green.opacity(0.05) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Workout Summary View

struct WorkoutSummaryView: View {
    let summary: WorkoutSummary
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)

                Text(String(localized: "workout.complete"))
                    .font(.title.bold())

                VStack(spacing: 12) {
                    SummaryRow(
                        icon: "figure.strengthtraining.traditional",
                        label: String(localized: "workout.summary.exercises"),
                        value: "\(summary.exercisesCompleted)"
                    )
                    SummaryRow(
                        icon: "number",
                        label: String(localized: "workout.summary.sets"),
                        value: "\(summary.totalSets)"
                    )
                    SummaryRow(
                        icon: "clock",
                        label: String(localized: "workout.summary.duration"),
                        value: formatDuration(summary.duration)
                    )
                    if summary.exercisesSkipped > 0 {
                        SummaryRow(
                            icon: "forward.fill",
                            label: String(localized: "workout.summary.skipped"),
                            value: "\(summary.exercisesSkipped)"
                        )
                    }
                    if !summary.newPRs.isEmpty {
                        SummaryRow(
                            icon: "star.fill",
                            label: String(localized: "workout.summary.prs"),
                            value: "\(summary.newPRs.count)"
                        )
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text(String(localized: "common.done"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle(String(localized: "workout.summary.title"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        if minutes < 60 {
            return "\(minutes)m"
        }
        return "\(minutes / 60)h \(minutes % 60)m"
    }
}

struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.blue)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
    }
}
