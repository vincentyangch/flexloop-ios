import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query private var users: [CachedUser]
    @State private var viewModel = HomeViewModel()
    @State private var showGuidedWorkout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Deload alert banner
                    if let deload = viewModel.deloadAlert, deload.recommended {
                        deloadBanner(deload)
                    }

                    // Weekly streak card
                    weeklyCard

                    // Next workout card
                    if let next = viewModel.nextWorkout {
                        nextWorkoutCard(next)
                    } else {
                        noWorkoutCard
                    }

                    // Recent sessions
                    if !viewModel.recentSessions.isEmpty {
                        recentSessionsCard
                    }
                }
                .padding()
            }
            .navigationTitle("FlexLoop")
            .onAppear { viewModel.loadDashboard(context: context) }
            .task {
                guard let user = users.first else { return }
                let apiClient = APIClient(config: .current)
                await viewModel.loadNextWorkout(apiClient: apiClient, userId: user.serverId)
                await viewModel.checkDeload(apiClient: apiClient, userId: user.serverId)
            }
            .fullScreenCover(isPresented: $showGuidedWorkout) {
                if let next = viewModel.nextWorkout, let user = users.first {
                    GuidedWorkoutView(
                        planDay: next.day,
                        planDayId: next.day.id,
                        userId: user.serverId,
                        exerciseNames: viewModel.exerciseNames,
                        unitSymbol: user.weightUnit
                    )
                }
            }
            .onChange(of: showGuidedWorkout) { _, isShowing in
                if !isShowing {
                    viewModel.loadDashboard(context: context)
                    Task {
                        guard let user = users.first else { return }
                        let apiClient = APIClient(config: .current)
                        do {
                            _ = try await SyncService.performSync(
                                apiClient: apiClient,
                                context: context,
                                userId: user.serverId
                            )
                            viewModel.loadDashboard(context: context)
                        } catch {
                            print("Post-workout sync failed: \(error.localizedDescription)")
                        }
                        await viewModel.loadNextWorkout(apiClient: apiClient, userId: user.serverId)
                    }
                }
            }
        }
    }

    // MARK: - Next Workout Card

    private func nextWorkoutCard(_ next: APINextWorkoutResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "home.nextWorkout"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Day \(next.nextDayNumber): \(next.day.label)")
                        .font(.title3.bold())
                    Text(next.day.focus.replacingOccurrences(of: ",", with: " / "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(next.planName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(next.nextDayNumber)/\(next.cycleLength)")
                        .font(.caption.monospacedDigit())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }

            // Exercise preview
            let allExercises = next.day.exerciseGroups.flatMap(\.exercises)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(allExercises.prefix(4), id: \.exerciseId) { ex in
                    HStack {
                        Text(viewModel.exerciseNames[ex.exerciseId] ?? "Exercise #\(ex.exerciseId)")
                            .font(.subheadline)
                        Spacer()
                        Text("\(ex.sets)x\(ex.reps)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                if allExercises.count > 4 {
                    Text(String(localized: "home.moreExercises \(allExercises.count - 4)"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                showGuidedWorkout = true
            } label: {
                Label(String(localized: "home.startWorkout"), systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var noWorkoutCard: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.title)
                .foregroundStyle(.secondary)
            Text(String(localized: "home.noPlan"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(String(localized: "home.noPlan.hint"))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Weekly Card

    private var weeklyCard: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(String(localized: "home.thisWeek"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(String(localized: "home.sessions \(viewModel.weeklySessionCount)"))
                    .font(.title2.bold())
            }
            Spacer()
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Recent Sessions

    private var recentSessionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "home.recentSessions"))
                .font(.headline)

            ForEach(viewModel.recentSessions, id: \.startedAt) { session in
                HStack {
                    VStack(alignment: .leading) {
                        Text(session.source.rawValue
                            .replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.subheadline.bold())
                        Text(session.startedAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(session.sets?.count ?? 0) sets")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Deload Banner

    private func deloadBanner(_ deload: DeloadAlert) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(String(localized: "home.deloadRecommended"))
                    .font(.subheadline.bold())
                Spacer()
                Text(deload.confidence.uppercased())
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(deload.confidence == "high" ? Color.red.opacity(0.2) : Color.orange.opacity(0.2))
                    .clipShape(Capsule())
            }
            Text(deload.reason)
                .font(.caption)
                .foregroundStyle(.secondary)
            ForEach(deload.signals, id: \.self) { signal in
                HStack(spacing: 4) {
                    Circle().fill(.orange).frame(width: 4, height: 4)
                    Text(signal).font(.caption2).foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3)))
    }
}
