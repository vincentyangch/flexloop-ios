import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int, body: String)
    case decodingFailed(Error)
    case networkUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .requestFailed(let code, let body):
            return "Request failed (\(code)): \(body)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkUnavailable:
            return "Network unavailable"
        }
    }
}

actor APIClient {
    let config: ServerConfig
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(config: ServerConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    func buildURL(path: String, queryItems: [URLQueryItem]? = nil) -> URL? {
        var components = URLComponents(string: config.baseURL + path)
        if let queryItems, !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        return components?.url
    }

    // MARK: - Generic request methods

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        guard let url = buildURL(path: path, queryItems: queryItems) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    func post<Body: Encodable, Response: Decodable>(
        _ path: String, body: Body
    ) async throws -> Response {
        guard let url = buildURL(path: path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    func put<Body: Encodable, Response: Decodable>(
        _ path: String, body: Body
    ) async throws -> Response {
        guard let url = buildURL(path: path) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    // MARK: - Convenience methods

    func fetchExercises(muscleGroup: String? = nil, equipment: String? = nil,
                        query: String? = nil) async throws -> APIExerciseList {
        var queryItems: [URLQueryItem] = []
        if let muscleGroup { queryItems.append(.init(name: "muscle_group", value: muscleGroup)) }
        if let equipment { queryItems.append(.init(name: "equipment", value: equipment)) }
        if let query { queryItems.append(.init(name: "q", value: query)) }
        return try await get("/api/exercises", queryItems: queryItems)
    }

    func fetchUserWorkouts(userId: Int) async throws -> [APIWorkoutSession] {
        try await get("/api/users/\(userId)/workouts")
    }

    func syncWorkouts(request: APISyncRequest) async throws -> APISyncResponse {
        try await post("/api/sync", body: request)
    }

    func sendChatMessage(request: AIChatRequest) async throws -> AIChatResponse {
        try await post("/api/ai/chat", body: request)
    }

    // MARK: - Plans

    func fetchPlans(userId: Int, status: String? = nil) async throws -> APIPlanListResponse {
        var queryItems: [URLQueryItem] = [.init(name: "user_id", value: "\(userId)")]
        if let status { queryItems.append(.init(name: "status", value: status)) }
        return try await get("/api/plans", queryItems: queryItems)
    }

    func fetchPlan(id: Int) async throws -> APIPlanResponse {
        try await get("/api/plans/\(id)")
    }

    func createPlan(data: APIPlanCreate) async throws -> APIPlanResponse {
        try await post("/api/plans", body: data)
    }

    func updatePlan(id: Int, data: APIPlanUpdate) async throws -> APIPlanResponse {
        try await put("/api/plans/\(id)", body: data)
    }

    func activatePlan(id: Int) async throws -> APIPlanResponse {
        try await put("/api/plans/\(id)/activate", body: EmptyBody())
    }

    func archivePlan(id: Int) async throws -> APIPlanResponse {
        try await put("/api/plans/\(id)/archive", body: EmptyBody())
    }

    func deletePlan(id: Int) async throws {
        guard let url = buildURL(path: "/api/plans/\(id)") else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (_, response) = try await session.data(for: request)
        try validateResponse(response, data: Data())
    }

    func generatePlan(userId: Int) async throws -> APIPlanGenerateResponse {
        try await post("/api/ai/plan/generate", body: APIPlanGenerateRequest(userId: userId))
    }

    // MARK: - Cycle Tracker

    func fetchNextWorkout(userId: Int) async throws -> APINextWorkoutResponse {
        try await get("/api/users/\(userId)/next-workout")
    }

    func completeWorkout(userId: Int) async throws -> APICompleteWorkoutResponse {
        try await post("/api/users/\(userId)/complete-workout", body: EmptyBody())
    }

    // MARK: - Set Editing

    func updateWorkoutSet(workoutId: Int, setId: Int, data: APIWorkoutSetUpdate) async throws -> APIWorkoutSetUpdateResponse {
        try await put("/api/workouts/\(workoutId)/sets/\(setId)", body: data)
    }

    // MARK: - Health

    func checkHealth() async throws -> APIHealthResponse {
        try await get("/api/health")
    }

    // MARK: - Helpers

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw APIError.requestFailed(statusCode: http.statusCode, body: body)
        }
    }
}

struct EmptyBody: Codable, Sendable {}
