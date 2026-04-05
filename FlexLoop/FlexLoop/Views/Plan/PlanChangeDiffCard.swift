import SwiftUI

struct PlanChangeDiffCard: View {
    let change: APIPlanChange
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                if let toolName = change.toolName {
                    Text(toolLabel(toolName))
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(toolColor(toolName).opacity(0.15))
                        .foregroundStyle(toolColor(toolName))
                        .clipShape(Capsule())
                }

                Text(change.exerciseName)
                    .font(.subheadline.bold())

                Spacer()

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }

            if isExpanded {
                // Before/After diff
                if change.before != nil || change.after != nil {
                    HStack(spacing: 16) {
                        diffColumn(label: String(localized: "refine.diff.sets"), key: "sets")
                        diffColumn(label: String(localized: "refine.diff.reps"), key: "reps")
                        diffColumn(label: "RPE", key: "rpe_target")
                        diffColumn(label: String(localized: "refine.diff.weight"), key: "weight")
                    }
                }

                if let reasoning = change.reasoning, !reasoning.isEmpty {
                    Text(reasoning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let warning = change.warning, !warning.isEmpty {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func diffColumn(label: String, key: String) -> some View {
        let before = change.beforeValue(for: key)
        let after = change.afterValue(for: key)
        let changed = before != after

        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            if changed {
                Text(before)
                    .font(.caption)
                    .strikethrough()
                    .foregroundStyle(.secondary)
                Text(after)
                    .font(.caption.bold())
                    .foregroundStyle(.accentColor)
            } else {
                Text(after)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 40)
    }

    private func toolLabel(_ name: String) -> String {
        switch name {
        case "swap_exercise": String(localized: "refine.tool.swap")
        case "adjust_sets": String(localized: "refine.tool.adjust")
        case "add_exercise": String(localized: "refine.tool.add")
        case "remove_exercise": String(localized: "refine.tool.remove")
        default: name
        }
    }

    private func toolColor(_ name: String) -> Color {
        switch name {
        case "swap_exercise": .blue
        case "adjust_sets": .orange
        case "add_exercise": .green
        case "remove_exercise": .red
        default: .gray
        }
    }
}
