import SwiftUI

/// 상품 썸네일 — 항상 1:1 정사각형 안에 이미지를 맞춤 (center crop)
struct ProductThumbnailView: View {
    let imageURL: String?
    var mall: Mall?
    var productPageURL: String?
    var cornerRadius: CGFloat = 6
    var showsWishIndicator: Bool = false

    @State private var loadedImage: UIImage?
    @State private var loadFailed = false

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .background(UCColor.surface)
            .overlay {
                squareImageLayer
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(alignment: .topTrailing) {
                if showsWishIndicator {
                    wishIndicator
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(UCColor.border, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            .task(id: taskKey) {
                await loadImage()
            }
    }

    private var taskKey: String {
        "\(imageURL ?? "")|\(mall?.rawValue ?? "")|\(productPageURL ?? "")"
    }

    private var squareImageLayer: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)

            ZStack {
                if let loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: side, height: side)
                        .clipped()
                } else {
                    placeholder
                        .frame(width: side, height: side)
                        .overlay {
                            if !loadFailed {
                                ProgressView()
                            }
                        }
                }
            }
            .frame(width: side, height: side)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(UCColor.surface)
            .overlay(
                VStack(spacing: 4) {
                    Image(systemName: "photo")
                        .font(.body)
                        .foregroundStyle(UCColor.textDisabled)
                    if loadFailed {
                        Text("이미지 없음")
                            .font(.caption2)
                            .foregroundStyle(UCColor.textDisabled)
                    }
                }
            )
    }

    private var wishIndicator: some View {
        Image(systemName: "heart.fill")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(UCColor.accent)
            .frame(width: 22, height: 22)
            .background(.white.opacity(0.92))
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(UCColor.border, lineWidth: 0.5)
            )
            .padding(6)
    }

    @MainActor
    private func loadImage() async {
        if let key = ProductImageCache.cacheKey(imageURL: imageURL, productPageURL: productPageURL),
           let cached = ProductImageCache.image(forKey: key) {
            loadedImage = cached
            loadFailed = false
            return
        }

        loadedImage = nil
        loadFailed = false

        guard ImageURLNormalizer.resolve(imageURL) != nil else {
            loadFailed = true
            return
        }

        let image = await ProductImageLoader.load(
            imageURL: imageURL,
            mall: mall,
            productPageURL: productPageURL
        )
        if let image {
            loadedImage = image
            loadFailed = false
        } else {
            loadFailed = true
        }
    }
}
