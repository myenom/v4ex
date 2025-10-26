import Foundation

struct Member: Codable, Identifiable {
    let id: Int
    let username: String
    let bio: String?
    let website: String?
    let github: String?
    let twitter: String?
    let location: String?
    let avatar: String?
    let created: Int

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case bio
        case website
        case github
        case twitter
        case location
        case avatar = "avatar_large"
        case created
    }
}

struct Node: Codable, Identifiable {
    let id: Int
    let name: String
    let title: String
    let url: String?
    let topics: Int?
    let header: String?
    let footer: String?
    let avatar: String?
    let avatarLarge: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case title
        case url
        case topics
        case header
        case footer
        case avatar
        case avatarLarge = "avatar_large"
    }
}

struct Topic: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String?
    let contentRendered: String?
    let url: String
    let member: Member?
    let node: Node?
    let created: Int
    let lastModified: Int?
    let lastReplyTime: Int?
    let replies: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case contentRendered = "content_rendered"
        case url
        case member
        case node
        case created
        case lastModified = "last_modified"
        case lastReplyTime = "last_reply_time"
        case replies
    }
}

struct Reply: Codable, Identifiable {
    let id: Int
    let content: String
    let contentRendered: String?
    let member: Member?
    let created: Int
    let lastModified: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case contentRendered = "content_rendered"
        case member
        case created
        case lastModified = "last_modified"
    }
}

struct Notification: Codable, Identifiable {
    let id: Int
    let member: Member?
    let text: String
    let created: Int
    let forObject: String?
    let payload: String?

    enum CodingKeys: String, CodingKey {
        case id
        case member
        case text
        case created
        case forObject = "for_object"
        case payload
    }
}

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let result: T?
    let message: String?
}

struct TopicsResponse: Codable {
    let topics: [Topic]?
}

struct RepliesResponse: Codable {
    let replies: [Reply]?
}

struct NotificationsResponse: Codable {
    let notifications: [Notification]?
}
