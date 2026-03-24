import SwiftUI

struct PlanDayCard: View {
    let day: APIPlanDay
    let isToday: Bool
    let exerciseName: (Int) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Day \(day.dayNumber): \(day.label)")
                    .font(.headline)
                Spacer()
                if isToday {
                    Text("TODAY")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            Text(day.focus.replacingOccurrences(of: ",", with: " / "))
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(Array(day.exerciseGroups.enumerated()), id: \.offset) { _, group in
                if group.exercises.isEmpty { EmptyView() }
                else {
                    if group.groupType != "straight" {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption2)
                            Text(group.groupType.uppercased())
                                .font(.caption2.bold())
                        }
                        .foregroundStyle(.blue)
                        .padding(.top, 2)
                    }

                    ForEach(Array(group.exercises.enumerated()), id: \.offset) { _, exercise in
                        HStack {
                            Text(exerciseName(exercise.exerciseId))
                                .font(.subheadline)
                            Spacer()
                            Text("\(exercise.sets)x\(exercise.reps)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                            if let rpe = exercise.rpeTarget {
                                Text("RPE \(rpe, specifier: "%.0f")")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.orange.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }

                        if let notes = exercise.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(isToday ? Color.blue.opacity(0.05) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.blue.opacity(0.3) : Color.clear)
        )
    }
}
