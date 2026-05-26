import Foundation

struct OGMetadata {
    let title: String?
    let imageURL: String?
    let price: Int?

    static let empty = OGMetadata(title: nil, imageURL: nil, price: nil)
}

enum OGMetadataExtractor {
    private enum FetchUserAgent {
        case mobileSafari
        case desktopChrome

        var value: String {
            switch self {
            case .mobileSafari:
                return "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
            case .desktopChrome:
                return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36"
            }
        }
    }

    static func fetch(from url: URL) async -> MetadataFetchResult {
        let mall = MallDetector.detect(from: url)
        let strategies: [FetchUserAgent] = mall == .kurly
            ? [.mobileSafari, .desktopChrome]
            : [.mobileSafari]

        var lastResult: MetadataFetchResult?

        for strategy in strategies {
            let result = await fetch(requestURL: url, mall: mall, userAgent: strategy)
            lastResult = result

            if !result.isHardFailure {
                return result
            }

            if case .blocked = result.primaryIssue {
                continue
            }
        }

        return lastResult ?? MetadataFetchResult(
            metadata: .empty,
            primaryIssue: .network,
            partialIssues: []
        )
    }

    private static func fetch(
        requestURL: URL,
        mall: Mall,
        userAgent: FetchUserAgent
    ) async -> MetadataFetchResult {
        var request = URLRequest(url: requestURL)
        request.timeoutInterval = 20
        request.setValue(userAgent.value, forHTTPHeaderField: "User-Agent")
        request.setValue(
            "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            forHTTPHeaderField: "Accept"
        )
        request.setValue("ko-KR,ko;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")

        if mall == .kurly {
            request.setValue("https://www.kurly.com/", forHTTPHeaderField: "Referer")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode

            if let statusCode, statusCode >= 400 {
                return MetadataFetchResult(
                    metadata: .empty,
                    primaryIssue: .blocked(statusCode: statusCode),
                    partialIssues: []
                )
            }

            guard let html = String(data: data, encoding: .utf8),
                  !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                return MetadataFetchResult(
                    metadata: .empty,
                    primaryIssue: .parseFailed,
                    partialIssues: []
                )
            }

            return parse(html: html, mall: mall)
        } catch {
            return MetadataFetchResult(
                metadata: .empty,
                primaryIssue: .network,
                partialIssues: []
            )
        }
    }

    private static func parse(html: String, mall: Mall) -> MetadataFetchResult {
        let rawTitle =
            metaContent(in: html, property: "og:title") ??
            metaContent(in: html, name: "title")
        let title = normalizeTitle(rawTitle, mall: mall)
        let imageURL = resolveImageURL(from: html)
        let price = parsePrice(from: html, mall: mall)
        let metadata = OGMetadata(title: title, imageURL: imageURL, price: price)

        var partialIssues: [MetadataFetchIssue] = []
        if title == nil || title?.isEmpty == true {
            partialIssues.append(.partialMissingTitle)
        }
        if price == nil {
            partialIssues.append(.partialMissingPrice)
        }
        if imageURL == nil || imageURL?.isEmpty == true {
            partialIssues.append(.partialMissingImage)
        }

        if title == nil, price == nil, imageURL == nil {
            return MetadataFetchResult(
                metadata: metadata,
                primaryIssue: .parseFailed,
                partialIssues: []
            )
        }

        return MetadataFetchResult(
            metadata: metadata,
            primaryIssue: nil,
            partialIssues: partialIssues
        )
    }

    private static func resolveImageURL(from html: String) -> String? {
        let candidates = [
            metaContent(in: html, property: "og:image:secure_url"),
            metaContent(in: html, property: "og:image"),
            metaContent(in: html, property: "twitter:image"),
            metaContent(in: html, name: "twitter:image"),
        ]

        for raw in candidates {
            guard let resolved = ImageURLNormalizer.resolve(raw) else { continue }
            if ImageURLNormalizer.looksLikeImageURL(resolved) {
                return resolved
            }
        }

        for raw in candidates {
            if let resolved = ImageURLNormalizer.resolve(raw) {
                return resolved
            }
        }

        return nil
    }

    private static func normalizeTitle(_ title: String?, mall: Mall) -> String? {
        guard var title, !title.isEmpty else { return nil }

        if mall == .kurly {
            let suffixes = [" - 마켓컬리", " | 마켓컬리", " · 마켓컬리"]
            for suffix in suffixes where title.hasSuffix(suffix) {
                title.removeLast(suffix.count)
                break
            }
        }

        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Price

    private static func parsePrice(from html: String, mall: Mall) -> Int? {
        if mall == .kurly, let price = parseKurlyPrice(in: html) { return price }
        if let price = parseJSONLDPrice(in: html) { return price }
        if let raw = metaContent(in: html, property: "product:price:amount")
            ?? metaContent(in: html, property: "og:price:amount") {
            return parseKRW(raw)
        }
        return parseMallSpecificPrice(in: html, mall: mall)
    }

    private static func parseKurlyPrice(in html: String) -> Int? {
        if let json = parseNextDataJSON(in: html),
           let price = findKurlySalePrice(in: json) {
            return price
        }

        let patterns = [
            #""discountedPrice"\s*:\s*(\d+)"#,
            #""salePrice"\s*:\s*(\d+)"#,
            #""discounted_price"\s*:\s*(\d+)"#,
            #""salesPrice"\s*:\s*(\d+)"#,
            #""basePrice"\s*:\s*(\d+)"#,
            #""retailPrice"\s*:\s*(\d+)"#,
        ]

        for pattern in patterns {
            if let raw = firstCapture(in: html, pattern: pattern),
               let price = parseKRW(raw) {
                return price
            }
        }

        return nil
    }

    private static func parseNextDataJSON(in html: String) -> Any? {
        let pattern = #"<script id="__NEXT_DATA__" type="application/json">([\s\S]*?)</script>"#
        guard let raw = firstCapture(in: html, pattern: pattern),
              let data = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) else {
            return nil
        }
        return json
    }

    private static func findKurlySalePrice(in object: Any) -> Int? {
        if let dict = object as? [String: Any] {
            for key in ["discountedPrice", "salePrice", "discounted_price", "salesPrice", "price", "lowPrice"] {
                if let value = dict[key], let price = parseKRWValue(value) {
                    return price
                }
            }

            for (_, value) in dict {
                if let price = findKurlySalePrice(in: value) { return price }
            }
        }

        if let array = object as? [Any] {
            for element in array {
                if let price = findKurlySalePrice(in: element) { return price }
            }
        }

        return nil
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
                #"data-price=["'](\d+)["']"#,
            ]
        case .musinsa:
            patterns = [
                #""salePrice"\s*:\s*(\d+)"#,
                #""price"\s*:\s*(\d+)"#,
                #"goods_price['\"]?\s*[:=]\s*['\"]?(\d+)"#,
            ]
        case .wconcept:
            patterns = [
                #""salePrice"\s*:\s*(\d+)"#,
                #""finalPrice"\s*:\s*(\d+)"#,
            ]
        case .naver:
            patterns = [
                #""salePrice"\s*:\s*(\d+)"#,
                #""discountedSalePrice"\s*:\s*(\d+)"#,
                #"product-sale-price[^>]*>([^<]*\d[^<]*)<"#,
            ]
        case .kurly:
            patterns = []
        case .etc:
            patterns = [
                #""price"\s*:\s*(\d+)"#,
                #"₩\s*([\d,]+)"#,
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
            #"<meta[^>]+content=["']([^"']+)["'][^>]+property=["']\#(property)["']"#,
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
            #"<meta[^>]+content=["']([^"']+)["'][^>]+name=["']\#(name)["']"#,
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

#if DEBUG
extension OGMetadataExtractor {
  static func parseHTMLForTesting(_ html: String, url: URL) -> MetadataFetchResult {
    parse(html: html, mall: MallDetector.detect(from: url))
  }
}
#endif
