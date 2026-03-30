import Combine
import Foundation
import WatchConnectivity

class PhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneConnectivityManager()

    @Published var isWatchReachable = false

    /// Reference to the active workout ViewModel for handling Watch actions.
    /// Set by GuidedWorkoutView on appear, cleared on disappear.
    weak var activeWorkoutViewModel: GuidedWorkoutViewModel?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Send to Watch

    func sendWorkoutStarted(_ state: WorkoutSyncState) {
        let message = SyncMessageCoder.encode(.workoutStarted, payload: state)
        sendAndSetContext(message)
    }

    func sendStateUpdate(_ state: WorkoutSyncState) {
        guard WCSession.default.isReachable else { return }
        let message = SyncMessageCoder.encode(.stateUpdate, payload: state)
        WCSession.default.sendMessage(message, replyHandler: nil)
    }

    func sendWorkoutEnded(reason: String) {
        struct EndPayload: Codable { let reason: String }
        let message = SyncMessageCoder.encode(.workoutEnded, payload: EndPayload(reason: reason))
        sendAndSetContext(message)
    }

    private func sendAndSetContext(_ message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
        try? WCSession.default.updateApplicationContext(message)
    }

    // MARK: - Handle Watch Messages

    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        guard let type = SyncMessageCoder.decodeType(from: message) else {
            replyHandler(SyncMessageCoder.encode(.noActiveWorkout))
            return
        }

        switch type {
        case .completeSet:
            handleCompleteSet(message: message, replyHandler: replyHandler)
        case .requestState:
            handleRequestState(replyHandler: replyHandler)
        default:
            replyHandler(SyncMessageCoder.encode(.noActiveWorkout))
        }
    }

    private func handleCompleteSet(message: [String: Any],
                                   replyHandler: @escaping ([String: Any]) -> Void) {
        guard let action = SyncMessageCoder.decodePayload(WatchCompleteSetAction.self, from: message) else {
            print("[WatchSync] Failed to decode completeSet action")
            handleRequestState(replyHandler: replyHandler)
            return
        }
        guard let vm = activeWorkoutViewModel else {
            print("[WatchSync] activeWorkoutViewModel is nil — cannot process completeSet")
            handleRequestState(replyHandler: replyHandler)
            return
        }
        print("[WatchSync] completeSet: exercise=\(action.exerciseIndex) set=\(action.setNumber) weight=\(action.weight ?? 0) reps=\(action.reps ?? 0) rpe=\(action.rpe ?? 0)")

        DispatchQueue.main.async {
            vm.completeSet(
                exerciseIndex: action.exerciseIndex,
                setNumber: action.setNumber,
                weight: action.weight,
                reps: action.reps,
                rpe: action.rpe
            )
            let state = vm.stateSnapshot()
            replyHandler(SyncMessageCoder.encode(.stateUpdate, payload: state))
        }
    }

    private func handleRequestState(replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            if let vm = self.activeWorkoutViewModel, vm.isWorkoutActive {
                let state = vm.stateSnapshot()
                replyHandler(SyncMessageCoder.encode(.stateUpdate, payload: state))
            } else {
                replyHandler(SyncMessageCoder.encode(.noActiveWorkout))
            }
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }
}
