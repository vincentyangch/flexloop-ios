import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("sessionFeedbackEnabled") private var sessionFeedbackEnabled = false
    @AppStorage("measurementReminders") private var measurementReminders = false

    @Query private var users: [CachedUser]
    private var currentUser: CachedUser? { users.first }

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "settings.server")) {
                    NavigationLink(String(localized: "settings.server")) {
                        ServerConfigView()
                    }
                }

                Section(String(localized: "settings.weightUnit")) {
                    HStack {
                        Text(String(localized: "settings.weightUnit"))
                        Spacer()
                        Text(currentUser?.weightUnit.uppercased() ?? "KG")
                            .foregroundStyle(.secondary)
                    }
                    Text(String(localized: "settings.unitChangeHint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section(String(localized: "tab.workout")) {
                    Toggle(String(localized: "settings.sessionFeedback"), isOn: $sessionFeedbackEnabled)
                    Text(String(localized: "settings.sessionFeedbackDesc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Toggle(String(localized: "settings.measurementReminders"), isOn: $measurementReminders)
                    Text(String(localized: "settings.measurementRemindersDesc"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    HStack {
                        Text(String(localized: "settings.version"))
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(String(localized: "settings.title"))
        }
    }
}
