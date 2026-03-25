import SwiftUI
import SwiftData

struct WarmupSet: Identifiable {
    let id = UUID()
    let weight: Double
    let reps: Int
    let percentage: Int
    let restSec: Int
    var completed: Bool = false
}

struct ActiveWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ActiveWorkoutViewModel()

    var templateExercises: [[String: AnyCodableValue]]?

    @State private var currentWeight: Double?
    @State private var currentReps: Int?
    @State private var currentRPE: Double?
    @State private var currentSetType: SetType = .working
    @State private var selectedExerciseId: Int?
    @State private var warmupSets: [WarmupSet] = []
    @State private var isLoadingWarmup = false
    @State private var templateQueue: [(exerciseId: Int, sets: Int, reps: Int, weight: Double?)] = []

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
                    exerciseSection
                    if selectedExerciseId != nil {
                        logSetSection
                        warmupButtonSection
                        if !warmupSets.isEmpty { warmupSection }
                    }
                    if !viewModel.loggedSets.isEmpty { completedSetsSection }
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "workout.finish")) {
                        viewModel.completeWorkout(context: context)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "workout.cancel")) { dismiss() }
                }
            }
            .onAppear {
                if viewModel.currentSession == nil {
                    viewModel.startWorkout(context: context)
                }
                if templateQueue.isEmpty, let tmpl = templateExercises {
                    templateQueue = tmpl.compactMap { entry in
                        guard let id = entry["exercise_id"]?.intValue else { return nil }
                        let sets = entry["sets"]?.intValue ?? 3
                        let reps = entry["reps"]?.intValue ?? 8
                        let weight = entry["weight_kg"]?.doubleValue ?? entry["weight"]?.doubleValue
                        return (exerciseId: id, sets: sets, reps: reps, weight: weight)
                    }
                    if let first = templateQueue.first {
                        selectedExerciseId = first.exerciseId
                        currentWeight = first.weight
                        currentReps = first.reps
                    }
                }
            }
            .alert(String(localized: "workout.newPR"), isPresented: $viewModel.showPRAlert) {
                Button(String(localized: "common.ok")) {}
            } message: {
                if let pr = viewModel.currentPRAlert {
                    Text("\(pr.title)\n\(pr.detail)\nPrevious: \(pr.previous, specifier: "%.1f")")
                }
            }
            .onChange(of: selectedExerciseId) { _, _ in
                warmupSets = []
            }
        }
    }

    // MARK: - Sections

    private var exerciseSection: some View {
        Section(String(localized: "workout.exercise")) {
            Picker(String(localized: "workout.selectExercise"), selection: $selectedExerciseId) {
                Text(String(localized: "workout.selectExercise")).tag(nil as Int?)
                ForEach(exercises) { exercise in
                    Text(exercise.name).tag(exercise.serverId as Int?)
                }
            }

            if let id = selectedExerciseId,
               let exercise = exercises.first(where: { $0.serverId == id }) {
                NavigationLink {
                    ExerciseDetailView(exerciseId: id, exerciseName: exercise.name)
                } label: {
                    Label(String(localized: "exercise.howToPerform"), systemImage: "info.circle")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private var warmupSection: some View {
        let unit = WeightUnit.current
        return Section(String(localized: "workout.warmUp")) {
            ForEach(Array(warmupSets.enumerated()), id: \.element.id) { index, warmup in
                HStack {
                    Image(systemName: warmup.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(warmup.completed ? .green : .secondary)

                    Text("\(unit.fromKg(warmup.weight), specifier: "%.1f") \(unit.symbol)")
                        .font(.subheadline.monospacedDigit())
                    Text("x \(warmup.reps)")
                        .font(.subheadline)
                    Spacer()
                    if warmup.percentage > 0 {
                        Text("\(warmup.percentage)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(String(localized: "plan.bar"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .opacity(warmup.completed ? 0.5 : 1.0)
                .onTapGesture {
                    warmupSets[index].completed.toggle()
                    if warmupSets[index].completed {
                        // Log as warm-up set
                        if let exerciseId = selectedExerciseId {
                            viewModel.logSet(
                                exerciseId: exerciseId,
                                weight: warmup.weight,
                                reps: warmup.reps,
                                setType: .warmUp,
                                context: context
                            )
                            viewModel.startRestTimer(seconds: warmup.restSec)
                        }
                    }
                }
            }
        }
    }

    private var warmupButtonSection: some View {
        Section {
            Button {
                guard let id = selectedExerciseId, let w = currentWeight, w > 20 else { return }
                Task { await loadWarmup(exerciseId: id, weight: w) }
            } label: {
                HStack {
                    Image(systemName: "flame")
                    Text(warmupSets.isEmpty
                         ? String(localized: "workout.generateWarmUp")
                         : String(localized: "workout.updateWarmUp"))
                }
            }
            .disabled(selectedExerciseId == nil || currentWeight == nil || (currentWeight ?? 0) <= 20)
        }
    }

    private var logSetSection: some View {
        Section(String(localized: "workout.workingSet")) {
            SetEntryRow(
                setNumber: viewModel.loggedSets.filter { $0.setType != .warmUp }.count + 1,
                previousWeight: viewModel.loggedSets.last?.weight,
                previousReps: viewModel.loggedSets.last?.reps,
                weight: $currentWeight,
                reps: $currentReps,
                rpe: $currentRPE,
                setType: $currentSetType
            )

            Button(String(localized: "workout.logSet")) {
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
            .disabled(currentWeight == nil || currentReps == nil)
        }
    }

    private var completedSetsSection: some View {
        let unit = WeightUnit.current
        return Section(String(localized: "workout.completed \(viewModel.loggedSets.count)")) {
            ForEach(viewModel.loggedSets, id: \.setNumber) { set in
                HStack {
                    Text(set.setType == .warmUp ? "WU" : "Set \(set.setNumber)")
                        .font(.subheadline)
                        .foregroundStyle(set.setType == .warmUp ? .secondary : .primary)
                    Spacer()
                    if let w = set.weight, let r = set.reps {
                        Text("\(unit.fromKg(w), specifier: "%.1f") x \(r)")
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

    // MARK: - Warmup Loading

    private func loadWarmup(exerciseId: Int, weight: Double) async {
        isLoadingWarmup = true

        struct WarmupResponse: Codable {
            let warmupSets: [WarmupSetData]

            enum CodingKeys: String, CodingKey {
                case warmupSets = "warmup_sets"
            }
        }

        struct WarmupSetData: Codable {
            let weight: Double
            let reps: Int
            let percentage: Int
            let restSec: Int

            enum CodingKeys: String, CodingKey {
                case weight, reps, percentage
                case restSec = "rest_sec"
            }
        }

        do {
            let apiClient = APIClient(config: .current)
            let response: WarmupResponse = try await apiClient.get(
                "/api/warmup/\(exerciseId)",
                queryItems: [.init(name: "working_weight", value: "\(weight)")]
            )

            warmupSets = response.warmupSets.map {
                WarmupSet(weight: $0.weight, reps: $0.reps,
                          percentage: $0.percentage, restSec: $0.restSec)
            }
        } catch {
            warmupSets = []
        }

        isLoadingWarmup = false
    }
}
