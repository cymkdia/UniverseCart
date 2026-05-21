import Foundation

struct ProfileRecord: Codable {
    let userId: UUID
    var displayName: String?
    var shareSlug: String?
    var shareEnabled: Bool
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case shareSlug = "share_slug"
        case shareEnabled = "share_enabled"
        case updatedAt = "updated_at"
    }
}
