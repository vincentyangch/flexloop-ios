import SwiftUI
import Charts

struct E1RMChartCard: View {
    let exercise: E1RMExercise
    let unitSymbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(exercise.name)
                    .font(.headline)
                Spacer()
                if let latest = exercise.points.last {
                    Text("\(latest.value, specifier: "%.1f") \(unitSymbol)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                }
            }

            if let trend = trendText {
                Text(trend)
                    .font(.caption)
                    .foregroundStyle(trendColor)
            }

            Chart(exercise.points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Est. 1RM", point.value)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Est. 1RM", point.value)
                )
                .foregroundStyle(.blue)
                .symbolSize(30)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var trendText: String? {
        guard exercise.points.count >= 2,
              let first = exercise.points.first,
              let last = exercise.points.last else { return nil }

        let diff = last.value - first.value
        let sign = diff >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", diff)) \(unitSymbol) over \(exercise.points.count) sessions"
    }

    private var trendColor: Color {
        guard exercise.points.count >= 2,
              let first = exercise.points.first,
              let last = exercise.points.last else { return .secondary }
        return last.value >= first.value ? .green : .red
    }
}
