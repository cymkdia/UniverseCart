import Foundation

enum FundingCoordinationState: String, Codable, CaseIterable {
    case collecting
    case goalReached = "goal_reached"
    case buyerAssigned = "buyer_assigned"
    case purchased
    case received

    var displayTitle: String {
        switch self {
        case .collecting: return "모으는 중"
        case .goalReached: return "목표 달성"
        case .buyerAssigned: return "정산 중"
        case .purchased: return "구매 완료"
        case .received: return "선물 받음"
        }
    }

    var statusMessage: String {
        switch self {
        case .collecting:
            return "친구들의 약속을 모으고 있어요."
        case .goalReached:
            return "약속 금액이 모였어요. 대표 구매자를 정해 주세요."
        case .buyerAssigned:
            return "참여자들이 대표에게 송금한 뒤, 대표가 구매해 주세요."
        case .purchased:
            return "대표가 구매를 완료했어요. 선물을 받으면 확인해 주세요."
        case .received:
            return "선물을 받았어요. 받은 선물 아카이브에 보관됩니다."
        }
    }
}

struct FundingCoordinationRecord: Codable, Equatable {
    let itemId: UUID
    let ownerUserId: UUID
    var state: FundingCoordinationState
    var buyerUserId: UUID?
    var goalReachedAt: Date?
    var purchasedAt: Date?
    var receivedAt: Date?
    var thankYouMessage: String?
    var settlementBankName: String?
    var settlementBankCode: String?
    var settlementAccountNumber: String?
    var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case ownerUserId = "owner_user_id"
        case state
        case buyerUserId = "buyer_user_id"
        case goalReachedAt = "goal_reached_at"
        case purchasedAt = "purchased_at"
        case receivedAt = "received_at"
        case thankYouMessage = "thank_you_message"
        case settlementBankName = "settlement_bank_name"
        case settlementBankCode = "settlement_bank_code"
        case settlementAccountNumber = "settlement_account_number"
        case updatedAt = "updated_at"
    }

    var hasSettlementAccount: Bool {
        guard let settlementAccountNumber, !settlementAccountNumber.isEmpty,
              let settlementBankName, !settlementBankName.isEmpty
        else {
            return false
        }
        return true
    }
}

struct FundingCoordinationContext: Equatable {
    let record: FundingCoordinationRecord?
    let summary: FundingPledgeSummary
    let itemPrice: Int?

    var effectiveState: FundingCoordinationState {
        if record?.state == .received { return .received }
        if record?.state == .purchased { return .purchased }
        if record?.state == .buyerAssigned { return .buyerAssigned }
        if record?.state == .goalReached { return .goalReached }

        guard let itemPrice, itemPrice > 0 else { return .collecting }
        if summary.totalAmount >= itemPrice { return .goalReached }
        return .collecting
    }

    var isGoalMet: Bool {
        guard let itemPrice, itemPrice > 0 else { return false }
        return summary.totalAmount >= itemPrice
    }

    var progress: Double? {
        summary.progress(for: itemPrice)
    }
}
