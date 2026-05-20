import Foundation

struct SharedPendingItem: Codable, Identifiable {
    let id: UUID
    var title: String
    var imageURL: String?
    var productURL: String
    var mall: Mall
    var createdAt: Date
}
