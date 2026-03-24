import SwiftUI

struct WatchWorkoutView: View {
    @State private var currentExercise = "Bench Press"
    @State private var setNumber = 1
    @State private var weight = 80.0
    @State private var reps = 8
    @State private var showRestTimer = false
    @State private var totalSets = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 8) {
            Text(currentExercise)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("Set \(setNumber)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                VStack {
                    Text("\(weight, specifier: "%.1f")")
                        .font(.title3.monospacedDigit().bold())
                    Text("kg")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .focusable()
                .digitalCrownRotation($weight, from: 0, through: 500, by: 2.5)

                Text("x")
                    .foregroundStyle(.secondary)

                VStack {
                    Text("\(reps)")
                        .font(.title3.monospacedDigit().bold())
                    Text("reps")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button {
                    totalSets += 1
                    setNumber += 1
                    showRestTimer = true
                } label: {
                    Image(systemName: "checkmark")
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }

            Text("\(totalSets) sets done")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showRestTimer) {
            WatchRestTimerView(seconds: 90) {
                showRestTimer = false
            }
        }
    }
}

#Preview {
    WatchWorkoutView()
}
