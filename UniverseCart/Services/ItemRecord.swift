import Foundation

struct ItemRecord: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let imageUrl: String?
    let price: Int?
    let productUrl: String
    let mall: String
    let category: String
    let listType: String
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case imageUrl = "image_url"
        case price
        case productUrl = "product_url"
        case mall
        case category
        case listType = "list_type"
        case updatedAt = "updated_at"
    }

    func toItem() -> Item? {
        guard let mall = Mall(rawValue: mall),
              let category = Category(rawValue: category),
              let listType = ListType(rawValue: listType)
        else {
            return nil
        }

        return Item(
            id: id,
            title: title,
            imageURL: imageUrl,
            price: price,
            productURL: productUrl,
            mall: mall,
            category: category,
            listType: listType
        )
    }

    static func from(item: Item, userId: UUID) -> ItemRecord {
        ItemRecord(
            id: item.id,
            userId: userId,
            title: item.title,
            imageUrl: item.imageURL,
            price: item.price,
            productUrl: item.productURL,
            mall: item.mall.rawValue,
            category: item.category.rawValue,
            listType: item.listType.rawValue,
            updatedAt: Date()
        )
    }
}
