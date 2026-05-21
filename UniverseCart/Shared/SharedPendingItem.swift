import Foundation

struct SharedPendingItem: Codable, Identifiable {
    let id: UUID
    var title: String
    var imageURL: String?
    var price: Int?
    var priceManual: Bool
    var productURL: String
    var mall: Mall
    var listType: ListType
    var category: Category
    var createdAt: Date

    init(
        id: UUID,
        title: String,
        imageURL: String?,
        price: Int? = nil,
        priceManual: Bool = false,
        productURL: String,
        mall: Mall,
        listType: ListType = .wishlist,
        category: Category = .fashion,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.price = price
        self.priceManual = priceManual
        self.productURL = productURL
        self.mall = mall
        self.listType = listType
        self.category = category
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        price = try container.decodeIfPresent(Int.self, forKey: .price)
        priceManual = try container.decodeIfPresent(Bool.self, forKey: .priceManual) ?? false
        productURL = try container.decode(String.self, forKey: .productURL)
        mall = try container.decode(Mall.self, forKey: .mall)
        listType = try container.decodeIfPresent(ListType.self, forKey: .listType) ?? .wishlist
        category = try container.decodeIfPresent(Category.self, forKey: .category) ?? .fashion
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
