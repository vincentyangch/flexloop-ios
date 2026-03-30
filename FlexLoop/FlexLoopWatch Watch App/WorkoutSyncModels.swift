import Foundation

// MARK: - Workout Sync State (iPhone → Watch)

struct WorkoutSyncState: Codable {
    let isActive: Bool
    let currentExerciseIndex: Int
    let exercises: [SyncExercise]
    let restTimerRemaining: Int?
    let startedAt: Date
}

struct SyncExercise: Codable {
    let exerciseId: Int
    let name: String
    let isSkipped: Bool
    let restSeconds: Int
    let targets: [SyncSetTarget]
    let completedSets: [SyncCompletedSet]
}

struct SyncSetTarget: Codable {
    let setNumber: Int
    let weight: Double?
    let reps: Int
    let rpe: Double?
}

struct SyncCompletedSet: Codable {
    let setNumber: Int
    let weight: Double?
    let reps: Int?
    let rpe: Double?
}

// MARK: - Watch → iPhone Actions

struct WatchCompleteSetAction: Codable {
    let exerciseIndex: Int
    let setNumber: Int
    let weight: Double?
    let reps: Int?
    let rpe: Double?
}

// MARK: - Message Encoding Helpers

enum SyncMessageType: String {
    case workoutStarted
    case stateUpdate
    case workoutEnded
    case completeSet
    case requestState
    case noActiveWorkout
}

enum SyncMessageCoder {
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .secondsSince1970
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    static func encode<T: Encodable>(_ type: SyncMessageType, payload: T) -> [String: Any] {
        let data = (try? encoder.encode(payload)) ?? Data()
        return ["type": type.rawValue, "payload": data]
    }

    static func encode(_ type: SyncMessageType) -> [String: Any] {
        return ["type": type.rawValue]
    }

    static func decodeType(from message: [String: Any]) -> SyncMessageType? {
        guard let raw = message["type"] as? String else { return nil }
        return SyncMessageType(rawValue: raw)
    }

    static func decodePayload<T: Decodable>(_ type: T.Type, from message: [String: Any]) -> T? {
        guard let data = message["payload"] as? Data else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
