import Foundation

/// 공유·담기 시 동일 상품 판별용 URL 정규화 (utm 등 제거)
enum ProductURLNormalizer {
    private static let trackingQueryNames: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "fbclid", "gclid", "gclsrc", "gbraid", "wbraid", "msclkid", "mc_eid",
        "igshid", "ref", "ref_src", "spm", "scm", "affiliate", "aff_id",
    ]

    static func normalize(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withScheme: String
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            withScheme = trimmed
        } else {
            withScheme = "https://\(trimmed)"
        }

        guard let url = URL(string: withScheme),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        else {
            return nil
        }

        components.scheme = "https"
        components.host = components.host?.lowercased()
        components.fragment = nil

        if var path = components.percentEncodedPath, path.count > 1, path.hasSuffix("/") {
            path.removeLast()
            components.percentEncodedPath = path
        }

        if let queryItems = components.queryItems, !queryItems.isEmpty {
            let kept = queryItems.filter { item in
                let name = item.name.lowercased()
                if trackingQueryNames.contains(name) { return false }
                if name.hasPrefix("utm_") { return false }
                return true
            }
            components.queryItems = kept.isEmpty ? nil : kept
        }

        return components.url
    }

    static func canonicalString(from raw: String) -> String? {
        normalize(raw)?.absoluteString
    }

    static func isSameProduct(_ lhs: String, _ rhs: String) -> Bool {
        guard let left = canonicalString(from: lhs),
              let right = canonicalString(from: rhs)
        else {
            return lhs.trimmingCharacters(in: .whitespacesAndNewlines)
                == rhs.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return left == right
    }
}
