import SwiftUI

struct ItemDetailView: View {
    @Environment(\.openURL) private var openURL
    @Environment(AuthSession.self) private var auth
    @Environment(FundingNotificationCenter.self) private var notificationCenter

    let item: Item
    let ownerUserId: UUID?
    let onToggleListType: () -> Void
    let onTapPrice: () -> Void
    var onItemUpdated: ((Item) -> Void)?

    @State private var pledgeSummary = FundingPledgeSummary(pledges: [])
    @State private var coordination: FundingCoordinationRecord?
    @State private var isLoadingFunding = false
    @State private var shareProfile: ProfileRecord?
    @State private var showingVolunteerSheet = false
    @State private var showingSettlement = false
    @State private var showingReceivedSheet = false
    @State private var showingShareWishlistSheet = false
    @State private var actionErrorMessage: String?

    private var canOpenStore: Bool {
        guard let url = URL(string: item.productURL) else { return false }
        return url.scheme == "https" || url.scheme == "http"
    }

    private var coordinationContext: FundingCoordinationContext {
        FundingCoordinationContext(
            record: coordination,
            summary: pledgeSummary,
            itemPrice: item.price
        )
    }

    private var isOwner: Bool {
        guard let current = auth.currentUserId(), let ownerUserId else { return false }
        return current == ownerUserId
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                productImage

                VStack(alignment: .leading, spacing: 20) {
                    metaSection
                    titleSection
                    priceSection

                    if item.listType == .wishlist || item.listType == .receivedGift {
                        FundingPledgeSection(
                            item: item,
                            context: coordinationContext,
                            isLoading: isLoadingFunding,
                            pledgeWebURL: pledgeWebURL,
                            isShareEnabled: shareProfile?.shareEnabled == true,
                            currentUserId: auth.currentUserId(),
                            ownerUserId: ownerUserId,
                            onShareWishlist: { showingShareWishlistSheet = true },
                            onVolunteerAsBuyer: { showingVolunteerSheet = true },
                            onOpenSettlement: { showingSettlement = true },
                            onMarkPurchased: { Task { await markPurchased() } },
                            onMarkReceived: { showingReceivedSheet = true }
                        )
                    }

                    if let actionErrorMessage {
                        Text(actionErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    if canOpenStore {
                        UCPrimaryCTA("\(item.mall.displayName)에서 보기", systemImage: "arrow.up.right.square") {
                            openProductURL()
                        }
                    } else if item.listType != .receivedGift {
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
            if item.listType != .receivedGift, isOwner {
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
        }
        .task(id: item.id) {
            await loadShareProfileIfNeeded()
            await reloadFundingData()
        }
        .sheet(isPresented: $showingVolunteerSheet) {
            VolunteerBuyerSheet(itemTitle: item.title) { bank, account in
                try await volunteerAsBuyer(bank: bank, accountNumber: account)
            }
        }
        .sheet(isPresented: $showingSettlement) {
            if let record = coordination {
                SettlementGuideView(
                    itemTitle: item.title,
                    coordination: record,
                    pledges: pledgeSummary.pledges,
                    buyerDisplayName: buyerDisplayName(for: record),
                    currentUserId: auth.currentUserId()
                )
            }
        }
        .sheet(isPresented: $showingReceivedSheet) {
            MarkGiftReceivedSheet(itemTitle: item.title) { message in
                try await markReceived(thankYouMessage: message)
            }
        }
        .sheet(isPresented: $showingShareWishlistSheet) {
            ShareWishlistSheet(shareProfile: $shareProfile)
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
                .foregroundStyle(item.listType == .receivedGift ? UCColor.fundingText : UCColor.textSecond)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.listType == .receivedGift ? UCColor.fundingSoft : UCColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: UCRadius.xs))
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
    private func reloadFundingData() async {
        guard item.listType == .wishlist || item.listType == .receivedGift,
              let client = SupabaseService.shared.client
        else {
            return
        }

        isLoadingFunding = true
        defer { isLoadingFunding = false }

        do {
            let pledges = try await FundingPledgeService.fetchPledges(
                client: client,
                itemId: item.id
            )
            pledgeSummary = FundingPledgeSummary(pledges: pledges)
            coordination = try await FundingCoordinationService.fetchCoordination(
                client: client,
                itemId: item.id
            )
        } catch {
            pledgeSummary = FundingPledgeSummary(pledges: [])
        }
    }

    @MainActor
    private func volunteerAsBuyer(bank: SettlementBankOption, accountNumber: String) async throws {
        guard let client = SupabaseService.shared.client,
              let userId = auth.currentUserId(),
              let ownerId = ownerUserId
        else {
            throw FundingCoordinationError.notAuthorized
        }

        let previous = coordination
        coordination = FundingCoordinationRecord(
            itemId: item.id,
            ownerUserId: ownerId,
            state: .buyerAssigned,
            buyerUserId: userId,
            goalReachedAt: coordination?.goalReachedAt,
            purchasedAt: nil,
            receivedAt: nil,
            thankYouMessage: nil,
            settlementBankName: bank.tossBankName,
            settlementBankCode: bank.kakaoBankCode,
            settlementAccountNumber: accountNumber.filter(\.isNumber),
            updatedAt: Date()
        )

        do {
            coordination = try await FundingCoordinationService.volunteerAsBuyer(
                client: client,
                itemId: item.id,
                ownerUserId: ownerId,
                buyerUserId: userId,
                bank: bank,
                accountNumber: accountNumber
            )
            await notificationCenter.refresh(auth: auth)
        } catch {
            coordination = previous
            throw error
        }
    }

    @MainActor
    private func markPurchased() async {
        guard let client = SupabaseService.shared.client,
              let userId = auth.currentUserId(),
              let ownerId = ownerUserId
        else {
            actionErrorMessage = FundingCoordinationError.notAuthorized.errorDescription
            return
        }

        let previous = coordination
        if var optimistic = coordination {
            optimistic.state = .purchased
            optimistic.purchasedAt = Date()
            coordination = optimistic
        }

        do {
            coordination = try await FundingCoordinationService.markPurchased(
                client: client,
                itemId: item.id,
                ownerUserId: ownerId,
                buyerUserId: userId
            )
            actionErrorMessage = nil
            await notificationCenter.refresh(auth: auth)
        } catch {
            coordination = previous
            actionErrorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func markReceived(thankYouMessage: String?) async throws {
        guard let client = SupabaseService.shared.client,
              let userId = ownerUserId
        else {
            throw FundingCoordinationError.notAuthorized
        }

        let previousCoordination = coordination
        let previousItem = item

        if var optimistic = coordination {
            optimistic.state = .received
            optimistic.receivedAt = Date()
            optimistic.thankYouMessage = thankYouMessage
            coordination = optimistic
        }

        var archivedItem = item
        archivedItem.listType = .receivedGift

        do {
            coordination = try await FundingCoordinationService.markReceived(
                client: client,
                itemId: item.id,
                ownerUserId: userId,
                thankYouMessage: thankYouMessage
            )
            try await ItemSyncService.updateItem(
                client: client,
                userId: userId,
                item: archivedItem
            )
            onItemUpdated?(archivedItem)
            actionErrorMessage = nil
            await notificationCenter.refresh(auth: auth)
        } catch {
            coordination = previousCoordination
            onItemUpdated?(previousItem)
            throw error
        }
    }

    private func buyerDisplayName(for record: FundingCoordinationRecord) -> String {
        guard let buyerId = record.buyerUserId else { return "대표" }
        if let pledge = pledgeSummary.pledges.first(where: { $0.contributorUserId == buyerId }) {
            return pledge.displayContributorName
        }
        return "대표"
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
        RemittanceDeepLinkBuilder.formatPrice(value)
    }
}
