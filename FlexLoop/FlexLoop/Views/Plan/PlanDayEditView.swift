import SwiftUI
import SwiftData

struct PlanDayEditView: View {
    let planId: Int
    let day: APIPlanDay
    let exerciseName: (Int) -> String

    @Environment(\.dismiss) private var dismiss
    @State private var label: String
    @State private var focus: String
    @State private var exercises: [EditablePlanExercise]
    @State private var showExercisePicker = false
    @State private var showVolumeDiff = false
    @State private var refinerVM = PlanRefinerViewModel()

    @Query(sort: \CachedExercise.name) private var cachedExercises: [CachedExercise]
    @Query private var users: [CachedUser]
    private var unitSymbol: String { users.first?.weightUnit ?? "kg" }
    private var userId: Int? { users.first?.serverId }

    var onSave: (([EditablePlanExercise], String, String) -> Void)?

    init(planId: Int, day: APIPlanDay, exerciseName: @escaping (Int) -> String,
         onSave: (([EditablePlanExercise], String, String) -> Void)? = nil) {
        self.planId = planId
        self.day = day
        self.exerciseName = exerciseName
        self.onSave = onSave
        _label = State(initialValue: day.label)
        _focus = State(initialValue: day.focus)

        let editable = day.exerciseGroups.flatMap { group in
            group.exercises.enumerated().map { idx, ex in
                EditablePlanExercise(
                    exerciseId: ex.exerciseId,
                    order: ex.order,
                    sets: ex.sets,
                    reps: ex.reps,
                    weight: ex.weight,
                    rpeTarget: ex.rpeTarget,
                    setsJson: ex.setsJson,
                    notes: ex.notes
                )
            }
        }
        _exercises = State(initialValue: editable)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "plan.edit.dayInfo")) {
                    TextField(String(localized: "plan.edit.label"), text: $label)
                    TextField(String(localized: "plan.edit.focus"), text: $focus)
                }

                Section(String(localized: "plan.edit.exercises")) {
                    ForEach($exercises) { $exercise in
                        NavigationLink {
                            PlanExerciseEditView(
                                exercise: $exercise,
                                exerciseName: exerciseName(exercise.exerciseId),
                                unitSymbol: unitSymbol,
                                planId: planId,
                                userId: userId,
                                dayNumber: day.dayNumber
                            )
                        } label: {
                            HStack {
                                Text(exerciseName(exercise.exerciseId))
                                    .font(.subheadline)
                                Spacer()
                                Text("\(exercise.sets)x\(exercise.reps)")
                                    .font(.subheadline.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onMove { exercises.move(fromOffsets: $0, toOffset: $1) }
                    .onDelete { exercises.remove(atOffsets: $0) }

                    Button {
                        showExercisePicker = true
                    } label: {
                        Label(String(localized: "plan.edit.addExercise"), systemImage: "plus")
                    }

                    if let uid = userId {
                        Button {
                            let apiClient = APIClient(config: .current)
                            Task {
                                await refinerVM.adjustVolume(
                                    apiClient: apiClient, planId: planId,
                                    userId: uid, dayNumber: day.dayNumber,
                                    direction: "auto"
                                )
                                if !refinerVM.volumeChanges.isEmpty {
                                    showVolumeDiff = true
                                }
                            }
                        } label: {
                            Label(String(localized: "refine.adjustVolume"), systemImage: "sparkles")
                        }
                        .disabled(refinerVM.isAnyActionLoading)
                    }
                }
            }
            .navigationTitle("Day \(day.dayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        // Update order values
                        for i in exercises.indices {
                            exercises[i].order = i + 1
                        }
                        onSave?(exercises, label, focus)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .bottomBar) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExercisePickerView(cachedExercises: cachedExercises) { exerciseId in
                    let newExercise = EditablePlanExercise(
                        exerciseId: exerciseId,
                        order: exercises.count + 1,
                        sets: 3,
                        reps: 10,
                        weight: nil,
                        rpeTarget: nil,
                        setsJson: nil,
                        notes: nil
                    )
                    exercises.append(newExercise)
                }
            }
            .sheet(isPresented: $showVolumeDiff) {
                VolumeDiffSheet(changes: refinerVM.volumeChanges) {
                    // Apply volume changes to local exercises
                    for change in refinerVM.volumeChanges {
                        if let idx = exercises.firstIndex(where: { $0.exerciseId == change.exerciseId }) {
                            if let sets = change.after?["sets"]?.displayString, let s = Int(sets) {
                                exercises[idx].sets = s
                            }
                            if let reps = change.after?["reps"]?.displayString, let r = Int(reps) {
                                exercises[idx].reps = r
                            }
                            if let rpe = change.after?["rpe_target"]?.displayString, let r = Double(rpe) {
                                exercises[idx].rpeTarget = r
                            }
                            if let weight = change.after?["weight"]?.displayString, let w = Double(weight) {
                                exercises[idx].weight = w
                            }
                        }
                    }
                    refinerVM.clearVolume()
                }
            }
        }
    }
}

// MARK: - Editable model

struct EditablePlanExercise: Identifiable {
    let id = UUID()
    var exerciseId: Int
    var order: Int
    var sets: Int
    var reps: Int
    var weight: Double?
    var rpeTarget: Double?
    var setsJson: [APISetTarget]?
    var notes: String?
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    let cachedExercises: [CachedExercise]
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filtered: [CachedExercise] {
        if searchText.isEmpty { return cachedExercises }
        return cachedExercises.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered, id: \.serverId) { exercise in
                Button {
                    onSelect(exercise.serverId)
                    dismiss()
                } label: {
                    VStack(alignment: .leading) {
                        Text(exercise.name)
                            .font(.subheadline)
                        Text(exercise.muscleGroup)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: String(localized: "plan.edit.searchExercise"))
            .navigationTitle(String(localized: "plan.edit.pickExercise"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
            }
        }
    }
}
