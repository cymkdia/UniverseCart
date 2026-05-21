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

enum Category: String, Codable, CaseIterable {
    case fashion, beauty, home, appliance, food, sports

    static var allCases: [Category] {
        [.fashion, .beauty, .home, .appliance, .food, .sports]
    }

    var displayName: String {
        switch self {
        case .fashion: return "패션"
        case .beauty: return "뷰티"
        case .home: return "홈리빙"
        case .appliance: return "가전"
        case .food: return "식품"
        case .sports: return "스포츠"
        }
    }

    /// 메인·공유 카테고리 바 칸 너비 (3글자 라벨은 2글자와 비슷한 비율)
    var barLayoutWeight: CGFloat {
        switch self {
        case .home, .sports: return 2.1
        default: return 2
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

struct Item: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var imageURL: String?
    var price: Int?
    var productURL: String
    var mall: Mall
    var category: Category
    var listType: ListType

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Mall {
    var storefrontURL: String {
        switch self {
        case .cm29: return "https://www.29cm.co.kr"
        case .musinsa: return "https://www.musinsa.com"
        case .wconcept: return "https://www.wconcept.co.kr"
        case .naver: return "https://shopping.naver.com"
        case .etc: return "https://www.google.com"
        }
    }
}
