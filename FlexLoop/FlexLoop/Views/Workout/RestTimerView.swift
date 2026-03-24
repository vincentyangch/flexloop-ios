import SwiftUI

struct RestTimerView: View {
    let timeRemaining: Int
    let isActive: Bool
    let onStop: () -> Void

    var body: some View {
        if isActive {
            HStack {
                Image(systemName: "timer")
                    .foregroundStyle(.blue)

                Text(formattedTime)
                    .font(.title2.monospacedDigit().bold())
                    .foregroundStyle(timeRemaining <= 10 ? .red : .primary)

                Spacer()

                Button(String(localized: "workout.skip"), action: onStop)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
