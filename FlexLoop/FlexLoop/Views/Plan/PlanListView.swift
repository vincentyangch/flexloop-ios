import SwiftUI
import SwiftData

struct PlanListView: View {
    @Query private var users: [CachedUser]
    @State private var viewModel = PlanListViewModel()
    @State private var showModePicker = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.plans.isEmpty {
                    emptyState
                } else {
                    planList
                }
            }
            .navigationTitle(String(localized: "plan.title"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showModePicker = true
                    } label: {
                        Label(String(localized: "plan.generateAI"), systemImage: "sparkles")
                    }
                    .disabled(viewModel.isGenerating)
                }
            }
            .task { await loadPlans() }
            .sheet(isPresented: $showModePicker, onDismiss: { viewModel.errorMessage = nil }) {
                PlanModePickerView(
                    isGenerating: $viewModel.isGenerating,
                    errorMessage: $viewModel.errorMessage,
                    hasActivePlan: viewModel.activePlan != nil,
                    onGenerate: { mode in
                        Task { await generatePlan(planMode: mode.rawValue) }
                    }
                )
            }
            .alert(String(localized: "common.error"), isPresented: Binding(
                get: { viewModel.errorMessage != nil && !showModePicker },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button(String(localized: "common.ok")) { viewModel.errorMessage = nil }
            } message: {
                if let msg = viewModel.errorMessage {
                    Text(msg)
                }
            }
        }
    }

    private var planList: some View {
        List {
            // Active plan section
            if let active = viewModel.activePlan {
                Section(String(localized: "plan.active")) {
                    NavigationLink {
                        PlanDetailView(plan: active, viewModel: viewModel)
                    } label: {
                        PlanRowView(plan: active)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(String(localized: "plan.archive"), role: .destructive) {
                            Task { await archivePlan(active.id) }
                        }
                    }
                }
            }

            // Archived plans
            let archived = viewModel.plans.filter { $0.status != "active" }
            if !archived.isEmpty {
                Section(String(localized: "plan.archived")) {
                    ForEach(archived) { plan in
                        NavigationLink {
                            PlanDetailView(plan: plan, viewModel: viewModel)
                        } label: {
                            PlanRowView(plan: plan)
                        }
                        .swipeActions(edge: .leading) {
                            Button(String(localized: "plan.activate")) {
                                Task { await activatePlan(plan.id) }
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(String(localized: "common.delete"), role: .destructive) {
                                Task { await deletePlan(plan.id) }
                            }
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(String(localized: "plan.empty.title"), systemImage: "calendar")
        } description: {
            Text(String(localized: "plan.empty.description"))
        } actions: {
            Button {
                showModePicker = true
            } label: {
                Text(String(localized: "plan.generate"))
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func loadPlans() async {
        guard let user = users.first else { return }
        let apiClient = APIClient(config: .current)
        await viewModel.loadPlans(apiClient: apiClient, userId: user.serverId)
    }

    private func generatePlan(planMode: String) async {
        guard let user = users.first else { return }
        let apiClient = APIClient(config: .current)
        await viewModel.generatePlan(apiClient: apiClient, userId: user.serverId, planMode: planMode)
        if viewModel.errorMessage == nil {
            showModePicker = false
        }
    }

    private func activatePlan(_ id: Int) async {
        let apiClient = APIClient(config: .current)
        await viewModel.activatePlan(apiClient: apiClient, planId: id)
    }

    private func archivePlan(_ id: Int) async {
        let apiClient = APIClient(config: .current)
        await viewModel.archivePlan(apiClient: apiClient, planId: id)
    }

    private func deletePlan(_ id: Int) async {
        let apiClient = APIClient(config: .current)
        await viewModel.deletePlan(apiClient: apiClient, planId: id)
    }
}

// MARK: - Plan Row

struct PlanRowView: View {
    let plan: APIPlanResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.name)
                .font(.headline)
            HStack(spacing: 8) {
                Label(plan.splitType.replacingOccurrences(of: "_", with: " ").capitalized,
                      systemImage: "figure.strengthtraining.traditional")
                Text(String(localized: "plan.cycleLengthLabel.\(plan.cycleLength)"))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Plan Detail

struct PlanDetailView: View {
    let plan: APIPlanResponse
    @Bindable var viewModel: PlanListViewModel
    @State private var editingDayNumber: Int?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Plan header
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.title2.bold())
                    HStack {
                        Label(plan.splitType.replacingOccurrences(of: "_", with: " ").capitalized,
                              systemImage: "figure.strengthtraining.traditional")
                        Spacer()
                        Text(String(localized: "plan.cycleLengthLabel.\(plan.cycleLength)"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if plan.aiGenerated {
                        Label(String(localized: "plan.aiGenerated"), systemImage: "sparkles")
                            .font(.caption)
                            .foregroundStyle(.purple)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Days — tap to edit
                ForEach(plan.days.sorted(by: { $0.dayNumber < $1.dayNumber }), id: \.dayNumber) { day in
                    PlanDayCard(
                        day: day,
                        isToday: false,
                        exerciseName: { viewModel.exerciseName(for: $0) }
                    )
                    .padding(.horizontal)
                    .onTapGesture {
                        editingDayNumber = day.dayNumber
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: Binding(
            get: { editingDayNumber != nil },
            set: { if !$0 { editingDayNumber = nil } }
        )) {
            if let dayNum = editingDayNumber,
               let day = plan.days.first(where: { $0.dayNumber == dayNum }) {
            PlanDayEditView(
                planId: plan.id,
                day: day,
                exerciseName: { viewModel.exerciseName(for: $0) },
                onSave: { exercises, label, focus in
                    Task {
                        let apiClient = APIClient(config: .current)
                        // Build updated days from current plan, replacing the edited day
                        let updatedDays = plan.days.map { d -> APIPlanDayCreate in
                            if d.dayNumber == day.dayNumber {
                                return APIPlanDayCreate(
                                    dayNumber: d.dayNumber,
                                    label: label,
                                    focus: focus,
                                    exerciseGroups: [APIPlanExerciseGroupCreate(
                                        groupType: "straight",
                                        order: 1,
                                        restAfterGroupSec: 90,
                                        exercises: exercises.map { ex in
                                            APIPlanExerciseCreate(
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
                                    )]
                                )
                            } else {
                                return APIPlanDayCreate(
                                    dayNumber: d.dayNumber,
                                    label: d.label,
                                    focus: d.focus,
                                    exerciseGroups: d.exerciseGroups.map { g in
                                        APIPlanExerciseGroupCreate(
                                            groupType: g.groupType,
                                            order: g.order,
                                            restAfterGroupSec: g.restAfterGroupSec,
                                            exercises: g.exercises.map { e in
                                                APIPlanExerciseCreate(
                                                    exerciseId: e.exerciseId,
                                                    order: e.order,
                                                    sets: e.sets,
                                                    reps: e.reps,
                                                    weight: e.weight,
                                                    rpeTarget: e.rpeTarget,
                                                    setsJson: e.setsJson,
                                                    notes: e.notes
                                                )
                                            }
                                        )
                                    }
                                )
                            }
                        }
                        _ = try? await apiClient.updatePlan(
                            id: plan.id,
                            data: APIPlanUpdate(name: nil, splitType: nil, cycleLength: nil, days: updatedDays)
                        )
                        // Refresh plans
                        await viewModel.loadPlans(apiClient: apiClient, userId: plan.userId)
                    }
                }
            )
            }
        }
    }
}
