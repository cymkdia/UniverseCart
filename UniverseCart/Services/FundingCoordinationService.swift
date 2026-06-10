import Foundation
import Supabase

enum FundingCoordinationService {
    static func fetchCoordination(
        client: SupabaseClient,
        itemId: UUID
    ) async throws -> FundingCoordinationRecord? {
        let rows: [FundingCoordinationRecord] = try await client
            .from("funding_coordinations")
            .select()
            .eq("item_id", value: itemId.uuidString)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    static func volunteerAsBuyer(
        client: SupabaseClient,
        itemId: UUID,
        ownerUserId: UUID,
        buyerUserId: UUID,
        bank: SettlementBankOption,
        accountNumber: String
    ) async throws -> FundingCoordinationRecord {
        let sanitized = accountNumber.filter { $0.isNumber }
        guard sanitized.count >= 10 else {
            throw FundingCoordinationError.invalidAccount
        }

        let payload = VolunteerBuyerPayload(
            itemId: itemId,
            ownerUserId: ownerUserId,
            buyerUserId: buyerUserId,
            state: .buyerAssigned,
            settlementBankName: bank.tossBankName,
            settlementBankCode: bank.kakaoBankCode,
            settlementAccountNumber: sanitized,
            updatedAt: Date()
        )

        let rows: [FundingCoordinationRecord] = try await client
            .from("funding_coordinations")
            .upsert(payload, onConflict: "item_id")
            .select()
            .execute()
            .value

        guard let record = rows.first else {
            throw FundingCoordinationError.saveFailed
        }

        try await createNotifications(
            client: client,
            itemId: itemId,
            ownerUserId: ownerUserId,
            kind: .buyerAssigned,
            title: "대표 구매자가 정해졌어요",
            ownerBody: "참여자들이 송금할 수 있도록 정산 안내를 확인해 주세요.",
            participantBody: "대표 구매자에게 약속 금액을 송금해 주세요."
        )

        return record
    }

    static func markPurchased(
        client: SupabaseClient,
        itemId: UUID,
        ownerUserId: UUID,
        buyerUserId: UUID
    ) async throws -> FundingCoordinationRecord {
        let payload = PurchasedPayload(
            state: .purchased,
            purchasedAt: Date(),
            updatedAt: Date()
        )

        let rows: [FundingCoordinationRecord] = try await client
            .from("funding_coordinations")
            .update(payload)
            .eq("item_id", value: itemId.uuidString)
            .eq("buyer_user_id", value: buyerUserId.uuidString)
            .select()
            .execute()
            .value

        guard let record = rows.first else {
            throw FundingCoordinationError.saveFailed
        }

        try await createNotifications(
            client: client,
            itemId: itemId,
            ownerUserId: ownerUserId,
            kind: .purchased,
            title: "구매가 완료됐어요",
            ownerBody: "선물이 도착하면 「선물 받음」을 눌러 주세요.",
            participantBody: "대표 구매자가 구매를 완료했어요."
        )

        return record
    }

    static func markReceived(
        client: SupabaseClient,
        itemId: UUID,
        ownerUserId: UUID,
        thankYouMessage: String?
    ) async throws -> FundingCoordinationRecord {
        let trimmedMessage = thankYouMessage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let payload = ReceivedPayload(
            state: .received,
            receivedAt: Date(),
            thankYouMessage: trimmedMessage?.isEmpty == true ? nil : trimmedMessage,
            updatedAt: Date()
        )

        let rows: [FundingCoordinationRecord] = try await client
            .from("funding_coordinations")
            .update(payload)
            .eq("item_id", value: itemId.uuidString)
            .eq("owner_user_id", value: ownerUserId.uuidString)
            .select()
            .execute()
            .value

        guard let record = rows.first else {
            throw FundingCoordinationError.saveFailed
        }

        let participantBody = if let trimmedMessage, !trimmedMessage.isEmpty {
            "감사 메시지: \(trimmedMessage)"
        } else {
            "함께해 주셔서 감사해요!"
        }

        try await createNotifications(
            client: client,
            itemId: itemId,
            ownerUserId: ownerUserId,
            kind: .received,
            title: "선물이 도착했어요",
            ownerBody: "받은 선물 아카이브에 보관됐어요",
            participantBody: participantBody
        )

        return record
    }

    private static func createNotifications(
        client: SupabaseClient,
        itemId: UUID,
        ownerUserId: UUID,
        kind: FundingNotificationKind,
        title: String,
        ownerBody: String,
        participantBody: String
    ) async throws {
        let pledges = try await FundingPledgeService.fetchPledges(client: client, itemId: itemId)
        var payloads: [FundingNotificationInsert] = [
            FundingNotificationInsert(
                userId: ownerUserId,
                itemId: itemId,
                kind: kind,
                title: title,
                body: ownerBody
            ),
        ]

        for pledge in pledges where pledge.contributorUserId != ownerUserId {
            payloads.append(
                FundingNotificationInsert(
                    userId: pledge.contributorUserId,
                    itemId: itemId,
                    kind: kind,
                    title: title,
                    body: participantBody
                )
            )
        }

        try await client
            .from("funding_notifications")
            .insert(payloads)
            .execute()
    }
}

enum FundingCoordinationError: LocalizedError {
    case invalidAccount
    case saveFailed
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .invalidAccount: return "계좌번호를 10자리 이상 입력해 주세요."
        case .saveFailed: return "저장하지 못했어요. 다시 시도해 주세요."
        case .notAuthorized: return "이 작업을 할 권한이 없어요."
        }
    }
}

private struct VolunteerBuyerPayload: Encodable {
    let itemId: UUID
    let ownerUserId: UUID
    let buyerUserId: UUID
    let state: FundingCoordinationState
    let settlementBankName: String
    let settlementBankCode: String
    let settlementAccountNumber: String
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case itemId = "item_id"
        case ownerUserId = "owner_user_id"
        case buyerUserId = "buyer_user_id"
        case state
        case settlementBankName = "settlement_bank_name"
        case settlementBankCode = "settlement_bank_code"
        case settlementAccountNumber = "settlement_account_number"
        case updatedAt = "updated_at"
    }
}

private struct PurchasedPayload: Encodable {
    let state: FundingCoordinationState
    let purchasedAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case state
        case purchasedAt = "purchased_at"
        case updatedAt = "updated_at"
    }
}

private struct ReceivedPayload: Encodable {
    let state: FundingCoordinationState
    let receivedAt: Date
    let thankYouMessage: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case state
        case receivedAt = "received_at"
        case thankYouMessage = "thank_you_message"
        case updatedAt = "updated_at"
    }
}
