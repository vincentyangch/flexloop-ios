import Foundation
import SwiftData
import Observation

@Observable
final class OnboardingViewModel {
    var name = ""
    var gender = "male"
    var age = 25
    var heightCm = 170.0
    var weightKg = 70.0
    var experienceLevel = "beginner"
    var goals = "general fitness"
    var availableEquipment: Set<String> = []
    var daysPerWeek = 3

    var isComplete = false
    var isSubmitting = false
    var errorMessage: String?

    let genders = ["male", "female", "other"]
    let experienceLevels = ["beginner", "intermediate", "advanced"]
    let goalOptions = ["hypertrophy", "strength", "general fitness", "weight loss", "endurance"]
    let equipmentOptions = [
        "barbell", "dumbbells", "kettlebells", "pull_up_bar",
        "cables", "machines", "bands", "bodyweight_only",
    ]

    func submit(apiClient: APIClient, context: ModelContext) async {
        isSubmitting = true
        errorMessage = nil

        let userData = APIUserCreate(
            name: name, gender: gender, age: age,
            heightCm: heightCm, weightKg: weightKg,
            experienceLevel: experienceLevel, goals: goals,
            availableEquipment: Array(availableEquipment)
        )

        do {
            let apiUser: APIUser = try await apiClient.post("/api/profiles", body: userData)

            let cachedUser = CachedUser(
                serverId: apiUser.id, name: apiUser.name, gender: apiUser.gender,
                age: apiUser.age, heightCm: apiUser.heightCm, weightKg: apiUser.weightKg,
                experienceLevel: apiUser.experienceLevel, goals: apiUser.goals,
                availableEquipment: apiUser.availableEquipment
            )
            context.insert(cachedUser)
            try context.save()

            isComplete = true
        } catch {
            errorMessage = "Failed to create profile. Check your server connection."
        }

        isSubmitting = false
    }
}
