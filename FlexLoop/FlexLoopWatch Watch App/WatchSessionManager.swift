import Combine
import Foundation
import WatchConnectivity

// MARK: - Shared data structures (mirrored from iPhone)

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

// MARK: - Watch-side connectivity manager

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published var todayPlan: WatchDayData?
    @Published var planName: String = ""
    @Published var isConnected = false

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    private func processPlanData(from dict: [String: Any]) {
        guard let data = dict["planData"] as? Data else { return }

        do {
            let plan = try JSONDecoder().decode(WatchPlanData.self, from: data)
            DispatchQueue.main.async {
                self.planName = plan.planName
                self.todayPlan = plan.todayDay
            }
        } catch {
            print("Failed to decode plan data: \(error)")
        }
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
        }

        // Check for any existing application context
        if !session.receivedApplicationContext.isEmpty {
            processPlanData(from: session.receivedApplicationContext)
        }
    }

    // Receive application context (guaranteed delivery)
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        processPlanData(from: applicationContext)
    }

    // Receive direct message (immediate, if reachable)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        processPlanData(from: message)
    }
}
