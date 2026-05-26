import UIKit

enum ProductImageCache {
    private static let cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 120
        return cache
    }()

    static func image(forKey key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    static func store(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }

    static func cacheKey(imageURL: String?, productPageURL: String?) -> String? {
        guard let imageURL = ImageURLNormalizer.resolve(imageURL) else { return nil }
        return "\(imageURL)|\(productPageURL ?? "")"
    }
}
