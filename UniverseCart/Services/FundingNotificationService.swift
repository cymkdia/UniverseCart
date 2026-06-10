import Foundation
import Supabase

enum FundingNotificationService {
    static func fetchNotifications(
        client: SupabaseClient,
        userId: UUID,
        limit: Int = 30
    ) async throws -> [FundingNotificationRecord] {
        try await client
            .from("funding_notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    static func markRead(
        client: SupabaseClient,
        notificationId: UUID,
        userId: UUID
    ) async throws {
        let payload = MarkReadPayload(readAt: Date())
        try await client
            .from("funding_notifications")
            .update(payload)
            .eq("id", value: notificationId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }

    static func markAllRead(
        client: SupabaseClient,
        userId: UUID
    ) async throws {
        let payload = MarkReadPayload(readAt: Date())
        try await client
            .from("funding_notifications")
            .update(payload)
            .eq("user_id", value: userId.uuidString)
            .is("read_at", value: nil)
            .execute()
    }
}

private struct MarkReadPayload: Encodable {
    let readAt: Date

    enum CodingKeys: String, CodingKey {
        case readAt = "read_at"
    }
}
