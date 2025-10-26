import Foundation

struct FavoriteRecord: Codable {
    let id: String?
    let userId: String
    let topicId: Int
    let topicTitle: String
    let topicUrl: String?
    let nodeName: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case topicId = "topic_id"
        case topicTitle = "topic_title"
        case topicUrl = "topic_url"
        case nodeName = "node_name"
        case createdAt = "created_at"
    }
}

struct ReadingHistoryRecord: Codable {
    let id: String?
    let userId: String
    let topicId: Int
    let topicTitle: String
    let lastReadAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case topicId = "topic_id"
        case topicTitle = "topic_title"
        case lastReadAt = "last_read_at"
    }
}

struct NodeSubscriptionRecord: Codable {
    let id: String?
    let userId: String
    let nodeId: Int
    let nodeName: String
    let nodeTitle: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case nodeId = "node_id"
        case nodeName = "node_name"
        case nodeTitle = "node_title"
        case createdAt = "created_at"
    }
}

struct UserPreferencesRecord: Codable {
    let id: String?
    let userId: String
    let themeMode: String
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case themeMode = "theme_mode"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

class SupabaseService {
    private let supabaseURL = "https://paaqlqlmaggdobiaxorx.supabase.co"
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBhYXFscWxtYWdnZG9iaWF4b3J4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE0NTMwNDQsImV4cCI6MjA3NzAyOTA0NH0.SeXjQ_P-mWhT1hN2BXriYXsc19iTNRAOH0LMpuDBjcw"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    private func createRequest(path: String, method: String = "GET", body: Data? = nil) throws -> URLRequest {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        if let body = body {
            request.httpBody = body
        }

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("Status code: \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func addFavorite(userId: String, topic: Topic) async throws {
        let favorite = FavoriteRecord(
            id: nil,
            userId: userId,
            topicId: topic.id,
            topicTitle: topic.title,
            topicUrl: topic.url,
            nodeName: topic.node?.name,
            createdAt: nil
        )

        let body = try JSONEncoder().encode(favorite)
        let request = try createRequest(path: "favorites", method: "POST", body: body)
        let _: [FavoriteRecord] = try await performRequest(request)
    }

    func removeFavorite(userId: String, topicId: Int) async throws {
        let path = "favorites?user_id=eq.\(userId)&topic_id=eq.\(topicId)"
        let request = try createRequest(path: path, method: "DELETE")
        let (_, _) = try await session.data(for: request)
    }

    func getFavorites(userId: String) async throws -> [FavoriteRecord] {
        let path = "favorites?user_id=eq.\(userId)&order=created_at.desc"
        let request = try createRequest(path: path)
        return try await performRequest(request)
    }

    func isFavorite(userId: String, topicId: Int) async throws -> Bool {
        let path = "favorites?user_id=eq.\(userId)&topic_id=eq.\(topicId)&select=id"
        let request = try createRequest(path: path)
        let result: [FavoriteRecord] = try await performRequest(request)
        return !result.isEmpty
    }

    func addToReadingHistory(userId: String, topic: Topic) async throws {
        let history = ReadingHistoryRecord(
            id: nil,
            userId: userId,
            topicId: topic.id,
            topicTitle: topic.title,
            lastReadAt: nil
        )

        let body = try JSONEncoder().encode(history)
        let request = try createRequest(path: "reading_history", method: "POST", body: body)
        let _: [ReadingHistoryRecord] = try await performRequest(request)
    }

    func getReadingHistory(userId: String, limit: Int = 50) async throws -> [ReadingHistoryRecord] {
        let path = "reading_history?user_id=eq.\(userId)&order=last_read_at.desc&limit=\(limit)"
        let request = try createRequest(path: path)
        return try await performRequest(request)
    }

    func subscribeToNode(userId: String, node: Node) async throws {
        let subscription = NodeSubscriptionRecord(
            id: nil,
            userId: userId,
            nodeId: node.id,
            nodeName: node.name,
            nodeTitle: node.title,
            createdAt: nil
        )

        let body = try JSONEncoder().encode(subscription)
        let request = try createRequest(path: "node_subscriptions", method: "POST", body: body)
        let _: [NodeSubscriptionRecord] = try await performRequest(request)
    }

    func unsubscribeFromNode(userId: String, nodeId: Int) async throws {
        let path = "node_subscriptions?user_id=eq.\(userId)&node_id=eq.\(nodeId)"
        let request = try createRequest(path: path, method: "DELETE")
        let (_, _) = try await session.data(for: request)
    }

    func getNodeSubscriptions(userId: String) async throws -> [NodeSubscriptionRecord] {
        let path = "node_subscriptions?user_id=eq.\(userId)&order=created_at.desc"
        let request = try createRequest(path: path)
        return try await performRequest(request)
    }

    func saveUserPreferences(userId: String, themeMode: String) async throws {
        let preferences = UserPreferencesRecord(
            id: nil,
            userId: userId,
            themeMode: themeMode,
            createdAt: nil,
            updatedAt: nil
        )

        let body = try JSONEncoder().encode(preferences)
        let request = try createRequest(path: "user_preferences", method: "POST", body: body)
        let _: [UserPreferencesRecord] = try await performRequest(request)
    }

    func getUserPreferences(userId: String) async throws -> UserPreferencesRecord? {
        let path = "user_preferences?user_id=eq.\(userId)"
        let request = try createRequest(path: path)
        let result: [UserPreferencesRecord] = try await performRequest(request)
        return result.first
    }
}
