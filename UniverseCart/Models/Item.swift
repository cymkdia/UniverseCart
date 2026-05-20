import Foundation

enum Mall: String, CaseIterable, Codable {
    case cm29, musinsa, wconcept, naver, etc

    var displayName: String {
        switch self {
        case .cm29: return "29CM"
        case .musinsa: return "무신사"
        case .wconcept: return "W컨셉"
        case .naver: return "네이버"
        case .etc: return "기타"
        }
    }

    /// Assets.xcassets 이미지셋 이름 (PNG 파일명과 동일)
    var logoAssetName: String? {
        switch self {
        case .cm29: return "mall_29cm"
        case .musinsa: return "mall_musinsa"
        case .wconcept: return "mall_wconcept"
        case .naver: return "mall_naver"
        case .etc: return nil
        }
    }
}

enum Category: String, CaseIterable, Codable {
    case fashion, home, food, beauty

    var displayName: String {
        switch self {
        case .fashion: return "패션"
        case .home: return "홈리빙"
        case .food: return "식품"
        case .beauty: return "뷰티"
        }
    }
}

enum ListType: String, CaseIterable, Codable {
    case wishlist, cart

    var displayName: String {
        switch self {
        case .wishlist: return "위시리스트"
        case .cart: return "내 장바구니"
        }
    }
}

struct Item: Identifiable, Codable {
    let id: UUID
    var title: String
    var imageURL: String?
    var price: Int?
    var productURL: String
    var mall: Mall
    var category: Category
    var listType: ListType
}
