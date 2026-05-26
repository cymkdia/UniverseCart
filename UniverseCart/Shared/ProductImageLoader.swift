import Foundation
import UIKit

enum ProductImageLoader {
    private static let userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"

    static func load(imageURL: String?, mall: Mall?, productPageURL: String?) async -> UIImage? {
        guard let urlString = ImageURLNormalizer.resolve(imageURL),
              let url = URL(string: urlString)
        else {
            return nil
        }

        if let key = ProductImageCache.cacheKey(imageURL: urlString, productPageURL: productPageURL),
           let cached = ProductImageCache.image(forKey: key) {
            return cached
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        request.cachePolicy = .returnCacheDataElseLoad
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("image/avif,image/webp,image/apng,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("ko-KR,ko;q=0.9", forHTTPHeaderField: "Accept-Language")

        let refererValue = referer(productPageURL: productPageURL, imageURL: url, mall: mall)

        if let refererValue {
            request.setValue(refererValue, forHTTPHeaderField: "Referer")
        }

        if let image = await fetchImage(request: request) {
            storeCache(imageURL: urlString, productPageURL: productPageURL, image: image)
            return image
        }

        guard refererValue != nil else { return nil }

        var fallback = request
        fallback.setValue(nil, forHTTPHeaderField: "Referer")
        if let image = await fetchImage(request: fallback) {
            storeCache(imageURL: urlString, productPageURL: productPageURL, image: image)
            return image
        }

        return nil
    }

    private static func fetchImage(request: URLRequest) async -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200 ... 299).contains(http.statusCode),
                  let image = UIImage(data: data)
            else {
                return nil
            }
            return image
        } catch {
            return nil
        }
    }

    private static func storeCache(imageURL: String, productPageURL: String?, image: UIImage) {
        if let key = ProductImageCache.cacheKey(imageURL: imageURL, productPageURL: productPageURL) {
            ProductImageCache.store(image, forKey: key)
        }
    }

    private static func referer(productPageURL: String?, imageURL: URL, mall: Mall?) -> String? {
        if let page = ImageURLNormalizer.resolve(productPageURL),
           let pageURL = URL(string: page),
           pageURL.scheme?.hasPrefix("http") == true {
            return page
        }

        let host = (imageURL.host ?? "").lowercased()

        if host.contains("kurly") || mall == .kurly {
            return "https://www.kurly.com/"
        }
        if host.contains("29cm") || mall == .cm29 {
            return "https://www.29cm.co.kr/"
        }
        if host.contains("musinsa") || mall == .musinsa {
            return "https://www.musinsa.com/"
        }
        if host.contains("wconcept") || mall == .wconcept {
            return "https://www.wconcept.co.kr/"
        }
        if host.contains("naver") || host.contains("pstatic") || host.contains("shop-phinf") || mall == .naver {
            return "https://shopping.naver.com/"
        }

        return mall?.storefrontURL
    }
}
