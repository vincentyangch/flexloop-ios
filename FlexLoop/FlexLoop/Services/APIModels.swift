import Foundation

// MARK: - User / Profile

struct APIUser: Codable, Sendable {
    let id: Int
    let name: String
    let gender: String
    let age: Int
    let heightCm: Double
    let weightKg: Double
    let experienceLevel: String
    let goals: String
    let availableEquipment: [String]
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, gender, age, goals
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case experienceLevel = "experience_level"
        case availableEquipment = "available_equipment"
        case createdAt = "created_at"
    }
}

struct APIUserCreate: Codable, Sendable {
    let name: String
    let gender: String
    let age: Int
    let heightCm: Double
    let weightKg: Double
    let experienceLevel: String
    let goals: String
    let availableEquipment: [String]

    enum CodingKeys: String, CodingKey {
        case name, gender, age, goals
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
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
    let templateId: Int?
    let source: String
    let startedAt: String
    let completedAt: String?
    let notes: String?
    let sets: [APIWorkoutSet]

    enum CodingKeys: String, CodingKey {
        case id, source, notes, sets
        case userId = "user_id"
        case planDayId = "plan_day_id"
        case templateId = "template_id"
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
    let templateId: Int?
    let source: String
    let startedAt: String
    let completedAt: String?
    let notes: String?
    let sets: [APISyncSet]

    enum CodingKeys: String, CodingKey {
        case source, notes, sets
        case planDayId = "plan_day_id"
        case templateId = "template_id"
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

struct APIPlanExercise: Codable, Sendable {
    let exerciseId: Int
    let sets: Int
    let reps: Int
    let weight: Double?
    let rpeTarget: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case sets, reps, weight, notes
        case exerciseId = "exercise_id"
        case rpeTarget = "rpe_target"
    }
}

struct APIPlanExerciseGroup: Codable, Sendable {
    let groupType: String
    let restAfterGroupSec: Int
    let exercises: [APIPlanExercise]

    enum CodingKeys: String, CodingKey {
        case exercises
        case groupType = "group_type"
        case restAfterGroupSec = "rest_after_group_sec"
    }
}

struct APIPlanDay: Codable, Sendable {
    let dayNumber: Int
    let label: String
    let focus: String
    let exerciseGroups: [APIPlanExerciseGroup]

    enum CodingKeys: String, CodingKey {
        case label, focus
        case dayNumber = "day_number"
        case exerciseGroups = "exercise_groups"
    }
}

struct APIPlanGenerateResponse: Codable, Sendable {
    let status: String
    let planId: Int?
    let planName: String?
    let splitType: String?
    let blockStart: String?
    let blockEnd: String?
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
        case blockStart = "block_start"
        case blockEnd = "block_end"
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case rawResponse = "raw_response"
    }
}

// MARK: - Health

struct APIHealthResponse: Codable, Sendable {
    let status: String
    let version: String
}
