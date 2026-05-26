import SwiftUI

struct ItemDetailView: View {
    @Environment(\.openURL) private var openURL

    let item: Item
    let onToggleListType: () -> Void
    let onTapPrice: () -> Void

    @State private var selectedSize = "M"
    @State private var quantity = 1

    private var compareRows: [MallPriceCompareRow] {
        ItemDetailSampleData.compareRows(for: item)
    }

    private var fundingProgress: Double {
        ItemDetailSampleData.fundingProgress(for: item)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                productImage
                VStack(alignment: .leading, spacing: 20) {
                    metaSection
                    titleSection
                    optionNote
                    priceSection
                    priceInsightCard
                    sizeSection
                    quantitySection
                    compareSection
                    if item.listType == .wishlist {
                        fundingSection
                    }
                    openStoreButton
                    hintText
                }
                .padding(20)
            }
        }
        .background(UCColor.bg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onToggleListType) {
                    Image(systemName: item.listType == .wishlist ? "heart.fill" : "heart")
                        .foregroundStyle(item.listType == .wishlist ? UCColor.accent : UCColor.textSecond)
                }
            }
        }
    }

    private var productImage: some View {
        ZStack(alignment: .bottomLeading) {
            ProductThumbnailView(
                imageURL: item.imageURL,
                cornerRadius: 0
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 6) {
                MallBadge(mall: item.mall)
                Text(item.mall.displayName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(UCColor.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.white.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(16)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: .infinity)
        .background(UCColor.surface)
        .clipped()
    }

    private var metaSection: some View {
        HStack {
            Text(item.category.displayName)
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(UCColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Spacer()

            Text(item.listType.displayName)
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
        }
    }

    private var titleSection: some View {
        Text(item.title)
            .font(.title3.bold())
            .foregroundStyle(UCColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var optionNote: some View {
        Text("\(selectedSize) · 수량 \(quantity)개 · 옵션은 쇼핑몰에서 최종 선택")
            .font(.caption)
            .foregroundStyle(UCColor.textSecond)
    }

    private var priceSection: some View {
        Group {
            if let price = item.price {
                VStack(alignment: .leading, spacing: 4) {
                    Text("판매가")
                        .font(.caption)
                        .foregroundStyle(UCColor.textSecond)
                    Text(formatPrice(price))
                        .font(.title2.bold())
                        .foregroundStyle(UCColor.textPrimary)
                }
            } else {
                Button(action: onTapPrice) {
                    Text("가격 입력하기")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(UCColor.accent)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var priceInsightCard: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.subheadline)
                .foregroundStyle(Color(hex: "3A8C5C"))

            Text(
                item.price == nil
                    ? "가격을 입력하면 다른 몰 비교·펀딩 예시가 더 잘 보여요."
                    : "가격 추적은 준비 중이에요. 지금 보이는 금액은 담을 때 기록한 가격이에요."
            )
            .font(.caption)
            .foregroundStyle(UCColor.textSecond)
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var sizeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailSectionTitle(title: "사이즈")

            FlowLayout(spacing: 6) {
                ForEach(ItemDetailSampleData.sizes, id: \.self) { size in
                    Button {
                        selectedSize = size
                    } label: {
                        Text(size)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(
                                selectedSize == size ? UCColor.bg : UCColor.textSecond
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedSize == size ? UCColor.textPrimary : UCColor.bg
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(UCColor.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quantitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailSectionTitle(title: "수량")

            HStack {
                HStack(spacing: 12) {
                    stepperButton(symbol: "−") {
                        quantity = max(1, quantity - 1)
                    }

                    Text("\(quantity)")
                        .font(.subheadline.weight(.bold))
                        .frame(minWidth: 20)

                    stepperButton(symbol: "+") {
                        quantity += 1
                    }
                }

                Spacer()

                if let price = item.price {
                    Text("소계 \(formatPrice(price * quantity))")
                        .font(.caption)
                        .foregroundStyle(UCColor.textSecond)
                }
            }
        }
    }

    private var compareSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailSectionTitle(title: "다른 쇼핑몰 가격")

            VStack(spacing: 0) {
                ForEach(compareRows) { row in
                    compareRow(row)
                    if row.id != compareRows.last?.id {
                        Divider().overlay(UCColor.border)
                    }
                }
            }
            .background(UCColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("※ 실제 연동 전 예시 UI예요. 같은 상품 URL 기준 비교는 다음 업데이트 예정.")
                .font(.caption2)
                .foregroundStyle(UCColor.textDisabled)
        }
    }

    private func compareRow(_ row: MallPriceCompareRow) -> some View {
        HStack {
            HStack(spacing: 7) {
                Circle()
                    .fill(UCColor.mallColor(row.mall))
                    .frame(width: 6, height: 6)

                Text(row.mall.displayName)
                    .font(.subheadline)
                    .foregroundStyle(UCColor.textSecond)

                if row.trend == .current {
                    Text("현재")
                        .font(.caption2)
                        .foregroundStyle(UCColor.textSecond)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(UCColor.bg)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(UCColor.border, lineWidth: 1)
                        )
                }
            }

            Spacer()

            Text(comparePriceText(row))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(comparePriceColor(row))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var fundingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            DetailSectionTitle(title: "친구 펀딩 현황")

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("친구가 함께 모으는 중")
                        .font(.subheadline)
                        .foregroundStyle(UCColor.textSecond)

                    Spacer()

                    Text("\(Int(fundingProgress * 100))%")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color(hex: "3A8C5C"))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(UCColor.border)
                            .frame(height: 4)
                        Capsule()
                            .fill(Color(hex: "7BAF92"))
                            .frame(width: geo.size.width * fundingProgress, height: 4)
                    }
                }
                .frame(height: 4)

                if let price = item.price {
                    let collected = ItemDetailSampleData.fundingCollected(for: item)
                    let remaining = max(0, price - collected)
                    Text("\(formatPrice(collected)) 모였어요 · \(formatPrice(remaining)) 남았어요")
                        .font(.caption)
                        .foregroundStyle(UCColor.textSecond)
                } else {
                    Text("가격을 입력하면 펀딩 진행률 예시가 보여요.")
                        .font(.caption)
                        .foregroundStyle(UCColor.textSecond)
                }
            }
            .padding(12)
            .background(UCColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("※ M7 데모 UI. 실제 친구 펀딩은 M6 이후 기능으로 연결 예정.")
                .font(.caption2)
                .foregroundStyle(UCColor.textDisabled)
        }
    }

    private var openStoreButton: some View {
        UCPrimaryCTA("\(item.mall.displayName)에서 보기", systemImage: "arrow.up.right.square") {
            openProductURL()
        }
    }

    private var hintText: some View {
        Text("원래 쇼핑몰 앱·Safari에서 옵션 선택과 결제를 이어가면 됩니다.")
            .font(.footnote)
            .foregroundStyle(UCColor.textSecond)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private func stepperButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(symbol)
                .font(.title3)
                .foregroundStyle(UCColor.textPrimary)
                .frame(width: 30, height: 30)
                .background(UCColor.bg)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(UCColor.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func comparePriceText(_ row: MallPriceCompareRow) -> String {
        let base = formatPrice(row.price)
        switch row.trend {
        case .current: return base
        case .lower: return "\(base) ↓"
        case .higher: return "\(base)"
        }
    }

    private func comparePriceColor(_ row: MallPriceCompareRow) -> Color {
        switch row.trend {
        case .current: return UCColor.textPrimary
        case .lower: return Color(hex: "3A8C5C")
        case .higher: return UCColor.textDisabled
        }
    }

    private func openProductURL() {
        guard let url = URL(string: item.productURL),
              url.scheme?.hasPrefix("http") == true
        else {
            return
        }
        openURL(url)
    }

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}

/// 간단한 칩 줄바꿈 레이아웃
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}
