import Foundation
import SwiftData

enum SetType: String, Codable {
    case warmUp = "warm_up"
    case working
    case drop
    case amrap
    case backoff
}

@Model
final class CachedWorkoutSet {
    var session: CachedWorkoutSession?
    var exerciseServerId: Int
    var exerciseGroupId: Int?
    var setNumber: Int
    var setType: SetType
    var weight: Double?
    var reps: Int?
    var rpe: Double?
    var durationSec: Int?
    var distanceM: Double?
    var restSec: Int?

    init(session: CachedWorkoutSession? = nil, exerciseServerId: Int,
         exerciseGroupId: Int? = nil, setNumber: Int,
         setType: SetType = .working, weight: Double? = nil,
         reps: Int? = nil, rpe: Double? = nil, durationSec: Int? = nil,
         distanceM: Double? = nil, restSec: Int? = nil) {
        self.session = session
        self.exerciseServerId = exerciseServerId
        self.exerciseGroupId = exerciseGroupId
        self.setNumber = setNumber
        self.setType = setType
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.durationSec = durationSec
        self.distanceM = distanceM
        self.restSec = restSec
    }
}
