import Foundation

struct ServerConfig: Sendable {
    let baseURL: String

    @MainActor
    static var current: ServerConfig {
        let url = UserDefaults.standard.string(forKey: "serverBaseURL") ?? "http://localhost:8000"
        return ServerConfig(baseURL: url)
    }

    @MainActor
    static func save(baseURL: String) {
        UserDefaults.standard.set(baseURL, forKey: "serverBaseURL")
    }
}
