import SwiftUI

struct ProductThumbnailView: View {
    let imageURL: String?
    var cornerRadius: CGFloat = 6
    /// 「전체」 탭에서 위시/장바구니 구분용 (행 오른쪽 하트와 별도)
    var showsWishIndicator: Bool = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            imageContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            if showsWishIndicator {
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
        }
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var imageContent: some View {
        if let url = resolvedURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    placeholder
                default:
                    placeholder
                        .overlay(ProgressView())
                }
            }
        } else {
            placeholder
        }
    }

    private var resolvedURL: URL? {
        guard let raw = imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty,
              let url = URL(string: raw),
              url.scheme?.hasPrefix("http") == true
        else {
            return nil
        }
        return url
    }

    private var placeholder: some View {
        Rectangle()
            .fill(UCColor.surface)
            .overlay(
                Image(systemName: "photo")
                    .font(.body)
                    .foregroundStyle(UCColor.textDisabled)
            )
    }
}
