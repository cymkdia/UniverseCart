import Foundation

enum FundingNotificationKind: String, Codable {
    case goalReached = "goal_reached"
    case buyerAssigned = "buyer_assigned"
    case purchased
    case received
}

struct FundingNotificationRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let userId: UUID
    let itemId: UUID
    let kind: FundingNotificationKind
    let title: String
    let body: String
    let readAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case itemId = "item_id"
        case kind
        case title
        case body
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    var isUnread: Bool { readAt == nil }
}

struct FundingNotificationInsert: Encodable {
    let userId: UUID
    let itemId: UUID
    let kind: FundingNotificationKind
    let title: String
    let body: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case itemId = "item_id"
        case kind
        case title
        case body
    }
}
