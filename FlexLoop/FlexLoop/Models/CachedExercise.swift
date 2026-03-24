import Foundation
import SwiftData

@Model
final class CachedExercise {
    @Attribute(.unique) var serverId: Int
    var name: String
    var muscleGroup: String
    var equipment: String
    var category: String
    var difficulty: String
    var sourcePlugin: String?

    init(serverId: Int, name: String, muscleGroup: String,
         equipment: String, category: String, difficulty: String,
         sourcePlugin: String? = nil) {
        self.serverId = serverId
        self.name = name
        self.muscleGroup = muscleGroup
        self.equipment = equipment
        self.category = category
        self.difficulty = difficulty
        self.sourcePlugin = sourcePlugin
    }
}
