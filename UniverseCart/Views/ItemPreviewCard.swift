import SwiftUI

/// URL 미리보기·온보딩 공통 상품 카드
struct ItemPreviewCard: View {
    let item: Item

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductThumbnailView(
                imageURL: item.imageURL,
                mall: item.mall,
                productPageURL: item.productURL,
                cornerRadius: 6
            )
            .frame(width: 72, height: 72)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UCColor.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(metaLine)
                    .font(.caption)
                    .foregroundStyle(UCColor.textSecond)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UCColor.accentSoft)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var metaLine: String {
        if let price = item.price {
            return "\(item.mall.listLabel) · \(formatKRW(price))"
        }
        return item.mall.listLabel
    }

    private func formatKRW(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}
