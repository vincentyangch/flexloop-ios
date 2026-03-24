import Foundation
import SwiftData

@Model
final class CachedPlan {
    @Attribute(.unique) var serverId: Int
    var userId: Int
    var name: String
    var splitType: String
    var blockStart: Date
    var blockEnd: Date
    var status: String
    var aiGenerated: Bool
    var daysJson: Data?
    var lastSyncedAt: Date?

    init(serverId: Int, userId: Int, name: String, splitType: String,
         blockStart: Date, blockEnd: Date, status: String = "active",
         aiGenerated: Bool = false, daysJson: Data? = nil) {
        self.serverId = serverId
        self.userId = userId
        self.name = name
        self.splitType = splitType
        self.blockStart = blockStart
        self.blockEnd = blockEnd
        self.status = status
        self.aiGenerated = aiGenerated
        self.daysJson = daysJson
    }
}
