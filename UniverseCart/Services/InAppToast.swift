import Foundation

struct InAppToast: Equatable {
    let title: String
    let subtitle: String?
    let style: InAppNotificationBannerStyle

    init(
        title: String,
        subtitle: String? = nil,
        style: InAppNotificationBannerStyle = .surface
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }
}

enum FundingNotificationDisplay {
    static func toast(for record: FundingNotificationRecord) -> InAppToast {
        switch record.kind {
        case .goalReached:
            return InAppToast(
                title: "100% 달성!",
                subtitle: "이제 누가 대표로 살지 정해주세요",
                style: .funding
            )
        case .buyerAssigned:
            return InAppToast(
                title: "대표가 정해졌어요",
                subtitle: "정산 안내에서 송금 금액을 확인해 주세요",
                style: .surface
            )
        case .purchased:
            return InAppToast(
                title: "구매가 완료됐어요",
                subtitle: "선물이 도착하면 확인해 주세요",
                style: .surface
            )
        case .received:
            return InAppToast(
                title: "선물이 도착했어요",
                subtitle: "함께해준 친구들에게 감사 인사를 남겨보세요",
                style: .funding
            )
        }
    }
}
