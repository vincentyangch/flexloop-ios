import Combine
import Foundation
import WatchConnectivity

// MARK: - Shared data structures (used by both iPhone and Watch)

struct WatchExerciseData: Codable {
    let name: String
    let sets: Int
    let reps: Int
    let weight: Double?
    let rpeTarget: Double?
    let groupType: String
    let restSec: Int
}

struct WatchDayData: Codable {
    let dayNumber: Int
    let label: String
    let focus: String
    let exercises: [WatchExerciseData]
}

struct WatchPlanData: Codable {
    let planName: String
    let todayDay: WatchDayData?
    let allDays: [WatchDayData]
}

// MARK: - iPhone-side connectivity manager

class PhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneConnectivityManager()

    @Published var isWatchReachable = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendPlanToWatch(_ planData: WatchPlanData) {
        guard WCSession.default.activationState == .activated else { return }

        do {
            let data = try JSONEncoder().encode(planData)
            let context: [String: Any] = ["planData": data]

            // Use application context for guaranteed delivery (even if Watch app isn't running)
            try WCSession.default.updateApplicationContext(context)

            // Also try direct message if Watch is reachable for immediate update
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(context, replyHandler: nil)
            }
        } catch {
            print("Failed to send plan to Watch: \(error)")
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
