import SwiftUI
import SwiftData

struct CreateTemplateView: View {
    @Bindable var viewModel: TemplatesViewModel
    @Query private var users: [CachedUser]
    @Query(sort: \CachedExercise.name) private var exercises: [CachedExercise]
    @Environment(\.dismiss) private var dismiss

    @State private var templateName = ""
    @State private var entries: [TemplateExerciseEntry] = []
    @State private var selectedExerciseId: Int?
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight: Double?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                addExerciseSection
                if !entries.isEmpty { entriesSection }
                if let error = viewModel.errorMessage { errorSection(error) }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveTemplate() }
                    }
                    .disabled(templateName.isEmpty || entries.isEmpty || isSaving)
                }
            }
        }
    }

    private var nameSection: some View {
        Section("Template Name") {
            TextField("e.g., Quick Push Day", text: $templateName)
        }
    }

    private var addExerciseSection: some View {
        Section("Add Exercise") {
            Picker("Exercise", selection: $selectedExerciseId) {
                Text("Select...").tag(nil as Int?)
                ForEach(exercises) { ex in
                    Text(ex.name).tag(ex.serverId as Int?)
                }
            }
            Stepper("Sets: \(sets)", value: $sets, in: 1...10)
            Stepper("Reps: \(reps)", value: $reps, in: 1...30)
            weightRow
            Button("Add to Template") { addExercise() }
                .disabled(selectedExerciseId == nil)
        }
    }

    private var weightRow: some View {
        HStack {
            Text("Weight (optional)")
            Spacer()
            TextField("kg", value: $weight, format: .number)
                .keyboardType(.decimalPad)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
        }
    }

    private var entriesSection: some View {
        Section("Exercises (\(entries.count))") {
            ForEach(entries) { entry in
                VStack(alignment: .leading) {
                    Text(entry.exerciseName).font(.subheadline)
                    Text(entryDetail(entry)).font(.caption).foregroundStyle(.secondary)
                }
            }
            .onDelete { entries.remove(atOffsets: $0) }
        }
    }

    private func errorSection(_ error: String) -> some View {
        Section { Text(error).foregroundStyle(.red).font(.caption) }
    }

    private func entryDetail(_ entry: TemplateExerciseEntry) -> String {
        var text = "\(entry.sets)x\(entry.reps)"
        if let w = entry.weight { text += " @ \(String(format: "%.1f", w))kg" }
        return text
    }

    private func addExercise() {
        guard let exerciseId = selectedExerciseId,
              let exercise = exercises.first(where: { $0.serverId == exerciseId }) else { return }
        entries.append(TemplateExerciseEntry(
            exerciseId: exerciseId, exerciseName: exercise.name,
            sets: sets, reps: reps, weight: weight
        ))
        selectedExerciseId = nil
        weight = nil
    }

    private func saveTemplate() async {
        guard let user = users.first else { return }
        isSaving = true
        let apiClient = APIClient(config: .current)
        await viewModel.saveTemplate(apiClient: apiClient, userId: user.serverId,
                                     name: templateName, exercises: entries)
        isSaving = false
        if viewModel.errorMessage == nil { dismiss() }
    }
}
