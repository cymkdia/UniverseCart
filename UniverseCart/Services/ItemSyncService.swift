import Foundation
import Supabase

enum ItemSyncService {
    static func fetchItems(client: SupabaseClient, userId: UUID) async throws -> [Item] {
        let records: [ItemRecord] = try await client
            .from("items")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("updated_at", ascending: false)
            .execute()
            .value

        return records.compactMap { $0.toItem() }
    }

    static func replaceAll(client: SupabaseClient, userId: UUID, items: [Item]) async throws {
        try await client
            .from("items")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()

        guard !items.isEmpty else { return }

        let records = items.map { ItemRecord.from(item: $0, userId: userId) }
        try await client
            .from("items")
            .insert(records)
            .execute()
    }
}
