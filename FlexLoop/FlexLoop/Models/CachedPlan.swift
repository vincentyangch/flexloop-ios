import Foundation
import SwiftData

@Model
final class CachedPlan {
    @Attribute(.unique) var serverId: Int
    var userId: Int
    var name: String
    var splitType: String
    var cycleLength: Int
    var status: String
    var aiGenerated: Bool
    var daysJson: Data?
    var lastSyncedAt: Date?

    init(serverId: Int, userId: Int, name: String, splitType: String,
         cycleLength: Int = 3, status: String = "active",
         aiGenerated: Bool = false, daysJson: Data? = nil) {
        self.serverId = serverId
        self.userId = userId
        self.name = name
        self.splitType = splitType
        self.cycleLength = cycleLength
        self.status = status
        self.aiGenerated = aiGenerated
        self.daysJson = daysJson
    }
}
