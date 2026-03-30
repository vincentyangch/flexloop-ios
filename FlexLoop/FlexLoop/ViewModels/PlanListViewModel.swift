import Foundation
import Observation

@Observable
final class PlanListViewModel {
    var plans: [APIPlanResponse] = []
    var activePlan: APIPlanResponse?
    var isLoading = false
    var isGenerating = false
    var errorMessage: String?
    var exerciseNames: [Int: String] = [:]

    func loadPlans(apiClient: APIClient, userId: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            // Load exercise names
            if exerciseNames.isEmpty {
                let exerciseList = try await apiClient.fetchExercises()
                for ex in exerciseList.exercises {
                    exerciseNames[ex.id] = ex.name
                }
            }

            let response = try await apiClient.fetchPlans(userId: userId)
            plans = response.plans
            activePlan = plans.first(where: { $0.status == "active" })
        } catch {
            errorMessage = String(localized: "error.loadPlans")
        }

        isLoading = false
    }

    func activatePlan(apiClient: APIClient, planId: Int) async {
        do {
            let updated = try await apiClient.activatePlan(id: planId)
            activePlan = updated

            // Refresh full list to get updated statuses
            if let userId = plans.first?.userId {
                await loadPlans(apiClient: apiClient, userId: userId)
            }
        } catch {
            errorMessage = String(localized: "error.activatePlan")
        }
    }

    func archivePlan(apiClient: APIClient, planId: Int) async {
        do {
            _ = try await apiClient.archivePlan(id: planId)
            if let userId = plans.first?.userId {
                await loadPlans(apiClient: apiClient, userId: userId)
            }
        } catch {
            errorMessage = String(localized: "error.archivePlan")
        }
    }

    func deletePlan(apiClient: APIClient, planId: Int) async {
        do {
            try await apiClient.deletePlan(id: planId)
            plans.removeAll(where: { $0.id == planId })
            if activePlan?.id == planId {
                activePlan = plans.first(where: { $0.status == "active" })
            }
        } catch {
            errorMessage = String(localized: "error.deletePlan")
        }
    }

    func generatePlan(apiClient: APIClient, userId: Int, planMode: String) async {
        isGenerating = true
        errorMessage = nil

        do {
            let response = try await apiClient.generatePlan(userId: userId, planMode: planMode)
            if response.status == "success" {
                await loadPlans(apiClient: apiClient, userId: userId)
            } else {
                errorMessage = response.message ?? String(localized: "error.invalidPlan")
            }
        } catch {
            errorMessage = String(localized: "error.generatePlan")
        }

        isGenerating = false
    }

    func exerciseName(for id: Int) -> String {
        exerciseNames[id] ?? "Exercise #\(id)"
    }
}
