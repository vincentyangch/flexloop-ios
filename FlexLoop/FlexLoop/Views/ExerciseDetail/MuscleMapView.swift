import SwiftUI

struct MuscleMapView: View {
    let primaryMuscles: [String]
    let secondaryMuscles: [String]

    private let allMuscles = [
        "chest", "back", "shoulders", "biceps", "triceps",
        "quads", "hamstrings", "glutes", "core", "calves",
        "forearms", "traps",
    ]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 8) {
            ForEach(allMuscles, id: \.self) { muscle in
                muscleCell(muscle)
            }
        }
    }

    private func muscleCell(_ muscle: String) -> some View {
        let isPrimary = primaryMuscles.contains(muscle)
        let isSecondary = secondaryMuscles.contains(muscle)

        return VStack(spacing: 4) {
            Image(systemName: iconForMuscle(muscle))
                .font(.title3)
                .foregroundStyle(isPrimary ? .red : isSecondary ? .orange : .gray.opacity(0.3))
                .scaleEffect(isPrimary ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                           value: isPrimary)

            Text(muscle.capitalized)
                .font(.caption2)
                .foregroundStyle(isPrimary ? .primary : isSecondary ? .secondary : .tertiary)
        }
        .frame(height: 50)
    }

    private func iconForMuscle(_ muscle: String) -> String {
        switch muscle {
        case "chest": return "figure.arms.open"
        case "back": return "figure.walk"
        case "shoulders": return "figure.boxing"
        case "biceps": return "figure.strengthtraining.functional"
        case "triceps": return "figure.strengthtraining.traditional"
        case "quads": return "figure.run"
        case "hamstrings": return "figure.flexibility"
        case "glutes": return "figure.dance"
        case "core": return "figure.core.training"
        case "calves": return "figure.step.training"
        case "forearms": return "hand.raised.fill"
        case "traps": return "figure.rowing"
        default: return "figure.stand"
        }
    }
}
