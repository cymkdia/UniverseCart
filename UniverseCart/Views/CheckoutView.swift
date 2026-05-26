import SwiftUI

struct CheckoutView: View {
    @Environment(\.openURL) private var openURL

    let cartItems: [Item]

    private var mallGroups: [(mall: Mall, items: [Item])] {
        let grouped = Dictionary(grouping: cartItems, by: \.mall)
        return Mall.allCases.compactMap { mall in
            guard let items = grouped[mall], !items.isEmpty else { return nil }
            return (mall, items)
        }
    }

    private var grandTotal: Int {
        cartItems.compactMap(\.price).reduce(0, +)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                totalHeader
                Divider().overlay(UCColor.border)

                if mallGroups.isEmpty {
                    emptyState
                } else {
                    ForEach(mallGroups, id: \.mall) { group in
                        mallSection(mall: group.mall, items: group.items)
                    }
                }
            }
            .padding(20)
        }
        .background(UCColor.bg)
        .navigationTitle("쇼핑몰별 결제")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var totalHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("장바구니 합계")
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)

            Text(formatPrice(grandTotal))
                .font(.title.bold())
                .foregroundStyle(UCColor.textPrimary)

            Text("\(cartItems.count)개 · \(mallGroups.count)개 쇼핑몰")
                .font(.footnote)
                .foregroundStyle(UCColor.textSecond)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("장바구니가 비어 있어요")
                .font(.headline)
            Text("내 장바구니에 담은 상품이 여기에 모여요.")
                .font(.subheadline)
                .foregroundStyle(UCColor.textSecond)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func mallSection(mall: Mall, items: [Item]) -> some View {
        let subtotal = items.compactMap(\.price).reduce(0, +)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                MallBadge(mall: mall)
                Text(mall.displayName)
                    .font(.headline)
                Spacer()
                Text(formatPrice(subtotal))
                    .font(.subheadline.weight(.semibold))
            }

            ForEach(items) { item in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(UCColor.surface)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "bag")
                                .font(.caption)
                                .foregroundStyle(UCColor.textDisabled)
                        )

                    Text(item.title)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(UCColor.textPrimary)

                    Spacer(minLength: 0)

                    if let price = item.price {
                        Text(formatPrice(price))
                            .font(.caption.weight(.semibold))
                    }
                }
            }

            Button {
                openCheckout(for: mall, items: items)
            } label: {
                Text("\(mall.displayName)에서 결제하기")
            }
            .buttonStyle(UCPrimaryButtonStyle())

            Text("각 쇼핑몰 앱·Safari에서 결제를 이어가요.")
                .font(.caption2)
                .foregroundStyle(UCColor.textSecond)
        }
        .padding(14)
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }

    private func openCheckout(for mall: Mall, items: [Item]) {
        let urlString = items.first?.productURL ?? mall.storefrontURL
        guard let url = URL(string: urlString),
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
