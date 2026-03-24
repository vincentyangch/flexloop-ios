import SwiftUI
import WatchKit

struct WatchRestTimerView: View {
    let seconds: Int
    let onComplete: () -> Void

    @State private var remaining: Int
    @State private var timer: Timer?

    init(seconds: Int, onComplete: @escaping () -> Void) {
        self.seconds = seconds
        self.onComplete = onComplete
        self._remaining = State(initialValue: seconds)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Rest")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(formattedTime)
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundStyle(remaining <= 10 ? .red : .primary)

            Button("Skip") {
                timer?.invalidate()
                onComplete()
            }
            .font(.caption)
        }
        .onAppear { startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private var formattedTime: String {
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remaining > 0 {
                remaining -= 1
            } else {
                timer?.invalidate()
                WKInterfaceDevice.current().play(.notification)
                onComplete()
            }
        }
    }
}

#Preview {
    WatchRestTimerView(seconds: 90) {}
}
