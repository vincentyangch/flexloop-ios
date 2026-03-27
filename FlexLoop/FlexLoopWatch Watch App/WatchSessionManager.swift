import Combine
import Foundation
import HealthKit
import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published var workoutState: WorkoutSyncState?
    @Published var isConnected = false

    private var healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Send to iPhone

    func sendCompleteSet(exerciseIndex: Int, setNumber: Int,
                         weightKg: Double?, reps: Int?, rpe: Double?) {
        let action = WatchCompleteSetAction(
            exerciseIndex: exerciseIndex,
            setNumber: setNumber,
            weightKg: weightKg,
            reps: reps,
            rpe: rpe
        )
        let message = SyncMessageCoder.encode(.completeSet, payload: action)

        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            if let state = SyncMessageCoder.decodePayload(WorkoutSyncState.self, from: reply) {
                DispatchQueue.main.async {
                    self?.workoutState = state
                }
            }
        }, errorHandler: { error in
            print("sendCompleteSet error: \(error)")
        })
    }

    func requestState() {
        guard WCSession.default.isReachable else { return }
        let message = SyncMessageCoder.encode(.requestState)

        WCSession.default.sendMessage(message, replyHandler: { [weak self] reply in
            guard let type = SyncMessageCoder.decodeType(from: reply) else { return }
            if type == .stateUpdate,
               let state = SyncMessageCoder.decodePayload(WorkoutSyncState.self, from: reply) {
                DispatchQueue.main.async {
                    self?.workoutState = state
                }
            } else if type == .noActiveWorkout {
                DispatchQueue.main.async {
                    self?.workoutState = nil
                }
            }
        }, errorHandler: { error in
            print("requestState error: \(error)")
        })
    }

    // MARK: - HKWorkoutSession

    private func startWorkoutSession() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

            workoutSession?.startActivity(with: Date())
            try workoutBuilder?.beginCollection(withStart: Date()) { _, _ in }
        } catch {
            print("Failed to start workout session: \(error)")
        }
    }

    private func endWorkoutSession() {
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            self?.workoutBuilder?.finishWorkout { _, _ in }
        }
        workoutSession = nil
        workoutBuilder = nil
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }
        if !session.receivedApplicationContext.isEmpty {
            handleIncomingMessage(session.receivedApplicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handleIncomingMessage(message)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        handleIncomingMessage(applicationContext)
    }

    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let type = SyncMessageCoder.decodeType(from: message) else { return }

        switch type {
        case .workoutStarted, .stateUpdate:
            if let state = SyncMessageCoder.decodePayload(WorkoutSyncState.self, from: message) {
                DispatchQueue.main.async {
                    let wasInactive = self.workoutState == nil
                    self.workoutState = state
                    if wasInactive && state.isActive {
                        self.startWorkoutSession()
                    }
                }
            }
        case .workoutEnded:
            DispatchQueue.main.async {
                self.workoutState = nil
                self.endWorkoutSession()
            }
        default:
            break
        }
    }
}
