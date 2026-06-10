import Foundation
import Supabase

enum FundingPledgeService {
    static func fetchPledges(client: SupabaseClient, itemId: UUID) async throws -> [FundingPledgeRecord] {
        let records: [FundingPledgeRecord] = try await client
            .from("funding_pledges")
            .select()
            .eq("item_id", value: itemId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value

        return records
    }
}
