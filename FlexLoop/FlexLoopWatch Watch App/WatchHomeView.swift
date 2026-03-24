import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager

    private var todayLabel: String {
        sessionManager.todayPlan?.label ?? "No Plan"
    }

    private var exerciseCount: Int {
        sessionManager.todayPlan?.exercises.count ?? 0
    }

    private var hasPlan: Bool {
        sessionManager.todayPlan != nil
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(todayLabel)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                if hasPlan {
                    Text("\(exerciseCount) exercises")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    NavigationLink("Start") {
                        WatchWorkoutView(exercises: sessionManager.todayPlan?.exercises ?? [])
                            .environmentObject(sessionManager)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Text("Open FlexLoop on iPhone\nto generate a plan")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("FlexLoop")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WatchHomeView()
        .environmentObject(WatchSessionManager.shared)
}
