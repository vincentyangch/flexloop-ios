import Foundation

// MARK: - User / Profile

struct APIUser: Codable, Sendable {
    let id: Int
    let name: String
    let gender: String
    let age: Int
    let height: Double
    let weight: Double
    let weightUnit: String
    let heightUnit: String
    let experienceLevel: String
    let goals: String
    let availableEquipment: [String]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, gender, age, goals, height, weight
        case weightUnit = "weight_unit"
        case heightUnit = "height_unit"
        case experienceLevel = "experience_level"
        case availableEquipment = "available_equipment"
        case createdAt = "created_at"
    }
}

struct APIUserCreate: Codable, Sendable {
    let name: String
    let gender: String
    let age: Int
    let height: Double
    let weight: Double
    let weightUnit: String
    let heightUnit: String
    let experienceLevel: String
    let goals: String
    let availableEquipment: [String]

    enum CodingKeys: String, CodingKey {
        case name, gender, age, goals, height, weight
        case weightUnit = "weight_unit"
        case heightUnit = "height_unit"
        case experienceLevel = "experience_level"
        case availableEquipment = "available_equipment"
    }
}

// MARK: - Exercise

struct APIExercise: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let muscleGroup: String
    let equipment: String
    let category: String
    let difficulty: String

    enum CodingKeys: String, CodingKey {
        case id, name, equipment, category, difficulty
        case muscleGroup = "muscle_group"
    }
}

struct APIExerciseList: Codable, Sendable {
    let exercises: [APIExercise]
    let total: Int
}

// MARK: - Workout

struct APIWorkoutSet: Codable, Identifiable, Sendable {
    let id: Int?
    let exerciseId: Int
    let exerciseGroupId: Int?
    let setNumber: Int
    let setType: String
    let weight: Double?
    let reps: Int?
    let rpe: Double?
    let durationSec: Int?
    let distanceM: Double?
    let restSec: Int?

    enum CodingKeys: String, CodingKey {
        case id, weight, reps, rpe
        case exerciseId = "exercise_id"
        case exerciseGroupId = "exercise_group_id"
        case setNumber = "set_number"
        case setType = "set_type"
        case durationSec = "duration_sec"
        case distanceM = "distance_m"
        case restSec = "rest_sec"
    }
}

struct APIWorkoutSession: Codable, Identifiable, Sendable {
    let id: Int
    let userId: Int
    let planDayId: Int?
    let source: String
    let startedAt: String
    let completedAt: String?
    let notes: String?
    let sets: [APIWorkoutSet]

    enum CodingKeys: String, CodingKey {
        case id, source, notes, sets
        case userId = "user_id"
        case planDayId = "plan_day_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

// MARK: - Sync

struct APISyncRequest: Codable, Sendable {
    let userId: Int
    let workouts: [APISyncWorkout]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case workouts
    }
}

struct APISyncWorkout: Codable, Sendable {
    let planDayId: Int?
    let source: String
    let startedAt: String
    let completedAt: String?
    let notes: String?
    let sets: [APISyncSet]

    enum CodingKeys: String, CodingKey {
        case source, notes, sets
        case planDayId = "plan_day_id"
        case startedAt = "started_at"
        case completedAt = "completed_at"
    }
}

struct APISyncSet: Codable, Sendable {
    let exerciseId: Int
    let exerciseGroupId: Int?
    let setNumber: Int
    let setType: String
    let weight: Double?
    let reps: Int?
    let rpe: Double?
    let durationSec: Int?
    let distanceM: Double?
    let restSec: Int?

    enum CodingKeys: String, CodingKey {
        case weight, reps, rpe
        case exerciseId = "exercise_id"
        case exerciseGroupId = "exercise_group_id"
        case setNumber = "set_number"
        case setType = "set_type"
        case durationSec = "duration_sec"
        case distanceM = "distance_m"
        case restSec = "rest_sec"
    }
}

struct APISyncResponse: Codable, Sendable {
    let workoutsSynced: Int

    enum CodingKeys: String, CodingKey {
        case workoutsSynced = "workouts_synced"
    }
}

// MARK: - AI

struct AIChatRequest: Codable, Sendable {
    let userId: Int
    let message: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case message
    }
}

struct AIChatResponse: Codable, Sendable {
    let reply: String
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case reply
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

// MARK: - Plan

struct APIPlanGenerateRequest: Codable, Sendable {
    let userId: Int

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
    }
}

struct APISetTarget: Codable, Sendable {
    var setNumber: Int
    var targetWeight: Double?
    var targetReps: Int
    var targetRpe: Double?

    enum CodingKeys: String, CodingKey {
        case setNumber = "set_number"
        case targetWeight = "target_weight"
        case targetReps = "target_reps"
        case targetRpe = "target_rpe"
    }
}

struct APIPlanExercise: Codable, Sendable, Identifiable {
    let id: Int?
    let exerciseId: Int
    var order: Int
    var sets: Int
    var reps: Int
    var weight: Double?
    var rpeTarget: Double?
    var setsJson: [APISetTarget]?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, order, sets, reps, weight, notes
        case exerciseId = "exercise_id"
        case rpeTarget = "rpe_target"
        case setsJson = "sets_json"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        exerciseId = try container.decode(Int.self, forKey: .exerciseId)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        sets = try container.decode(Int.self, forKey: .sets)
        reps = try container.decode(Int.self, forKey: .reps)
        weight = try container.decodeIfPresent(Double.self, forKey: .weight)
        rpeTarget = try container.decodeIfPresent(Double.self, forKey: .rpeTarget)
        setsJson = try container.decodeIfPresent([APISetTarget].self, forKey: .setsJson)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
}

struct APIPlanExerciseGroup: Codable, Sendable, Identifiable {
    let id: Int?
    let groupType: String
    let order: Int
    let restAfterGroupSec: Int
    let exercises: [APIPlanExercise]

    enum CodingKeys: String, CodingKey {
        case id, order, exercises
        case groupType = "group_type"
        case restAfterGroupSec = "rest_after_group_sec"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        groupType = try container.decode(String.self, forKey: .groupType)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        restAfterGroupSec = try container.decodeIfPresent(Int.self, forKey: .restAfterGroupSec) ?? 90
        exercises = try container.decode([APIPlanExercise].self, forKey: .exercises)
    }
}

struct APIPlanDay: Codable, Sendable, Identifiable {
    let id: Int?
    let dayNumber: Int
    var label: String
    var focus: String
    let exerciseGroups: [APIPlanExerciseGroup]

    enum CodingKeys: String, CodingKey {
        case id, label, focus
        case dayNumber = "day_number"
        case exerciseGroups = "exercise_groups"
    }
}

struct APIPlanResponse: Codable, Sendable, Identifiable {
    let id: Int
    let userId: Int
    let name: String
    let splitType: String
    let cycleLength: Int
    let status: String
    let aiGenerated: Bool
    let createdAt: String
    let updatedAt: String?
    let days: [APIPlanDay]

    enum CodingKeys: String, CodingKey {
        case id, name, status, days
        case userId = "user_id"
        case splitType = "split_type"
        case cycleLength = "cycle_length"
        case aiGenerated = "ai_generated"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct APIPlanListResponse: Codable, Sendable {
    let plans: [APIPlanResponse]
    let total: Int
}

struct APIPlanCreate: Codable, Sendable {
    let userId: Int
    let name: String
    let splitType: String
    let cycleLength: Int
    let days: [APIPlanDayCreate]

    enum CodingKeys: String, CodingKey {
        case name, days
        case userId = "user_id"
        case splitType = "split_type"
        case cycleLength = "cycle_length"
    }
}

struct APIPlanDayCreate: Codable, Sendable {
    let dayNumber: Int
    let label: String
    let focus: String
    let exerciseGroups: [APIPlanExerciseGroupCreate]

    enum CodingKeys: String, CodingKey {
        case label, focus
        case dayNumber = "day_number"
        case exerciseGroups = "exercise_groups"
    }
}

struct APIPlanExerciseGroupCreate: Codable, Sendable {
    let groupType: String
    let order: Int
    let restAfterGroupSec: Int
    let exercises: [APIPlanExerciseCreate]

    enum CodingKeys: String, CodingKey {
        case order, exercises
        case groupType = "group_type"
        case restAfterGroupSec = "rest_after_group_sec"
    }
}

struct APIPlanExerciseCreate: Codable, Sendable {
    let exerciseId: Int
    let order: Int
    let sets: Int
    let reps: Int
    let weight: Double?
    let rpeTarget: Double?
    let setsJson: [APISetTarget]?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case order, sets, reps, weight, notes
        case exerciseId = "exercise_id"
        case rpeTarget = "rpe_target"
        case setsJson = "sets_json"
    }
}

struct APIPlanUpdate: Codable, Sendable {
    let name: String?
    let splitType: String?
    let cycleLength: Int?
    let days: [APIPlanDayCreate]?

    enum CodingKeys: String, CodingKey {
        case name, days
        case splitType = "split_type"
        case cycleLength = "cycle_length"
    }
}

struct APIPlanGenerateResponse: Codable, Sendable {
    let status: String
    let planId: Int?
    let planName: String?
    let splitType: String?
    let cycleLength: Int?
    let days: [APIPlanDay]?
    let inputTokens: Int?
    let outputTokens: Int?
    let message: String?
    let rawResponse: String?

    enum CodingKeys: String, CodingKey {
        case status, days, message
        case planId = "plan_id"
        case planName = "plan_name"
        case splitType = "split_type"
        case cycleLength = "cycle_length"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case rawResponse = "raw_response"
    }
}

// MARK: - Cycle Tracker

struct APINextWorkoutResponse: Codable, Sendable {
    let planId: Int
    let planName: String
    let cycleLength: Int
    let nextDayNumber: Int
    let lastCompletedAt: String?
    let day: APIPlanDay

    enum CodingKeys: String, CodingKey {
        case day
        case planId = "plan_id"
        case planName = "plan_name"
        case cycleLength = "cycle_length"
        case nextDayNumber = "next_day_number"
        case lastCompletedAt = "last_completed_at"
    }
}

struct APICompleteWorkoutResponse: Codable, Sendable {
    let completedDayNumber: Int
    let nextDayNumber: Int
    let cycleLength: Int

    enum CodingKeys: String, CodingKey {
        case cycleLength = "cycle_length"
        case completedDayNumber = "completed_day_number"
        case nextDayNumber = "next_day_number"
    }
}

struct APIWorkoutSetUpdate: Codable, Sendable {
    let weight: Double?
    let reps: Int?
    let rpe: Double?
}

struct APIWorkoutSetUpdateResponse: Codable, Sendable {
    let id: Int
    let weight: Double?
    let reps: Int?
    let rpe: Double?
}

// MARK: - Health

struct APIHealthResponse: Codable, Sendable {
    let status: String
    let version: String
}
