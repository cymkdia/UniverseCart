import Foundation

enum ItemUpsert {
    static func index(matching productURL: String, in items: [Item]) -> Int? {
        items.firstIndex { ProductURLNormalizer.isSameProduct($0.productURL, productURL) }
    }

    /// 새로 추가하거나 같은 URL이면 기존 항목을 갱신합니다. 기존 `id`는 유지합니다.
    @discardableResult
    static func apply(_ incoming: Item, to items: inout [Item], moveUpdatedToTop: Bool = true) -> UUID {
        var normalized = incoming
        if let canonical = ProductURLNormalizer.canonicalString(from: incoming.productURL) {
            normalized.productURL = canonical
        }

        if let existingIndex = index(matching: normalized.productURL, in: items) {
            let existingID = items[existingIndex].id
            var merged = merge(existing: items[existingIndex], incoming: normalized)
            merged.id = existingID

            items.remove(at: existingIndex)
            if moveUpdatedToTop {
                items.insert(merged, at: 0)
            } else {
                items.insert(merged, at: existingIndex)
            }
            return existingID
        }

        items.insert(normalized, at: 0)
        return normalized.id
    }

    static func merge(existing: Item, incoming: Item) -> Item {
        var merged = existing

        if let canonical = ProductURLNormalizer.canonicalString(from: incoming.productURL) {
            merged.productURL = canonical
        }

        let title = incoming.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty, title != "공유 상품" {
            merged.title = title
        }

        if let imageURL = incoming.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
           !imageURL.isEmpty {
            merged.imageURL = imageURL
        }

        if let price = incoming.price {
            merged.price = price
        }

        merged.mall = incoming.mall
        merged.category = incoming.category
        merged.listType = incoming.listType
        return merged
    }
}
