import SwiftUI

struct WatchHomeView: View {
    @State private var todayLabel = "Push Day"
    @State private var exerciseCount = 6
    @State private var isWorkoutActive = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(todayLabel)
                    .font(.headline)

                Text("\(exerciseCount) exercises")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                NavigationLink("Start") {
                    WatchWorkoutView()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .navigationTitle("FlexLoop")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WatchHomeView()
}
