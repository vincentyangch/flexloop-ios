import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Query private var users: [CachedUser]

    var body: some View {
        Group {
            if users.isEmpty {
                OnboardingView()
            } else {
                mainTabView
            }
        }
    }

    private var mainTabView: some View {
        TabView {
            HomeView()
                .tabItem { Label(String(localized: "tab.home"), systemImage: "house") }
            ActiveWorkoutView()
                .tabItem { Label(String(localized: "tab.workout"), systemImage: "figure.strengthtraining.traditional") }
            PlanView()
                .tabItem { Label(String(localized: "tab.plan"), systemImage: "calendar") }
            ProgressTabView()
                .tabItem { Label(String(localized: "tab.progress"), systemImage: "chart.line.uptrend.xyaxis") }
            AIChatView()
                .tabItem { Label(String(localized: "tab.aiCoach"), systemImage: "brain") }
            SettingsView()
                .tabItem { Label(String(localized: "tab.settings"), systemImage: "gear") }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await syncIfNeeded() }
            }
        }
    }

    private func syncIfNeeded() async {
        guard let user = users.first else { return }
        let apiClient = APIClient(config: .current)
        do {
            let synced = try await SyncService.performSync(
                apiClient: apiClient, context: context, userId: user.serverId
            )
            if synced > 0 {
                print("Synced \(synced) workout(s) to server")
            }
        } catch {
            print("Sync failed: \(error.localizedDescription)")
        }
    }
}
