import Foundation

struct OGMetadata {
    let title: String?
    let imageURL: String?
}

enum OGMetadataExtractor {
    static func fetch(from url: URL) async -> OGMetadata {
        var request = URLRequest(url: url)
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15",
            forHTTPHeaderField: "User-Agent"
        )

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let html = String(data: data, encoding: .utf8) else {
                return OGMetadata(title: nil, imageURL: nil)
            }

            let title =
                metaContent(in: html, property: "og:title") ??
                metaContent(in: html, name: "title")

            let imageURL = metaContent(in: html, property: "og:image")

            return OGMetadata(title: title, imageURL: imageURL)
        } catch {
            return OGMetadata(title: nil, imageURL: nil)
        }
    }

    private static func metaContent(in html: String, property: String) -> String? {
        let patterns = [
            #"<meta[^>]+property=["']\#(property)["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']\#(property)["']"#
        ]

        for pattern in patterns {
            if let value = firstCapture(in: html, pattern: pattern) {
                return decode(value)
            }
        }
        return nil
    }

    private static func metaContent(in html: String, name: String) -> String? {
        let patterns = [
            #"<meta[^>]+name=["']\#(name)["'][^>]+content=["']([^"']+)["']"#,
            #"<meta[^>]+content=["']([^"']+)["'][^>]+name=["']\#(name)["']"#
        ]

        for pattern in patterns {
            if let value = firstCapture(in: html, pattern: pattern) {
                return decode(value)
            }
        }
        return nil
    }

    private static func firstCapture(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[captureRange])
    }

    private static func decode(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
