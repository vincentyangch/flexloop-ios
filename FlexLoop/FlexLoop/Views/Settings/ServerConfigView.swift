import SwiftUI

struct ServerConfigView: View {
    @AppStorage("serverBaseURL") private var serverURL = "http://localhost:8000"
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        Form {
            Section("Server URL") {
                TextField("http://your-server:8000", text: $serverURL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Text("The URL of your self-hosted FlexLoop backend.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    Task { await testConnection() }
                } label: {
                    HStack {
                        Text("Test Connection")
                        Spacer()
                        if isTesting {
                            ProgressView()
                        } else if let result = testResult {
                            Image(systemName: result == "ok"
                                  ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result == "ok" ? .green : .red)
                        }
                    }
                }
                .disabled(isTesting)
            }

            if let result = testResult, result != "ok" {
                Section {
                    Text("Connection failed: \(result)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Server")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil

        let config = ServerConfig(baseURL: serverURL)
        let client = APIClient(config: config)

        do {
            let response: APIHealthResponse = try await client.checkHealth()
            testResult = response.status
            if response.status == "ok" {
                ServerConfig.save(baseURL: serverURL)
            }
        } catch {
            testResult = error.localizedDescription
        }

        isTesting = false
    }
}
