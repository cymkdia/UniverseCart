import Foundation

enum MallDetector {
    static func detect(from url: URL) -> Mall {
        let host = (url.host ?? "").lowercased()

        if host.contains("29cm") { return .cm29 }
        if host.contains("musinsa") { return .musinsa }
        if host.contains("wconcept") { return .wconcept }
        if host.contains("naver") || host.contains("smartstore") { return .naver }
        if host.contains("kurly") || host.contains("marketkurly") { return .kurly }

        return .etc
    }
}
