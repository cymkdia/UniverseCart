import Foundation

struct OGMetadata {
    let title: String?
    let imageURL: String?
    let price: Int?
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
                return OGMetadata(title: nil, imageURL: nil, price: nil)
            }

            let mall = MallDetector.detect(from: url)
            let title =
                metaContent(in: html, property: "og:title") ??
                metaContent(in: html, name: "title")
            let imageURL = metaContent(in: html, property: "og:image")
            let price = parsePrice(from: html, mall: mall)

            return OGMetadata(title: title, imageURL: imageURL, price: price)
        } catch {
            return OGMetadata(title: nil, imageURL: nil, price: nil)
        }
    }

    // MARK: - Price

    private static func parsePrice(from html: String, mall: Mall) -> Int? {
        if let price = parseJSONLDPrice(in: html) { return price }
        if let raw = metaContent(in: html, property: "product:price:amount")
            ?? metaContent(in: html, property: "og:price:amount") {
            return parseKRW(raw)
        }
        return parseMallSpecificPrice(in: html, mall: mall)
    }

    private static func parseJSONLDPrice(in html: String) -> Int? {
        let pattern = #"<script[^>]*type=["']application/ld\+json["'][^>]*>([\s\S]*?)</script>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            guard match.numberOfRanges > 1,
                  let scriptRange = Range(match.range(at: 1), in: html) else { continue }

            let script = String(html[scriptRange])
            guard let data = script.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data),
                  let price = findPrice(in: json) else { continue }

            return price
        }

        return nil
    }

    private static func findPrice(in object: Any) -> Int? {
        if let dict = object as? [String: Any] {
            if let offers = dict["offers"] {
                if let price = findPrice(in: offers) { return price }
            }

            for key in ["price", "lowPrice", "highPrice"] {
                if let value = dict[key], let price = parseKRWValue(value) {
                    return price
                }
            }

            for (_, value) in dict {
                if let price = findPrice(in: value) { return price }
            }
        }

        if let array = object as? [Any] {
            for element in array {
                if let price = findPrice(in: element) { return price }
            }
        }

        return nil
    }

    private static func parseKRWValue(_ value: Any) -> Int? {
        if let intValue = value as? Int, intValue > 0 { return intValue }
        if let doubleValue = value as? Double, doubleValue > 0 { return Int(doubleValue) }
        if let stringValue = value as? String { return parseKRW(stringValue) }
        return nil
    }

    private static func parseMallSpecificPrice(in html: String, mall: Mall) -> Int? {
        let patterns: [String]
        switch mall {
        case .cm29:
            patterns = [
                #""sellingPrice"\s*:\s*(\d+)"#,
                #""discountedPrice"\s*:\s*(\d+)"#,
                #"data-price=["'](\d+)["']"#
            ]
        case .musinsa:
            patterns = [
                #""salePrice"\s*:\s*(\d+)"#,
                #""price"\s*:\s*(\d+)"#,
                #"goods_price['\"]?\s*[:=]\s*['\"]?(\d+)"#
            ]
        case .wconcept:
            patterns = [
                #""salePrice"\s*:\s*(\d+)"#,
                #""finalPrice"\s*:\s*(\d+)"#
            ]
        case .naver:
            patterns = [
                #""salePrice"\s*:\s*(\d+)"#,
                #""discountedSalePrice"\s*:\s*(\d+)"#,
                #"product-sale-price[^>]*>([^<]*\d[^<]*)<"#
            ]
        case .etc:
            patterns = [
                #""price"\s*:\s*(\d+)"#,
                #"₩\s*([\d,]+)"#
            ]
        }

        for pattern in patterns {
            if let raw = firstCapture(in: html, pattern: pattern),
               let price = parseKRW(raw) {
                return price
            }
        }

        return nil
    }

    private static func parseKRW(_ raw: String) -> Int? {
        let digits = raw.filter(\.isNumber)
        guard let value = Int(digits), value > 0 else { return nil }
        return value
    }

    // MARK: - Meta

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
