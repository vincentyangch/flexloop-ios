import SwiftUI

struct ExerciseAlternativesSheet: View {
    let alternatives: [APISwapAlternative]
    let originalExercise: APIOriginalExercise?
    let onSelect: (APISwapAlternative) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAlternative: APISwapAlternative?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if let original = originalExercise {
                        Text(String(localized: "refine.swap.replacing \(original.exerciseName ?? "")"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }

                    if alternatives.isEmpty {
                        ContentUnavailableView(
                            String(localized: "refine.swap.noAlternatives"),
                            systemImage: "sparkles",
                            description: Text(String(localized: "refine.swap.noAlternativesDesc"))
                        )
                    } else {
                        ForEach(alternatives) { alt in
                            AlternativeCard(alternative: alt, isSelected: selectedAlternative?.exerciseName == alt.exerciseName)
                                .onTapGesture {
                                    guard alt.isAvailable else { return }
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        selectedAlternative = alt
                                    }
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "refine.swap.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !alternatives.isEmpty {
                    Button {
                        if let selected = selectedAlternative {
                            onSelect(selected)
                            dismiss()
                        }
                    } label: {
                        Text(String(localized: "refine.swap.apply"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedAlternative == nil)
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
        }
    }
}

struct AlternativeCard: View {
    let alternative: APISwapAlternative
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(alternative.exerciseName)
                    .font(.headline)
                    .foregroundStyle(alternative.isAvailable ? .primary : .tertiary)
                Spacer()
                if let sets = alternative.sets, let reps = alternative.reps {
                    Text("\(sets)x\(reps)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.fill.tertiary)
                        .clipShape(Capsule())
                }
            }

            if let rpe = alternative.rpeTarget {
                Text("RPE \(String(format: "%.1f", rpe))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(alternative.reasoning)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if let warning = alternative.warning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        )
        .opacity(alternative.isAvailable ? 1.0 : 0.5)
    }
}
