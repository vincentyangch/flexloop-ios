import Foundation
import SwiftData

@Model
final class CachedUser {
    @Attribute(.unique) var serverId: Int
    var name: String
    var gender: String
    var age: Int
    var height: Double
    var weight: Double
    var weightUnit: String
    var heightUnit: String
    var experienceLevel: String
    var goals: String
    var availableEquipment: [String]
    var lastSyncedAt: Date?

    init(serverId: Int, name: String, gender: String, age: Int,
         height: Double, weight: Double, weightUnit: String, heightUnit: String,
         experienceLevel: String, goals: String, availableEquipment: [String] = []) {
        self.serverId = serverId
        self.name = name
        self.gender = gender
        self.age = age
        self.height = height
        self.weight = weight
        self.weightUnit = weightUnit
        self.heightUnit = heightUnit
        self.experienceLevel = experienceLevel
        self.goals = goals
        self.availableEquipment = availableEquipment
    }
}

extension CachedUser {
    var unit: WeightUnit { WeightUnit(rawValue: weightUnit) ?? .kg }
}
