import SwiftUI

enum PlanMode: String, CaseIterable, Identifiable {
    case fullBody3 = "full_body_3"
    case upperLower4 = "upper_lower_4"
    case ppl6 = "ppl_6"
    case arnold6 = "arnold_6"
    case bodyPart5 = "body_part_5"
    case ppl3 = "ppl_3"
    case phul4 = "phul_4"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullBody3: String(localized: "planMode.fullBody3.name")
        case .upperLower4: String(localized: "planMode.upperLower4.name")
        case .ppl6: String(localized: "planMode.ppl6.name")
        case .arnold6: String(localized: "planMode.arnold6.name")
        case .bodyPart5: String(localized: "planMode.bodyPart5.name")
        case .ppl3: String(localized: "planMode.ppl3.name")
        case .phul4: String(localized: "planMode.phul4.name")
        }
    }

    var subtitle: String {
        switch self {
        case .fullBody3: String(localized: "planMode.fullBody3.subtitle")
        case .upperLower4: String(localized: "planMode.upperLower4.subtitle")
        case .ppl6: String(localized: "planMode.ppl6.subtitle")
        case .arnold6: String(localized: "planMode.arnold6.subtitle")
        case .bodyPart5: String(localized: "planMode.bodyPart5.subtitle")
        case .ppl3: String(localized: "planMode.ppl3.subtitle")
        case .phul4: String(localized: "planMode.phul4.subtitle")
        }
    }

    var daysPerCycle: Int {
        switch self {
        case .fullBody3, .ppl3: 3
        case .upperLower4, .phul4: 4
        case .bodyPart5: 5
        case .ppl6, .arnold6: 6
        }
    }

    var suitedFor: String {
        switch self {
        case .fullBody3: String(localized: "planMode.suited.beginner")
        case .upperLower4, .ppl3, .phul4: String(localized: "planMode.suited.intermediate")
        case .ppl6, .arnold6, .bodyPart5: String(localized: "planMode.suited.intAdvanced")
        }
    }
}

struct PlanModePickerView: View {
    @State private var selectedMode: PlanMode?
    @Binding var isGenerating: Bool
    @Binding var errorMessage: String?
    let hasActivePlan: Bool
    let onGenerate: (PlanMode) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showReplaceConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(PlanMode.allCases) { mode in
                        PlanModeCard(
                            mode: mode,
                            isSelected: selectedMode == mode
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedMode = selectedMode == mode ? nil : mode
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(String(localized: "planMode.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    if hasActivePlan {
                        showReplaceConfirmation = true
                    } else {
                        generate()
                    }
                } label: {
                    Text(String(localized: "plan.generatePlan"))
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedMode == nil || isGenerating)
                .padding()
                .background(.ultraThinMaterial)
            }
            .overlay {
                if isGenerating {
                    VStack(spacing: 12) {
                        ProgressView()
                        Text(String(localized: "plan.generating"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
                }
            }
            .alert(String(localized: "planMode.replaceAlert.title"), isPresented: $showReplaceConfirmation) {
                Button(String(localized: "common.cancel"), role: .cancel) {}
                Button(String(localized: "planMode.replaceAlert.confirm"), role: .destructive) {
                    generate()
                }
            } message: {
                Text(String(localized: "planMode.replaceAlert.message"))
            }
            .alert(String(localized: "common.error"), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(String(localized: "common.ok")) { errorMessage = nil }
            } message: {
                if let msg = errorMessage {
                    Text(msg)
                }
            }
        }
    }

    private func generate() {
        guard let mode = selectedMode else { return }
        onGenerate(mode)
    }
}

struct PlanModeCard: View {
    let mode: PlanMode
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(mode.displayName)
                    .font(.headline)
                Spacer()
                Text(String(localized: "planMode.daysPerCycle.\(mode.daysPerCycle)"))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.fill.tertiary)
                    .clipShape(Capsule())
            }
            Text(mode.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(mode.suitedFor)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
        )
    }
}
