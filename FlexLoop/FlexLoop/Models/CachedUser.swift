import Foundation
import SwiftData

@Model
final class CachedUser {
    @Attribute(.unique) var serverId: Int
    var name: String
    var gender: String
    var age: Int
    var heightCm: Double
    var weightKg: Double
    var experienceLevel: String
    var goals: String
    var availableEquipment: [String]
    var lastSyncedAt: Date?

    init(serverId: Int, name: String, gender: String, age: Int,
         heightCm: Double, weightKg: Double, experienceLevel: String,
         goals: String, availableEquipment: [String] = []) {
        self.serverId = serverId
        self.name = name
        self.gender = gender
        self.age = age
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.experienceLevel = experienceLevel
        self.goals = goals
        self.availableEquipment = availableEquipment
    }
}
