import Foundation

enum SupabaseConfig {
    private static let secretsFileName = "SupabaseSecrets"
    private static let urlKey = "SUPABASE_URL"
    private static let anonKeyKey = "SUPABASE_ANON_KEY"
    private static let shareWebBaseURLKey = "SHARE_WEB_BASE_URL"

    static var projectURL: URL? {
        guard let raw = string(for: urlKey) else { return nil }
        return URL(string: raw)
    }

    static var anonKey: String? {
        string(for: anonKeyKey)
    }

    static var shareWebBaseURL: String? {
        string(for: shareWebBaseURLKey)
    }

    static var isConfigured: Bool {
        projectURL != nil && anonKey != nil
    }

    private static func string(for key: String) -> String? {
        guard let url = Bundle.main.url(forResource: secretsFileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let value = plist[key] as? String
        else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains("YOUR_")
        else {
            return nil
        }

        return trimmed
    }
}
