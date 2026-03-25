import SwiftUI

struct SessionDetailView: View {
    let session: CachedWorkoutSession

    var body: some View {
        List {
            Section("Session Info") {
                LabeledContent("Date", value: session.startedAt, format: .dateTime)
                LabeledContent("Source", value: session.source.rawValue
                    .replacingOccurrences(of: "_", with: " ").capitalized)
                if let end = session.completedAt {
                    let minutes = Int(end.timeIntervalSince(session.startedAt) / 60)
                    LabeledContent("Duration", value: "\(minutes) minutes")
                }
                LabeledContent("Synced", value: session.isSynced ? "Yes" : "Pending")
            }

            if let notes = session.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }

            Section("Sets (\(session.sets?.count ?? 0))") {
                ForEach(session.sets?.sorted(by: { $0.setNumber < $1.setNumber }) ?? [],
                        id: \.setNumber) { set in
                    HStack {
                        Text(set.setType.rawValue.replacingOccurrences(of: "_", with: " ").uppercased())
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Text("Set \(set.setNumber)")
                            .font(.subheadline)

                        Spacer()

                        if let w = set.weight, let r = set.reps {
                            let unit = WeightUnit.current
                            Text("\(unit.fromKgRounded(w), specifier: "%.1f") \(unit.symbol) x \(r)")
                                .font(.subheadline.monospacedDigit())
                        }

                        if let rpe = set.rpe {
                            Text("RPE \(rpe, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Session Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
