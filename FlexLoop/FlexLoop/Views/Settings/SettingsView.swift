import SwiftUI

struct SettingsView: View {
    @AppStorage("unitSystem") private var unitSystem = "metric"
    @AppStorage("sessionFeedbackEnabled") private var sessionFeedbackEnabled = false
    @AppStorage("measurementReminders") private var measurementReminders = false

    var body: some View {
        NavigationStack {
            List {
                Section("Server") {
                    NavigationLink("Backend Server") {
                        ServerConfigView()
                    }
                }

                Section("Units") {
                    Picker("Weight Unit", selection: $unitSystem) {
                        Text("Metric (kg)").tag("metric")
                        Text("Imperial (lbs)").tag("imperial")
                    }
                }

                Section("Workout") {
                    Toggle("Post-session feedback", isOn: $sessionFeedbackEnabled)
                    Text("When enabled, you'll be prompted to rate sleep, energy, and soreness after each workout.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Tracking") {
                    Toggle("Measurement reminders", isOn: $measurementReminders)
                    Text("Reminds you to take body measurements every 2-4 weeks.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
