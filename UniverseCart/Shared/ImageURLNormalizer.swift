import Foundation

enum ImageURLNormalizer {
    static func resolve(_ raw: String?) -> String? {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty
        else {
            return nil
        }

        value = decodeHTMLEntities(value)

        if value.hasPrefix("//") {
            value = "https:\(value)"
        }

        if value.hasPrefix("http://") {
            value = "https://" + value.dropFirst("http://".count)
        }

        guard let url = URL(string: value),
              url.scheme == "https" || url.scheme == "http"
        else {
            return nil
        }

        return url.absoluteString
    }

    static func looksLikeImageURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }

        let path = url.path.lowercased()
        let ext = [".jpg", ".jpeg", ".png", ".webp", ".gif", ".heic", ".bmp"]
        if ext.contains(where: { path.hasSuffix($0) || path.contains("\($0)?") }) {
            return true
        }

        let host = (url.host ?? "").lowercased()
        let imageHosts = [
            "img.", "image", "cdn", "cloudfront", "pstatic", "kurly", "29cm",
            "musinsa", "wconcept", "shop-phinf", "cafe24", "ssl.",
        ]
        if imageHosts.contains(where: { host.contains($0) }) {
            return true
        }

        let pathHints = ["/images/", "/image/", "/thumb", "/product", "/goods"]
        if pathHints.contains(where: { path.contains($0) }) {
            return true
        }

        return false
    }

    private static func decodeHTMLEntities(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#38;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
    }
}
