import SwiftUI

struct ItemDetailView: View {
    @Environment(\.openURL) private var openURL
    @Environment(AuthSession.self) private var auth

    let item: Item
    let onToggleListType: () -> Void
    let onTapPrice: () -> Void

    @State private var pledgeSummary = FundingPledgeSummary(pledges: [])
    @State private var isLoadingPledges = false
    @State private var shareProfile: ProfileRecord?

    private var canOpenStore: Bool {
        guard let url = URL(string: item.productURL) else { return false }
        return url.scheme == "https" || url.scheme == "http"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                productImage

                VStack(alignment: .leading, spacing: 20) {
                    metaSection
                    titleSection
                    priceSection

                    if item.listType == .wishlist {
                        FundingPledgeSection(
                            item: item,
                            summary: pledgeSummary,
                            isLoading: isLoadingPledges,
                            pledgeWebURL: pledgeWebURL,
                            isShareEnabled: shareProfile?.shareEnabled == true
                        )
                    }

                    if canOpenStore {
                        UCPrimaryCTA("\(item.mall.displayName)에서 보기", systemImage: "arrow.up.right.square") {
                            openProductURL()
                        }
                    } else {
                        Text("직접 입력한 항목이거나 링크가 없어요.")
                            .font(.footnote)
                            .foregroundStyle(UCColor.textSecond)
                    }

                    Text("옵션·결제는 원래 쇼핑몰 앱·Safari에서 이어가면 됩니다.")
                        .font(.footnote)
                        .foregroundStyle(UCColor.textSecond)
                        .frame(maxWidth: .infinity, alignment: .center)
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
                .accessibilityLabel(
                    item.listType == .wishlist ? "장바구니로 옮기기" : "위시리스트에 담기"
                )
            }
        }
        .task(id: item.id) {
            await loadShareProfileIfNeeded()
            await loadPledgesIfNeeded()
        }
    }

    private var pledgeWebURL: URL? {
        guard let slug = shareProfile?.shareSlug,
              shareProfile?.shareEnabled == true,
              let urlString = ShareProfileService.pledgeURL(slug: slug, itemId: item.id)
        else {
            return nil
        }

        return URL(string: urlString)
    }

    private var productImage: some View {
        ProductThumbnailView(
            imageURL: item.imageURL,
            mall: item.mall,
            productPageURL: item.productURL,
            cornerRadius: 0
        )
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var metaSection: some View {
        HStack(spacing: 8) {
            MallBadge(mall: item.mall)

            Text(item.category.displayName)
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)

            Spacer()

            Text(item.listType.displayName)
                .font(.caption.weight(.medium))
                .foregroundStyle(UCColor.textSecond)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(UCColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    private var titleSection: some View {
        Text(item.title)
            .font(.title3.bold())
            .foregroundStyle(UCColor.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var priceSection: some View {
        Group {
            if let price = item.price {
                VStack(alignment: .leading, spacing: 4) {
                    Text("담을 때 가격")
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

    @MainActor
    private func loadShareProfileIfNeeded() async {
        guard item.listType == .wishlist,
              let client = SupabaseService.shared.client,
              let userId = auth.currentUserId()
        else {
            shareProfile = nil
            return
        }

        do {
            shareProfile = try await ShareProfileService.fetchProfile(
                client: client,
                userId: userId
            )
        } catch {
            shareProfile = nil
        }
    }

    @MainActor
    private func loadPledgesIfNeeded() async {
        guard item.listType == .wishlist,
              let client = SupabaseService.shared.client
        else {
            return
        }

        isLoadingPledges = true
        defer { isLoadingPledges = false }

        do {
            let pledges = try await FundingPledgeService.fetchPledges(
                client: client,
                itemId: item.id
            )
            pledgeSummary = FundingPledgeSummary(pledges: pledges)
        } catch {
            pledgeSummary = FundingPledgeSummary(pledges: [])
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
