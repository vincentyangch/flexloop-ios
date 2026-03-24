import SwiftUI
import Charts

struct VolumeChartCard: View {
    let data: [VolumeEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Volume by Muscle Group")
                .font(.headline)

            let totalSets = data.reduce(0) { $0 + $1.totalSets }
            Text("\(totalSets) total working sets this week")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(data) { entry in
                BarMark(
                    x: .value("Sets", entry.totalSets),
                    y: .value("Muscle", entry.muscleGroup)
                )
                .foregroundStyle(colorForMuscle(entry.muscleGroup))
                .annotation(position: .trailing, alignment: .leading) {
                    Text("\(entry.totalSets)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis {
                AxisMarks(position: .bottom)
            }
            .frame(height: CGFloat(max(data.count * 36, 100)))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func colorForMuscle(_ name: String) -> Color {
        switch name.lowercased() {
        case "chest": return .blue
        case "back": return .green
        case "quads": return .red
        case "hamstrings": return .orange
        case "shoulders": return .purple
        case "biceps": return .cyan
        case "triceps": return .indigo
        case "glutes": return .pink
        case "core": return .yellow
        case "calves": return .mint
        default: return .gray
        }
    }
}
