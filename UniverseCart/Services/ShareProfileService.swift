import Foundation
import Supabase

enum ShareProfileService {
    static func fetchProfile(client: SupabaseClient, userId: UUID) async throws -> ProfileRecord? {
        let rows: [ProfileRecord] = try await client
            .from("profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .limit(1)
            .execute()
            .value

        return rows.first
    }

    static func enableSharing(
        client: SupabaseClient,
        userId: UUID,
        email: String?,
        existing: ProfileRecord?
    ) async throws -> ProfileRecord {
        let slug = existing?.shareSlug ?? makeSlug(from: email, userId: userId)
        let displayName = existing?.displayName ?? defaultDisplayName(from: email)

        let record = ProfileRecord(
            userId: userId,
            displayName: displayName,
            shareSlug: slug,
            shareEnabled: true,
            updatedAt: Date()
        )

        try await client
            .from("profiles")
            .upsert(record)
            .execute()

        return record
    }

    static func disableSharing(
        client: SupabaseClient,
        userId: UUID,
        existing: ProfileRecord
    ) async throws {
        var record = existing
        record.shareEnabled = false
        record.updatedAt = Date()

        try await client
            .from("profiles")
            .upsert(record)
            .execute()
    }

    static func shareURL(slug: String) -> String? {
        guard let base = SupabaseConfig.shareWebBaseURL else { return nil }
        let trimmed = base.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return "\(trimmed)?slug=\(slug)"
    }

    static func pledgeURL(slug: String, itemId: UUID) -> String? {
        guard let base = shareURL(slug: slug) else { return nil }
        return "\(base)&item=\(itemId.uuidString.lowercased())"
    }

    private static func makeSlug(from email: String?, userId: UUID) -> String {
        if let email,
           let prefix = email.split(separator: "@").first {
            let cleaned = prefix
                .lowercased()
                .filter { $0.isLetter || $0.isNumber }
            if cleaned.count >= 4 {
                return String(cleaned.prefix(20))
            }
        }

        return "uc-\(userId.uuidString.lowercased().prefix(8))"
    }

    private static func defaultDisplayName(from email: String?) -> String? {
        guard let email,
              let prefix = email.split(separator: "@").first
        else {
            return nil
        }
        return String(prefix)
    }
}
