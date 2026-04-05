import SwiftUI

struct VolumeDiffSheet: View {
    let changes: [APIPlanChange]
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                if changes.isEmpty {
                    ContentUnavailableView(
                        String(localized: "refine.volume.noChanges"),
                        systemImage: "chart.bar",
                        description: Text(String(localized: "refine.volume.noChangesDesc"))
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(changes) { change in
                            DiffRow(change: change)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(String(localized: "refine.volume.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !changes.isEmpty {
                    Button {
                        onApply()
                        dismiss()
                    } label: {
                        Text(String(localized: "refine.volume.apply"))
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .background(.ultraThinMaterial)
                }
            }
        }
    }
}

private struct DiffRow: View {
    let change: APIPlanChange

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(change.exerciseName)
                .font(.headline)

            HStack(spacing: 16) {
                DiffColumn(label: String(localized: "refine.diff.sets"),
                           before: change.beforeValue(for: "sets"),
                           after: change.afterValue(for: "sets"))
                DiffColumn(label: String(localized: "refine.diff.reps"),
                           before: change.beforeValue(for: "reps"),
                           after: change.afterValue(for: "reps"))
                DiffColumn(label: "RPE",
                           before: change.beforeValue(for: "rpe_target"),
                           after: change.afterValue(for: "rpe_target"))
                DiffColumn(label: String(localized: "refine.diff.weight"),
                           before: change.beforeValue(for: "weight"),
                           after: change.afterValue(for: "weight"))
            }

            if let reasoning = change.reasoning, !reasoning.isEmpty {
                Text(reasoning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct DiffColumn: View {
    let label: String
    let before: String
    let after: String

    var changed: Bool { before != after }

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if changed {
                Text(before)
                    .font(.caption)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                Text(after)
                    .font(.callout.bold())
                    .foregroundStyle(Color.accentColor)
            } else {
                Text(after)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 50)
    }
}
