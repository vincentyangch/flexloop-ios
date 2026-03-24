import SwiftUI

@main
struct FlexLoopWatch_Watch_AppApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(sessionManager)
        }
    }
}
