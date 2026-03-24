import Foundation
import Observation

struct E1RMDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct E1RMExercise: Identifiable {
    let id: Int
    let name: String
    var points: [E1RMDataPoint]
}

struct VolumeEntry: Identifiable {
    let id = UUID()
    let muscleGroup: String
    let totalSets: Int
}

@Observable
final class ProgressViewModel {
    var e1rmData: [E1RMExercise] = []
    var volumeData: [VolumeEntry] = []
    var isLoading = false
    var errorMessage: String?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func loadProgress(apiClient: APIClient, userId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            async let e1rmTask = loadE1RM(apiClient: apiClient, userId: userId)
            async let volumeTask = loadVolume(apiClient: apiClient, userId: userId)
            _ = try await (e1rmTask, volumeTask)
        } catch {
            errorMessage = "Could not load progress data."
        }

        isLoading = false
    }

    private func loadE1RM(apiClient: APIClient, userId: Int) async throws {
        struct E1RMResponse: Codable {
            let exerciseId: Int
            let exerciseName: String
            let points: [PointData]

            enum CodingKeys: String, CodingKey {
                case exerciseId = "exercise_id"
                case exerciseName = "exercise_name"
                case points
            }
        }

        struct PointData: Codable {
            let date: String
            let value: Double
        }

        let response: [E1RMResponse] = try await apiClient.get(
            "/api/progress/\(userId)/estimated-1rm"
        )

        e1rmData = response.map { ex in
            E1RMExercise(
                id: ex.exerciseId,
                name: ex.exerciseName,
                points: ex.points.compactMap { p in
                    guard let date = dateFormatter.date(from: p.date) else { return nil }
                    return E1RMDataPoint(date: date, value: p.value)
                }
            )
        }
        .filter { !$0.points.isEmpty }
        .sorted { $0.name < $1.name }
    }

    private func loadVolume(apiClient: APIClient, userId: Int) async throws {
        struct VolumeResponse: Codable {
            let muscleGroup: String
            let totalSets: Int

            enum CodingKeys: String, CodingKey {
                case muscleGroup = "muscle_group"
                case totalSets = "total_sets"
            }
        }

        let response: [VolumeResponse] = try await apiClient.get(
            "/api/progress/\(userId)/volume"
        )

        volumeData = response.map {
            VolumeEntry(muscleGroup: $0.muscleGroup.capitalized, totalSets: $0.totalSets)
        }
    }
}
