import Foundation

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimitExceeded
    case decodingError
    case networkError(Error)
    case serverError(String)
}

class V2EXAPIService {
    private let baseURL = "https://www.v2ex.com/api/v2"
    private let session: URLSession
    private var token: String?

    init(token: String? = nil) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.token = token
    }

    func setToken(_ token: String) {
        self.token = token
    }

    private func createRequest(endpoint: String, method: String = "GET") throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        return request
    }

    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError
                }
            case 401:
                throw APIError.unauthorized
            case 429:
                throw APIError.rateLimitExceeded
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.serverError(message)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    func fetchMember() async throws -> Member {
        let request = try createRequest(endpoint: "member")
        let response: APIResponse<Member> = try await performRequest(request)
        guard let member = response.result else {
            throw APIError.invalidResponse
        }
        return member
    }

    func fetchNode(name: String) async throws -> Node {
        let request = try createRequest(endpoint: "nodes/\(name)")
        return try await performRequest(request)
    }

    func fetchNodeTopics(name: String, page: Int = 1) async throws -> [Topic] {
        let request = try createRequest(endpoint: "nodes/\(name)/topics?p=\(page)")
        let response: TopicsResponse = try await performRequest(request)
        return response.topics ?? []
    }

    func fetchTopic(id: Int) async throws -> Topic {
        let request = try createRequest(endpoint: "topics/\(id)")
        return try await performRequest(request)
    }

    func fetchTopicReplies(id: Int, page: Int = 1) async throws -> [Reply] {
        let request = try createRequest(endpoint: "topics/\(id)/replies?p=\(page)")
        let response: RepliesResponse = try await performRequest(request)
        return response.replies ?? []
    }

    func fetchNotifications() async throws -> [Notification] {
        let request = try createRequest(endpoint: "notifications")
        let response: NotificationsResponse = try await performRequest(request)
        return response.notifications ?? []
    }

    func deleteNotification(id: Int) async throws {
        let request = try createRequest(endpoint: "notifications/\(id)", method: "DELETE")
        let _: APIResponse<String> = try await performRequest(request)
    }

    func fetchLatestTopics() async throws -> [Topic] {
        guard let url = URL(string: "https://www.v2ex.com/api/topics/latest.json") else {
            throw APIError.invalidURL
        }
        let request = URLRequest(url: url)
        return try await performRequest(request)
    }

    func fetchHotTopics() async throws -> [Topic] {
        guard let url = URL(string: "https://www.v2ex.com/api/topics/hot.json") else {
            throw APIError.invalidURL
        }
        let request = URLRequest(url: url)
        return try await performRequest(request)
    }

    func fetchAllNodes() async throws -> [Node] {
        guard let url = URL(string: "https://www.v2ex.com/api/nodes/all.json") else {
            throw APIError.invalidURL
        }
        let request = URLRequest(url: url)
        return try await performRequest(request)
    }
}
