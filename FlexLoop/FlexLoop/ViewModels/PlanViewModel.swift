import Foundation
import SwiftData
import Observation

@Observable
final class PlanViewModel {
    var plan: APIPlanGenerateResponse?
    var exerciseNames: [Int: String] = [:]
    var isLoading = false
    var isGenerating = false
    var errorMessage: String?

    func loadPlan(apiClient: APIClient, userId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            // Fetch exercises for name mapping
            let exerciseList: APIExerciseList = try await apiClient.fetchExercises()
            for ex in exerciseList.exercises {
                exerciseNames[ex.id] = ex.name
            }

            // Generate a plan (or fetch existing — for now we generate)
            let response = try await apiClient.generatePlan(userId: userId)
            if response.status == "success" {
                plan = response
            } else {
                errorMessage = response.message ?? "Failed to load plan"
            }
        } catch {
            errorMessage = "Could not load plan. Check server connection."
        }

        isLoading = false
    }

    func generateNewPlan(apiClient: APIClient, userId: Int) async {
        isGenerating = true
        errorMessage = nil

        do {
            let response = try await apiClient.generatePlan(userId: userId)
            if response.status == "success" {
                plan = response

                // Fetch exercise names if not loaded
                if exerciseNames.isEmpty {
                    let exerciseList = try await apiClient.fetchExercises()
                    for ex in exerciseList.exercises {
                        exerciseNames[ex.id] = ex.name
                    }
                }
            } else {
                errorMessage = response.message ?? "AI returned an invalid plan"
            }
        } catch {
            errorMessage = "Failed to generate plan. Check server connection."
        }

        isGenerating = false
    }

    func exerciseName(for id: Int) -> String {
        exerciseNames[id] ?? "Exercise #\(id)"
    }
}
