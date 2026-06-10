import Foundation

struct FundingPledgeRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let itemId: UUID
    let contributorUserId: UUID
    let amount: Int
    let message: String?
    let contributorName: String?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case contributorUserId = "contributor_user_id"
        case amount
        case message
        case contributorName = "contributor_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var displayContributorName: String {
        if let contributorName, !contributorName.isEmpty {
            return contributorName
        }
        return "친구"
    }
}

struct FundingPledgeSummary: Equatable {
    let pledges: [FundingPledgeRecord]

    var totalAmount: Int {
        pledges.reduce(0) { $0 + $1.amount }
    }

    var participantCount: Int {
        pledges.count
    }

    func progress(for price: Int?) -> Double? {
        guard let price, price > 0 else { return nil }
        return min(1, Double(totalAmount) / Double(price))
    }

    func remaining(for price: Int?) -> Int? {
        guard let price, price > 0 else { return nil }
        return max(0, price - totalAmount)
    }
}
