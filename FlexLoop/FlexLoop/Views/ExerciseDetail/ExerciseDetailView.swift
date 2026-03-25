import SwiftUI

struct ExerciseDetailView: View {
    let exerciseId: Int
    let exerciseName: String
    @State private var viewModel = ExerciseDetailViewModel()

    var body: some View {
        Group {
            if let detail = viewModel.detail {
                detailContent(detail)
            } else if let error = viewModel.errorMessage {
                ContentUnavailableView(error, systemImage: "exclamationmark.triangle")
            } else {
                SwiftUI.ProgressView(String(localized: "common.loading"))
            }
        }
        .navigationTitle(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: exerciseId) {
            let apiClient = APIClient(config: .current)
            await viewModel.loadExercise(apiClient: apiClient, exerciseId: exerciseId)
        }
    }

    private func detailContent(_ detail: ExerciseDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection(detail)
                if !detail.primaryMuscles.isEmpty { muscleSection(detail) }
                if !detail.instructions.isEmpty { instructionsSection(detail) }
                if !detail.formCues.isEmpty { formCuesSection(detail) }
                if !detail.commonMistakes.isEmpty { mistakesSection(detail) }
                if !detail.breathing.isEmpty { breathingSection(detail) }
            }
            .padding()
        }
    }

    private func headerSection(_ detail: ExerciseDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !detail.description.isEmpty {
                Text(detail.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                badge(detail.category.capitalized, color: .blue)
                badge(detail.equipment.capitalized, color: .green)
                badge(detail.difficulty.capitalized, color: difficultyColor(detail.difficulty))
            }
        }
    }

    private func muscleSection(_ detail: ExerciseDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "exercise.musclesWorked"))
                .font(.headline)
            MuscleMapView(
                primaryMuscles: detail.primaryMuscles,
                secondaryMuscles: detail.secondaryMuscles
            )
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func instructionsSection(_ detail: ExerciseDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "exercise.howToPerform"))
                .font(.headline)

            // Step-by-step with animation
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(detail.instructions.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(index == viewModel.currentInstructionStep ? Color.blue : Color.gray.opacity(0.2))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(index == viewModel.currentInstructionStep ? .white : .secondary)
                        }

                        Text(step)
                            .font(.subheadline)
                            .foregroundStyle(index == viewModel.currentInstructionStep ? .primary : .secondary)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation { viewModel.currentInstructionStep = index }
                    }
                }
            }

            // Navigation arrows
            HStack {
                Button {
                    withAnimation { viewModel.previousStep() }
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                }
                .disabled(viewModel.currentInstructionStep == 0)

                Spacer()
                Text("\(viewModel.currentInstructionStep + 1) / \(detail.instructions.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()

                Button {
                    withAnimation { viewModel.nextStep() }
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                }
                .disabled(viewModel.currentInstructionStep >= detail.instructions.count - 1)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formCuesSection(_ detail: ExerciseDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "exercise.formCues"))
                .font(.headline)

            ForEach(detail.formCues, id: \.self) { cue in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                    Text(cue)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func mistakesSection(_ detail: ExerciseDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "exercise.commonMistakes"))
                .font(.headline)

            ForEach(detail.commonMistakes, id: \.self) { mistake in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                    Text(mistake)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func breathingSection(_ detail: ExerciseDetail) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "wind")
                .font(.title2)
                .foregroundStyle(.cyan)
            VStack(alignment: .leading) {
                Text(String(localized: "exercise.breathing"))
                    .font(.subheadline.bold())
                Text(detail.breathing)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private func difficultyColor(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        default: return .gray
        }
    }
}
