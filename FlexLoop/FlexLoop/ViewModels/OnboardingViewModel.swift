import Foundation
import SwiftData
import Observation

@Observable
final class OnboardingViewModel {
    var name = ""
    var gender = "male"
    var age = 25
    var height = 170.0
    var weight = 70.0
    var weightUnit: WeightUnit = .kg
    var experienceLevel = "beginner"
    var goals = "general fitness"
    var availableEquipment: Set<String> = []
    var daysPerWeek = 3

    var isComplete = false
    var isSubmitting = false
    var errorMessage: String?

    var heightUnit: String { weightUnit == .kg ? "cm" : "in" }

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
            height: height, weight: weight,
            weightUnit: weightUnit.rawValue, heightUnit: heightUnit,
            experienceLevel: experienceLevel, goals: goals,
            availableEquipment: Array(availableEquipment)
        )

        do {
            let apiUser: APIUser = try await apiClient.post("/api/profiles", body: userData)

            let cachedUser = CachedUser(
                serverId: apiUser.id, name: apiUser.name, gender: apiUser.gender,
                age: apiUser.age, height: apiUser.height, weight: apiUser.weight,
                weightUnit: apiUser.weightUnit, heightUnit: apiUser.heightUnit,
                experienceLevel: apiUser.experienceLevel, goals: apiUser.goals,
                availableEquipment: apiUser.availableEquipment
            )
            context.insert(cachedUser)
            try context.save()

            // Request HealthKit authorization
            try? await HealthKitManager.shared.requestAuthorization()

            isComplete = true
        } catch {
            errorMessage = "Failed to create profile. Check your server connection."
        }

        isSubmitting = false
    }
}
