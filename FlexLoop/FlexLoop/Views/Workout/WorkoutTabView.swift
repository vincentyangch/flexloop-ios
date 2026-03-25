import SwiftUI

struct WorkoutTabView: View {
    @State private var isWorkoutActive = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text(String(localized: "home.startWorkout"))
                    .font(.title2.bold())
                Button {
                    isWorkoutActive = true
                } label: {
                    Label(String(localized: "home.startWorkout"), systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 32)
                Spacer()
            }
            .navigationTitle(String(localized: "tab.workout"))
        }
        .fullScreenCover(isPresented: $isWorkoutActive) {
            ActiveWorkoutView()
        }
    }
}
