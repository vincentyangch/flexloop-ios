import Foundation
import SwiftData

enum WorkoutSource: String, Codable {
    case plan
    case template
    case adHoc = "ad_hoc"
}

@Model
final class CachedWorkoutSession {
    var serverId: Int?
    var userId: Int?
    var planDayId: Int?
    var templateId: Int?
    var source: WorkoutSource
    var startedAt: Date
    var completedAt: Date?
    var notes: String?
    var isSynced: Bool

    @Relationship(deleteRule: .cascade, inverse: \CachedWorkoutSet.session)
    var sets: [CachedWorkoutSet]?

    init(serverId: Int? = nil, userId: Int? = nil, planDayId: Int? = nil,
         templateId: Int? = nil, source: WorkoutSource = .adHoc,
         startedAt: Date = Date(), notes: String? = nil) {
        self.serverId = serverId
        self.userId = userId
        self.planDayId = planDayId
        self.templateId = templateId
        self.source = source
        self.startedAt = startedAt
        self.notes = notes
        self.isSynced = false
    }
}
