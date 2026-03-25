import SwiftUI
import SwiftData

struct PlanView: View {
    @Query private var users: [CachedUser]
    @State private var viewModel = PlanViewModel()

    private var todayDayOfWeek: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Convert Sunday=1...Saturday=7 to Monday=1...Sunday=7
        return weekday == 1 ? 7 : weekday - 1
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading || viewModel.isGenerating {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text(viewModel.isGenerating ? "AI is generating your plan..." : "Loading plan...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else if let plan = viewModel.plan, let days = plan.days, !days.isEmpty {
                    planContent(plan: plan, days: days)
                } else if let error = viewModel.errorMessage {
                    ContentUnavailableView {
                        Label("Could not load plan", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error)
                    } actions: {
                        Button {
                            viewModel.errorMessage = nil
                            Task { await generatePlan() }
                        } label: {
                            Text("Try Again")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle(String(localized: "plan.title"))
            .toolbar {
                if viewModel.plan != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task { await generatePlan() }
                        } label: {
                            Label("Regenerate", systemImage: "arrow.clockwise")
                        }
                        .disabled(viewModel.isGenerating)
                    }
                }
            }
        }
    }

    private func planContent(plan: APIPlanGenerateResponse, days: [APIPlanDay]) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                // Plan header
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.planName ?? "Training Plan")
                        .font(.title2.bold())
                    HStack {
                        Label(plan.splitType?.uppercased() ?? "CUSTOM",
                              systemImage: "figure.strengthtraining.traditional")
                        if let start = plan.blockStart, let end = plan.blockEnd {
                            Spacer()
                            Text("\(start) → \(end)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Days
                ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                    PlanDayCard(
                        day: day,
                        isToday: day.dayNumber == todayDayOfWeek,
                        exerciseName: viewModel.exerciseName
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Active Plan", systemImage: "calendar")
        } description: {
            Text("Generate a personalized training plan with AI.")
        } actions: {
            Button {
                Task { await generatePlan() }
            } label: {
                Text("Generate Plan")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func generatePlan() async {
        guard let user = users.first else { return }
        let apiClient = APIClient(config: .current)
        await viewModel.generateNewPlan(apiClient: apiClient, userId: user.serverId)
        viewModel.sendPlanToWatch()
    }
}
