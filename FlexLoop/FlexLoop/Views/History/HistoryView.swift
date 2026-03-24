import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \CachedWorkoutSession.startedAt, order: .reverse)
    private var sessions: [CachedWorkoutSession]

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedByMonth, id: \.key) { month, monthSessions in
                    Section(month) {
                        ForEach(monthSessions, id: \.startedAt) { session in
                            NavigationLink {
                                SessionDetailView(session: session)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(session.startedAt, style: .date)
                                            .font(.subheadline.bold())
                                        Text(session.source.rawValue
                                            .replacingOccurrences(of: "_", with: " ").capitalized)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing) {
                                        Text("\(session.sets?.count ?? 0) sets")
                                            .font(.subheadline)
                                        if let duration = sessionDuration(session) {
                                            Text(duration)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    if !session.isSynced {
                                        Image(systemName: "arrow.triangle.2.circlepath")
                                            .font(.caption)
                                            .foregroundStyle(.orange)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .overlay {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Your completed workouts will appear here.")
                    )
                }
            }
        }
    }

    private var groupedByMonth: [(key: String, value: [CachedWorkoutSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let grouped = Dictionary(grouping: sessions) { formatter.string(from: $0.startedAt) }
        return grouped.sorted { $0.value.first!.startedAt > $1.value.first!.startedAt }
    }

    private func sessionDuration(_ session: CachedWorkoutSession) -> String? {
        guard let end = session.completedAt else { return nil }
        let minutes = Int(end.timeIntervalSince(session.startedAt) / 60)
        return "\(minutes)min"
    }
}
