import Foundation

enum DummyItems {
    static let sample: [Item] = [
        Item(
            id: UUID(),
            title: "29CM 미니 숄더백",
            imageURL: nil,
            price: 89000,
            productURL: "https://www.29cm.co.kr",
            mall: .cm29,
            category: .fashion,
            listType: .wishlist
        ),
        Item(
            id: UUID(),
            title: "무신사 와이드 데님 팬츠",
            imageURL: nil,
            price: 59000,
            productURL: "https://www.musinsa.com",
            mall: .musinsa,
            category: .fashion,
            listType: .cart
        ),
        Item(
            id: UUID(),
            title: "W컨셉 세라믹 디너 플레이트",
            imageURL: nil,
            price: 42000,
            productURL: "https://www.wconcept.co.kr",
            mall: .wconcept,
            category: .home,
            listType: .wishlist
        ),
        Item(
            id: UUID(),
            title: "네이버 스마트스토어 한우 선물세트",
            imageURL: nil,
            price: 129000,
            productURL: "https://smartstore.naver.com",
            mall: .naver,
            category: .food,
            listType: .cart
        ),
        Item(
            id: UUID(),
            title: "무신사 스킨 밸런싱 토너",
            imageURL: nil,
            price: nil,
            productURL: "https://www.musinsa.com",
            mall: .musinsa,
            category: .beauty,
            listType: .wishlist
        ),
        Item(
            id: UUID(),
            title: "29CM 패브릭 수납 바스켓",
            imageURL: nil,
            price: 27000,
            productURL: "https://www.29cm.co.kr",
            mall: .cm29,
            category: .home,
            listType: .cart
        )
    ]
}
