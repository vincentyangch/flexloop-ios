import SwiftUI

struct SettingsView: View {
    @AppStorage("unitSystem") private var unitSystem = "metric"
    @AppStorage("sessionFeedbackEnabled") private var sessionFeedbackEnabled = false
    @AppStorage("measurementReminders") private var measurementReminders = false

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "settings.server")) {
                    NavigationLink(String(localized: "settings.server")) {
                        ServerConfigView()
                    }
                }

                Section(String(localized: "settings.weightUnit")) {
                    Picker(String(localized: "settings.weightUnit"), selection: $unitSystem) {
                        Text(String(localized: "settings.metric")).tag("metric")
                        Text(String(localized: "settings.imperial")).tag("imperial")
                    }
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
