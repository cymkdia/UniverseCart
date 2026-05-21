import Foundation
import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    private(set) var client: SupabaseClient?

    private init() {
        guard SupabaseConfig.isConfigured,
              let url = SupabaseConfig.projectURL,
              let key = SupabaseConfig.anonKey
        else {
            return
        }

        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: AuthRedirect.callbackURL
                )
            )
        )
    }

    var isReady: Bool {
        client != nil
    }
}
