import SwiftUI

enum HomeSegment: String, CaseIterable {
    case all = "전체"
    case wishlist = "위시리스트"
    case cart = "내 장바구니"
    case receivedGifts = "받은 선물"
}

enum CategoryChip: String, CaseIterable {
    case all = "전체"
    case fashion = "패션"
    case beauty = "뷰티"
    case home = "홈리빙"
    case appliance = "가전"
    case food = "식품"
    case sports = "스포츠"

    var mappedCategory: Category? {
        switch self {
        case .all: return nil
        case .fashion: return .fashion
        case .beauty: return .beauty
        case .home: return .home
        case .appliance: return .appliance
        case .food: return .food
        case .sports: return .sports
        }
    }

    var layoutWeight: CGFloat {
        mappedCategory?.barLayoutWeight ?? 2
    }
}

struct MainListView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AuthSession.self) private var auth

    @State private var items: [Item] = []
    @State private var isSyncing = false
    @State private var didLoadStoredItems = false
    @State private var selectedSegment: HomeSegment = .all
    @State private var selectedChip: CategoryChip = .all
    @State private var isGrid = false
    @State private var showingAddSheet = false
    @State private var showingURLSheet = false
    @State private var showingPriceSheet = false
    @State private var priceEditingItemID: UUID?
    @State private var priceInputText = ""
    @State private var justAddedItemIDs: Set<UUID> = []
    @State private var selectedItemID: UUID?
    @State private var shareProfile: ProfileRecord?
    @State private var showingShareWishlistSheet = false

    private var wishlistItems: [Item] {
        items.filter { $0.listType == .wishlist }
    }

    private var wishlistPublicCount: Int {
        guard shareProfile?.shareEnabled == true else { return 0 }
        return wishlistItems.count
    }

    private var wishlistPrivateCount: Int {
        wishlistItems.count - wishlistPublicCount
    }

    private var filteredItems: [Item] {
        items.filter { item in
            let segmentPass: Bool = {
                switch selectedSegment {
                case .all: return true
                case .wishlist: return item.listType == .wishlist
                case .cart: return item.listType == .cart
                case .receivedGifts: return item.listType == .receivedGift
                }
            }()

            let categoryPass: Bool = {
                guard let category = selectedChip.mappedCategory else { return true }
                return item.category == category
            }()

            return segmentPass && categoryPass
        }
    }

    private var totalCount: Int { filteredItems.count }

    private var totalPrice: Int {
        filteredItems.compactMap { $0.price }.reduce(0, +)
    }

    private var wishlistCount: Int {
        filteredItems.filter { $0.listType == .wishlist }.count
    }

    private var cartItems: [Item] {
        items.filter { $0.listType == .cart }
    }

    private var emptyStateMessage: (title: String, subtitle: String) {
        if items.isEmpty {
            return (
                "아직 담은 상품이 없어요",
                "쇼핑몰에서 공유하거나 + 버튼으로 추가해 보세요"
            )
        }

        switch selectedSegment {
        case .wishlist:
            return (
                "위시리스트가 비어 있어요",
                "마음에 드는 상품을 위시리스트에 담아보세요"
            )
        case .cart:
            return (
                "장바구니가 비어 있어요",
                "구매할 상품을 장바구니에 담아보세요"
            )
        case .receivedGifts:
            return (
                "받은 선물이 없어요",
                "펀딩이 완료된 선물이 여기에 모여요"
            )
        case .all:
            if selectedChip != .all {
                return (
                    "\(selectedChip.rawValue) 항목이 없어요",
                    "다른 카테고리를 선택하거나 상품을 추가해 보세요"
                )
            }
            return (
                "조건에 맞는 상품이 없어요",
                "필터를 바꿔보세요"
            )
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    topBar
                    segmentPicker
                    headerSummary
                    checkoutEntry
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                categoryBar
                    .padding(.top, 8)

                contentArea
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Spacer(minLength: 0)
            }
            .background(UCColor.bg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if selectedSegment == .wishlist {
                    wishlistShareButton
                }
            }
            .navigationDestination(item: $selectedItemID) { itemID in
                if let item = items.first(where: { $0.id == itemID }) {
                    ItemDetailView(
                        item: item,
                        ownerUserId: auth.currentUserId(),
                        onToggleListType: { toggleListType(for: itemID) },
                        onTapPrice: {
                            selectedItemID = nil
                            openPriceEditor(for: itemID)
                        },
                        onItemUpdated: { updated in
                            applyItemUpdate(updated)
                        }
                    )
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddItemSheet { newItem in
                let id = addOrUpdateItem(newItem)
                markJustAdded([id])
            }
        }
        .sheet(isPresented: $showingURLSheet) {
            AddFromURLSheet { newItem in
                let id = addOrUpdateItem(newItem)
                markJustAdded([id])
            }
        }
        .sheet(isPresented: $showingPriceSheet) {
            PriceInputSheet(
                title: priceSheetTitle,
                priceText: $priceInputText,
                onSave: savePrice,
                onCancel: closePriceSheet
            )
        }
        .sheet(isPresented: $showingShareWishlistSheet) {
            ShareWishlistSheet(shareProfile: $shareProfile)
        }
        .onAppear {
            loadStoredItemsIfNeeded()
            importPendingSharedItems()
            Task { await loadShareProfileIfNeeded() }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                importPendingSharedItems()
            }
        }
        .onChange(of: items) { _, newItems in
            guard didLoadStoredItems else { return }
            ItemStore.save(newItems)
            pushToCloudIfNeeded(newItems)
        }
        .onChange(of: auth.isAuthenticated) { _, isLoggedIn in
            if isLoggedIn, didLoadStoredItems {
                Task { await syncFromCloud() }
            }
            Task { await loadShareProfileIfNeeded() }
        }
        .onChange(of: selectedSegment) { _, segment in
            guard segment == .wishlist else { return }
            Task { await loadShareProfileIfNeeded() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .localItemsDidChange)) { _ in
            guard didLoadStoredItems, let stored = ItemStore.load() else { return }
            items = stored
        }
    }

    private func loadShareProfileIfNeeded() async {
        guard auth.isAuthenticated,
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
            auth.statusMessage = "공유 설정 불러오기 실패: \(error.localizedDescription)"
        }
    }

    private func pushToCloudIfNeeded(_ newItems: [Item]) {
        guard auth.isAuthenticated,
              let client = SupabaseService.shared.client,
              let userId = auth.currentUserId()
        else {
            return
        }

        Task {
            do {
                try await ItemSyncService.replaceAll(
                    client: client,
                    userId: userId,
                    items: newItems
                )
            } catch {
                await MainActor.run {
                    auth.statusMessage = "동기화 실패: \(error.localizedDescription)"
                }
            }
        }
    }

    private func syncFromCloud() async {
        guard !isSyncing,
              auth.isAuthenticated,
              let client = SupabaseService.shared.client,
              let userId = auth.currentUserId()
        else {
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        do {
            let remote = try await ItemSyncService.fetchItems(client: client, userId: userId)

            if remote.isEmpty, !items.isEmpty {
                try await ItemSyncService.replaceAll(
                    client: client,
                    userId: userId,
                    items: items
                )
            } else if !remote.isEmpty {
                items = remote
                ItemStore.save(remote)
            }
        } catch {
            auth.statusMessage = "불러오기 실패: \(error.localizedDescription)"
        }
    }

    private func sanitizeItems(_ source: [Item]) -> [Item] {
        source.map { item in
            var copy = item
            copy.imageURL = ImageURLNormalizer.resolve(item.imageURL)
            return copy
        }
    }

    private func loadStoredItemsIfNeeded() {
        guard !didLoadStoredItems else { return }
        didLoadStoredItems = true

        if let stored = ItemStore.load(), !stored.isEmpty {
            items = sanitizeItems(stored)
        } else {
            items = DummyItems.sample
            ItemStore.save(items)
        }
    }

    private func importPendingSharedItems() {
        let pending = SharedItemStore.loadPending()
        guard !pending.isEmpty else { return }

        var touchedIDs: [UUID] = []
        for shared in pending {
            let incoming = Item(
                id: shared.id,
                title: shared.title,
                imageURL: ImageURLNormalizer.resolve(shared.imageURL),
                price: shared.price,
                productURL: shared.productURL,
                mall: shared.mall,
                category: shared.category,
                listType: shared.listType
            )
            touchedIDs.append(addOrUpdateItem(incoming))
        }

        markJustAdded(touchedIDs)
        SharedItemStore.clearPending()
    }

    @discardableResult
    private func addOrUpdateItem(_ incoming: Item) -> UUID {
        var item = incoming
        item.imageURL = ImageURLNormalizer.resolve(incoming.imageURL)
        return ItemUpsert.apply(item, to: &items, moveUpdatedToTop: true)
    }

    private func applyItemUpdate(_ updated: Item) {
        guard let index = items.firstIndex(where: { $0.id == updated.id }) else { return }
        items[index] = updated
        ItemStore.save(items)
        pushToCloudIfNeeded(items)
    }

    private func markJustAdded(_ ids: [UUID]) {
        guard !ids.isEmpty else { return }
        justAddedItemIDs.formUnion(ids)

        Task {
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            await MainActor.run {
                justAddedItemIDs.subtract(ids)
            }
        }
    }

    private var priceSheetTitle: String {
        guard let id = priceEditingItemID,
              let item = items.first(where: { $0.id == id }) else {
            return "가격 입력"
        }
        return item.title
    }

    private var topBar: some View {
        HStack {
            Text("Universe Cart")
                .font(.title3.bold())
                .foregroundStyle(UCColor.textPrimary)

            Spacer()

            Menu {
                Button {
                    showingURLSheet = true
                } label: {
                    Label("링크로 담기", systemImage: "link")
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Label("직접 입력", systemImage: "square.and.pencil")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(UCColor.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(UCColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
            .accessibilityLabel("상품 담기")

            Button {
                isGrid.toggle()
            } label: {
                Image(systemName: isGrid ? "list.bullet" : "square.grid.2x2")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(UCColor.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(UCColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 7))
            }
        }
    }

    private var segmentPicker: some View {
        HStack(spacing: 4) {
            ForEach(HomeSegment.allCases, id: \.self) { segment in
                Button {
                    selectedSegment = segment
                } label: {
                    Text(segment.rawValue)
                        .font(.caption)
                        .fontWeight(selectedSegment == segment ? .semibold : .regular)
                        .foregroundStyle(
                            selectedSegment == segment ? UCColor.bg : UCColor.textPrimary
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: UCButtonMetrics.segmentHeight)
                        .background(
                            selectedSegment == segment ? UCColor.textPrimary : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: UCButtonMetrics.segmentCornerRadius))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var headerSummary: some View {
        switch selectedSegment {
        case .wishlist:
            wishlistSummaryBar
        default:
            summaryBar
        }
    }

    private var wishlistSummaryBar: some View {
        HStack(spacing: 6) {
            summaryMetric(label: "위시 아이템", value: "\(wishlistItems.count)", suffix: "개")
            summaryDot
            summaryMetric(label: "공개", value: "\(wishlistPublicCount)", suffix: "개")
            summaryDot
            summaryMetric(label: "비공개", value: "\(wishlistPrivateCount)", suffix: "개")
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(12)
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }

    private var wishlistShareButton: some View {
        UCPrimaryCTA("위시리스트 공유하기", systemImage: "square.and.arrow.up") {
            showingShareWishlistSheet = true
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(UCColor.bg)
    }

    @ViewBuilder
    private var checkoutEntry: some View {
        if selectedSegment != .wishlist, !cartItems.isEmpty {
            NavigationLink {
                CheckoutView(cartItems: cartItems)
            } label: {
                HStack {
                    Text("쇼핑몰별 결제")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("\(cartItems.count)개")
                        .font(.caption)
                        .foregroundStyle(UCColor.textSecond)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(UCColor.textSecond)
                }
                .foregroundStyle(UCColor.textPrimary)
                .padding(12)
                .background(UCColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(UCColor.border, lineWidth: 1)
                )
            }
        }
    }

    private var summaryBar: some View {
        HStack(spacing: 6) {
            summaryMetric(label: "담은 것", value: "\(totalCount)", suffix: "개")
            summaryDot
            summaryMetric(label: "합계", value: currency(totalPrice))
            summaryDot
            summaryMetric(label: "위시", value: "\(wishlistCount)", suffix: "개")
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(12)
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }

    private var summaryDot: some View {
        Text("·")
            .font(.subheadline)
            .foregroundStyle(UCColor.textDisabled)
    }

    private func summaryMetric(label: String, value: String, suffix: String? = nil) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(UCColor.textSecond)

            HStack(spacing: 0) {
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundStyle(UCColor.textPrimary)

                if let suffix {
                    Text(suffix)
                        .fontWeight(.semibold)
                        .foregroundStyle(UCColor.textPrimary)
                }
            }
        }
        .font(.subheadline)
    }

    private var categoryBar: some View {
        let chips = CategoryChip.allCases
        let horizontalInset: CGFloat = 8
        let weightSum = chips.map(\.layoutWeight).reduce(0, +)

        return GeometryReader { geo in
            let width = geo.size.width
            let dividerPositions = categoryBarDividerPositions(
                width: width,
                chips: chips,
                weightSum: weightSum
            )

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    ForEach(chips, id: \.self) { chip in
                        categoryBarButton(chip)
                            .frame(width: width * chip.layoutWeight / weightSum)
                    }
                }

                ForEach(Array(dividerPositions.enumerated()), id: \.offset) { _, x in
                    Text("|")
                        .font(.caption)
                        .foregroundStyle(UCColor.gray300)
                        .position(x: x, y: geo.size.height / 2)
                }
            }
        }
        .padding(.horizontal, horizontalInset)
        .frame(height: 40)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(UCColor.border)
                .frame(height: 1)
        }
    }

    private func categoryBarDividerPositions(
        width: CGFloat,
        chips: [CategoryChip],
        weightSum: CGFloat
    ) -> [CGFloat] {
        var positions: [CGFloat] = []
        var cumulative: CGFloat = 0

        for index in 0..<chips.count - 1 {
            cumulative += width * chips[index].layoutWeight / weightSum
            positions.append(cumulative)
        }

        return positions
    }

    private func categoryBarButton(_ chip: CategoryChip) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedChip = chip
            }
        } label: {
            Text(chip.rawValue)
                .font(.caption2)
                .fontWeight(selectedChip == chip ? .semibold : .regular)
                .foregroundStyle(selectedChip == chip ? UCColor.textPrimary : UCColor.textSecond)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var emptyStateView: some View {
        let message = emptyStateMessage

        return VStack(spacing: 8) {
            Text(message.title)
                .font(.headline)
                .foregroundStyle(UCColor.textPrimary)

            Text(message.subtitle)
                .font(.subheadline)
                .foregroundStyle(UCColor.textSecond)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 48)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var contentArea: some View {
        if filteredItems.isEmpty {
            emptyStateView
        } else if isGrid {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredItems) { item in
                        GridCard(
                            item: item,
                            showJustAdded: justAddedItemIDs.contains(item.id),
                            showWishOnThumbnail: selectedSegment == .all && item.listType == .wishlist,
                            onOpen: { selectedItemID = item.id },
                            onTapPrice: { openPriceEditor(for: item.id) }
                        )
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
        } else {
            List {
                ForEach(filteredItems) { item in
                    ListRow(
                        item: item,
                        showJustAdded: justAddedItemIDs.contains(item.id),
                        showWishOnThumbnail: selectedSegment == .all && item.listType == .wishlist,
                        onOpen: { selectedItemID = item.id },
                        onToggleListType: { toggleListType(for: item.id) },
                        onTapPrice: { openPriceEditor(for: item.id) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: deleteItems)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func toggleListType(for id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].listType = items[index].listType == .wishlist ? .cart : .wishlist
    }

    private func openPriceEditor(for id: UUID) {
        priceEditingItemID = id
        if let item = items.first(where: { $0.id == id }), let price = item.price {
            priceInputText = "\(price)"
        } else {
            priceInputText = ""
        }
        showingPriceSheet = true
    }

    private func savePrice() {
        guard let id = priceEditingItemID,
              let index = items.firstIndex(where: { $0.id == id }) else { return }

        let digits = priceInputText.filter(\.isNumber)
        guard let price = Int(digits), price > 0 else { return }

        items[index].price = price
        closePriceSheet()
    }

    private func closePriceSheet() {
        showingPriceSheet = false
        priceEditingItemID = nil
        priceInputText = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        let targets = offsets.map { filteredItems[$0].id }
        items.removeAll { targets.contains($0.id) }
        justAddedItemIDs.subtract(targets)
    }

    private func currency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}

/// 리스트·그리드 공통 — 위시 ↔ 장바구니 전환
private struct ListTypeToggleButton: View {
    let item: Item
    let showWishOnThumbnail: Bool
    let action: () -> Void

    private var iconName: String {
        if showWishOnThumbnail {
            return "cart"
        }
        return item.listType == .wishlist ? "heart.fill" : "heart"
    }

    private var iconColor: Color {
        if showWishOnThumbnail {
            return UCColor.textSecond
        }
        return item.listType == .wishlist ? UCColor.accent : UCColor.textDisabled
    }

    private var accessibilityText: String {
        if showWishOnThumbnail {
            return "장바구니로 옮기기"
        }
        return item.listType == .wishlist ? "위시리스트에서 제거" : "위시리스트에 담기"
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.body)
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
    }
}

private struct JustAddedBadge: View {
    var body: some View {
        Text("방금 담음")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(UCColor.textPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(UCColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(UCColor.border, lineWidth: 1)
            )
    }
}

private enum ListRowLayout {
    static let thumbnailSize: CGFloat = 68
    static let metaRowHeight: CGFloat = 22
    static let titleHeight: CGFloat = 40
    static let priceRowHeight: CGFloat = 22
    static let textSpacing: CGFloat = 4
    static let padding: CGFloat = 12

    static var infoHeight: CGFloat {
        metaRowHeight + titleHeight + priceRowHeight + textSpacing * 2
    }

    static var rowHeight: CGFloat {
        max(thumbnailSize, infoHeight) + padding * 2
    }
}

private struct ListRow: View {
    let item: Item
    let showJustAdded: Bool
    let showWishOnThumbnail: Bool
    let onOpen: () -> Void
    let onToggleListType: () -> Void
    let onTapPrice: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ProductThumbnailView(
                imageURL: item.imageURL,
                mall: item.mall,
                productPageURL: item.productURL,
                showsWishIndicator: showWishOnThumbnail
            )
            .frame(width: ListRowLayout.thumbnailSize, height: ListRowLayout.thumbnailSize)
            .clipped()

            VStack(alignment: .leading, spacing: ListRowLayout.textSpacing) {
                HStack(spacing: 6) {
                    MallBadge(mall: item.mall)

                    Text(item.category.displayName)
                        .font(.caption)
                        .foregroundStyle(UCColor.textSecond)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if showJustAdded {
                        JustAddedBadge()
                    }
                }
                .padding(.top, 2)
                .frame(minHeight: ListRowLayout.metaRowHeight, alignment: .leading)

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UCColor.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: ListRowLayout.titleHeight,
                        maxHeight: ListRowLayout.titleHeight,
                        alignment: .topLeading
                    )

                Group {
                    if let price = item.price {
                        Text(currency(price))
                            .font(.footnote)
                            .foregroundStyle(UCColor.textPrimary)
                    } else {
                        Button(action: onTapPrice) {
                            Text("가격 입력하기")
                                .font(.footnote)
                                .foregroundStyle(UCColor.textSecond)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: ListRowLayout.priceRowHeight,
                    maxHeight: ListRowLayout.priceRowHeight,
                    alignment: .leading
                )
            }
            .frame(minHeight: ListRowLayout.infoHeight, alignment: .top)
            .layoutPriority(1)

            ListTypeToggleButton(
                item: item,
                showWishOnThumbnail: showWishOnThumbnail,
                action: onToggleListType
            )
            .frame(height: ListRowLayout.thumbnailSize, alignment: .center)
        }
        .padding(ListRowLayout.padding)
        .frame(maxWidth: .infinity, minHeight: ListRowLayout.rowHeight, alignment: .topLeading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UCColor.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }

    private func currency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}

private enum GridCardLayout {
    static let metaRowHeight: CGFloat = 22
    static let titleHeight: CGFloat = 40
    static let priceRowHeight: CGFloat = 22
    static let imageToMetaSpacing: CGFloat = 16
    static let metaToTitleSpacing: CGFloat = 10
    static let titleToPriceSpacing: CGFloat = 10
    static let padding: CGFloat = 12
}

private struct GridCard: View {
    let item: Item
    let showJustAdded: Bool
    let showWishOnThumbnail: Bool
    let onOpen: () -> Void
    let onTapPrice: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                ProductThumbnailView(
                    imageURL: item.imageURL,
                    mall: item.mall,
                    productPageURL: item.productURL,
                    cornerRadius: 4,
                    showsWishIndicator: showWishOnThumbnail
                )

                if showJustAdded {
                    VStack {
                        HStack {
                            JustAddedBadge()
                            Spacer(minLength: 0)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(6)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipped()

            HStack(spacing: 6) {
                mallMark

                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(UCColor.textSecond)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)
            }
            .padding(.top, GridCardLayout.imageToMetaSpacing)
            .frame(minHeight: GridCardLayout.metaRowHeight, alignment: .leading)

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UCColor.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .padding(.top, GridCardLayout.metaToTitleSpacing)
                .frame(maxWidth: .infinity, minHeight: GridCardLayout.titleHeight, alignment: .topLeading)

            Group {
                if let price = item.price {
                    Text(currency(price))
                        .font(.footnote)
                        .foregroundStyle(UCColor.textPrimary)
                } else {
                    Button(action: onTapPrice) {
                        Text("가격 입력하기")
                            .font(.footnote)
                            .foregroundStyle(UCColor.textSecond)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, GridCardLayout.titleToPriceSpacing)
            .frame(
                maxWidth: .infinity,
                minHeight: GridCardLayout.priceRowHeight,
                maxHeight: GridCardLayout.priceRowHeight,
                alignment: .leading
            )
        }
        .padding(GridCardLayout.padding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UCColor.border, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
    }

    @ViewBuilder
    private var mallMark: some View {
        if item.mall.logoAssetName != nil {
            MallBadge(mall: item.mall)
                .frame(width: 19, height: 19)
        } else {
            MallBadge(mall: item.mall)
        }
    }

    private func currency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}

private struct AddFromURLSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var urlText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var noticeMessage: String?
    @State private var fetchedTitle = ""
    @State private var fetchedImageURL: String?
    @State private var priceText = ""
    @State private var detectedMall: Mall = .etc
    @State private var hasFetched = false
    @State private var selectedCategory: Category = .fashion
    @State private var selectedListType: ListType = .wishlist

    let onSave: (Item) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://...", text: $urlText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)

                    Button {
                        Task { await fetchProduct() }
                    } label: {
                        if isLoading {
                            HStack {
                                ProgressView()
                                Text("불러오는 중...")
                            }
                        } else {
                            Text("상품 정보 가져오기")
                        }
                    }
                    .disabled(urlText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                } header: {
                    Text("상품 링크")
                } footer: {
                    Text("쇼핑몰에서 복사한 상품 URL을 붙여넣으면 이미지·가격을 자동으로 가져와요.")
                        .font(.caption)
                }

                if let noticeMessage {
                    Section {
                        Text(noticeMessage)
                            .font(.subheadline)
                            .foregroundStyle(UCColor.textSecond)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if hasFetched {
                    Section {
                        ItemPreviewCard(item: previewItem)
                    } header: {
                        Text("미리보기")
                    } footer: {
                        Text("이미지가 비어 있으면 쇼핑몰에서 막았을 수 있어요. 그래도 담을 수 있어요.")
                            .font(.caption)
                    }

                    Section("가격·분류") {
                        TextField("가격(숫자만)", text: $priceText)
                            .keyboardType(.numberPad)
                        Picker("카테고리", selection: $selectedCategory) {
                            ForEach(Category.allCases, id: \.self) { category in
                                Text(category.displayName).tag(category)
                            }
                        }

                        Picker("담을 곳", selection: $selectedListType) {
                            ForEach(ListType.selectableCases, id: \.self) { listType in
                                Text(listType.displayName).tag(listType)
                            }
                        }
                    }
                }
            }
            .ucSheetNavigationTitle("링크로 담기")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("담기") {
                        saveItem()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private var previewItem: Item {
        Item(
            id: UUID(),
            title: fetchedTitle,
            imageURL: fetchedImageURL,
            price: Int(priceText.filter(\.isNumber)),
            productURL: urlText,
            mall: detectedMall,
            category: selectedCategory,
            listType: selectedListType
        )
    }

    private var canSave: Bool {
        hasFetched && !fetchedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func fetchProduct() async {
        errorMessage = nil
        noticeMessage = nil
        hasFetched = false
        isLoading = true
        defer { isLoading = false }

        guard let url = normalizedURL(from: urlText) else {
            errorMessage = "올바른 URL을 입력해 주세요."
            return
        }

        urlText = url.absoluteString
        let result = await OGMetadataExtractor.fetch(from: url)
        let metadata = result.metadata

        fetchedTitle = metadata.title ?? url.host ?? "공유 상품"
        fetchedImageURL = ImageURLNormalizer.resolve(metadata.imageURL)
        detectedMall = MallDetector.detect(from: url)
        selectedCategory = detectedMall.defaultCategory

        if let price = metadata.price {
            priceText = "\(price)"
        } else {
            priceText = ""
        }

        hasFetched = true

        if let message = result.displayMessage {
            if result.isHardFailure {
                errorMessage = message
            } else {
                noticeMessage = message
            }
        }
    }

    private func saveItem() {
        guard let url = normalizedURL(from: urlText) else { return }

        let digits = priceText.filter(\.isNumber)
        let price = Int(digits).flatMap { $0 > 0 ? $0 : nil }

        let newItem = Item(
            id: UUID(),
            title: fetchedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: ImageURLNormalizer.resolve(fetchedImageURL),
            price: price,
            productURL: url.absoluteString,
            mall: detectedMall,
            category: selectedCategory,
            listType: selectedListType
        )

        onSave(newItem)
        dismiss()
    }

    private func normalizedURL(from text: String) -> URL? {
        ProductURLNormalizer.normalize(text)
    }
}

private struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var priceText: String = ""
    @State private var productURLText: String = ""
    @State private var selectedMall: Mall = .cm29
    @State private var selectedCategory: Category = .fashion
    @State private var selectedListType: ListType = .wishlist

    let onSave: (Item) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("링크 없이 기억나는 정보만 적어 담을 수 있어요. 쇼핑몰에서 ‘공유’하거나 ‘링크로 담기’가 더 편해요.")
                        .font(.subheadline)
                        .foregroundStyle(UCColor.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                } header: {
                    Text("직접 입력이란?")
                }

                Section("상품 정보") {
                    TextField("상품명", text: $title)
                    TextField("가격(숫자만)", text: $priceText)
                        .keyboardType(.numberPad)
                    TextField("상품 링크 (선택)", text: $productURLText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                }

                Section("분류") {
                    Picker("몰", selection: $selectedMall) {
                        ForEach(Mall.allCases, id: \.self) { mall in
                            Text(mall.displayName).tag(mall)
                        }
                    }

                    Picker("카테고리", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }

                    Picker("담을 곳", selection: $selectedListType) {
                        ForEach(ListType.selectableCases, id: \.self) { listType in
                            Text(listType.displayName).tag(listType)
                        }
                    }
                }
            }
            .ucSheetNavigationTitle("직접 입력")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        saveManualItem()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: selectedMall) { _, mall in
                selectedCategory = mall.defaultCategory
            }
        }
    }

    private func saveManualItem() {
        let trimmedURL = productURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        let productURL: String
        if let normalized = ProductURLNormalizer.canonicalString(from: trimmedURL), !trimmedURL.isEmpty {
            productURL = normalized
        } else {
            productURL = "universecart://manual/\(UUID().uuidString)"
        }

        let digits = priceText.filter(\.isNumber)
        let price = Int(digits).flatMap { $0 > 0 ? $0 : nil }

        let newItem = Item(
            id: UUID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            imageURL: nil,
            price: price,
            productURL: productURL,
            mall: selectedMall,
            category: selectedCategory,
            listType: selectedListType
        )
        onSave(newItem)
        dismiss()
    }
}

private struct PriceInputSheet: View {
    let title: String
    @Binding var priceText: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("상품") {
                    Text(title)
                        .foregroundStyle(UCColor.textSecond)
                }

                Section("가격") {
                    TextField("가격(숫자만)", text: $priceText)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("가격 입력")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소", action: onCancel)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장", action: onSave)
                        .disabled(Int(priceText.filter(\.isNumber)) ?? 0 <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
