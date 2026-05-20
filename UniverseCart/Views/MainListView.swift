import SwiftUI

enum HomeSegment: String, CaseIterable {
    case all = "전체"
    case wishlist = "위시리스트"
    case cart = "내 장바구니"
}

enum CategoryChip: String, CaseIterable {
    case all = "전체"
    case fashion = "패션"
    case home = "홈리빙"
    case food = "식품"
    case beauty = "뷰티"

    var mappedCategory: Category? {
        switch self {
        case .all: return nil
        case .fashion: return .fashion
        case .home: return .home
        case .food: return .food
        case .beauty: return .beauty
        }
    }
}

struct MainListView: View {
    @Environment(\.scenePhase) private var scenePhase

    @State private var items: [Item] = DummyItems.sample
    @State private var selectedSegment: HomeSegment = .all
    @State private var selectedChip: CategoryChip = .all
    @State private var isGrid = false
    @State private var showingAddSheet = false
    @State private var showingPriceSheet = false
    @State private var priceEditingItemID: UUID?
    @State private var priceInputText = ""

    private var filteredItems: [Item] {
        items.filter { item in
            let segmentPass: Bool = {
                switch selectedSegment {
                case .all: return true
                case .wishlist: return item.listType == .wishlist
                case .cart: return item.listType == .cart
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
            VStack(spacing: 12) {
                topBar
                segmentPicker
                summaryBar
                categoryChips
                contentArea
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .background(UCTheme.background.ignoresSafeArea())
        }
        .sheet(isPresented: $showingAddSheet) {
            AddItemSheet { newItem in
                items.insert(newItem, at: 0)
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
        .onAppear {
            importPendingSharedItems()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                importPendingSharedItems()
            }
        }
    }

    private func importPendingSharedItems() {
        let pending = SharedItemStore.loadPending()
        guard !pending.isEmpty else { return }

        let imported = pending.map { shared in
            Item(
                id: shared.id,
                title: shared.title,
                imageURL: shared.imageURL,
                price: nil,
                productURL: shared.productURL,
                mall: shared.mall,
                category: shared.category,
                listType: shared.listType
            )
        }

        items.insert(contentsOf: imported, at: 0)
        SharedItemStore.clearPending()
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
                .foregroundStyle(UCTheme.textPrimary)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(UCTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(UCTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }

                Button {
                    isGrid.toggle()
                } label: {
                    Image(systemName: isGrid ? "list.bullet" : "square.grid.2x2")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(UCTheme.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(UCTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
        }
    }

    private var segmentPicker: some View {
        Picker("세그먼트", selection: $selectedSegment) {
            ForEach(HomeSegment.allCases, id: \.self) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryBar: some View {
        HStack(spacing: 6) {
            summaryMetric(label: "담은 것", value: "\(totalCount)", suffix: "개")
            summaryDot
            summaryMetric(label: "합계", value: currency(totalPrice))
            summaryDot
            summaryMetric(label: "위시", value: "\(wishlistCount)", suffix: "개")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(UCTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UCTheme.border, lineWidth: 1)
        )
    }

    private var summaryDot: some View {
        Text("·")
            .font(.subheadline)
            .foregroundStyle(UCTheme.textLight)
    }

    private func summaryMetric(label: String, value: String, suffix: String? = nil) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .foregroundStyle(UCTheme.textSecondary)

            HStack(spacing: 0) {
                Text(value)
                    .fontWeight(.semibold)
                    .foregroundStyle(UCTheme.textPrimary)

                if let suffix {
                    Text(suffix)
                        .fontWeight(.semibold)
                        .foregroundStyle(UCTheme.textPrimary)
                }
            }
        }
        .font(.subheadline)
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CategoryChip.allCases, id: \.self) { chip in
                    Button {
                        selectedChip = chip
                    } label: {
                        Text(chip.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(selectedChip == chip ? UCTheme.background : UCTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedChip == chip ? UCTheme.textPrimary : UCTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(UCTheme.border, lineWidth: selectedChip == chip ? 0 : 1)
                            )
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        let message = emptyStateMessage

        return VStack(spacing: 8) {
            Text(message.title)
                .font(.headline)
                .foregroundStyle(UCTheme.textPrimary)

            Text(message.subtitle)
                .font(.subheadline)
                .foregroundStyle(UCTheme.textSecondary)
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
                        onToggleListType: { toggleListType(for: item.id) },
                        onTapPrice: { openPriceEditor(for: item.id) }
                    )
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
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
    }

    private func currency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}

private struct MallBadge: View {
    let mall: Mall

    var body: some View {
        if let assetName = mall.logoAssetName {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(UCTheme.border, lineWidth: 1)
                )
                .accessibilityLabel(mall.displayName)
        } else {
            Text(mall.displayName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(UCTheme.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(UCTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(UCTheme.border, lineWidth: 1)
                )
        }
    }
}

private struct ListRow: View {
    let item: Item
    let onToggleListType: () -> Void
    let onTapPrice: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(UCTheme.surface)
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(UCTheme.border, lineWidth: 1)
                    )

                if item.listType == .wishlist {
                    Text("★")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                        .padding(4)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    MallBadge(mall: item.mall)

                    Text(item.category.displayName)
                        .font(.caption)
                        .foregroundStyle(UCTheme.textSecondary)
                }

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UCTheme.textPrimary)
                    .lineLimit(2)

                if let price = item.price {
                    Text(currency(price))
                        .font(.subheadline.bold())
                        .foregroundStyle(UCTheme.textPrimary)
                } else {
                    Button(action: onTapPrice) {
                        Text("가격 입력하기")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(UCTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Button(action: onToggleListType) {
                Image(systemName: item.listType == .wishlist ? "heart.fill" : "heart")
                    .foregroundStyle(item.listType == .wishlist ? .pink : UCTheme.textLight)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UCTheme.border, lineWidth: 1)
        )
    }

    private func currency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}

private struct GridCard: View {
    let item: Item
    let onTapPrice: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(UCTheme.surface)
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(UCTheme.border, lineWidth: 1)
                    )

                if item.listType == .wishlist {
                    Text("★")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                        .padding(6)
                }
            }

            HStack(spacing: 6) {
                MallBadge(mall: item.mall)

                Text(item.category.displayName)
                    .font(.caption)
                    .foregroundStyle(UCTheme.textSecondary)
            }

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UCTheme.textPrimary)
                .lineLimit(2)

            if let price = item.price {
                Text(currency(price))
                    .font(.subheadline.bold())
                    .foregroundStyle(UCTheme.textPrimary)
            } else {
                Button(action: onTapPrice) {
                    Text("가격 입력하기")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(UCTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UCTheme.border, lineWidth: 1)
        )
    }

    private func currency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}

private struct AddItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var priceText: String = ""
    @State private var selectedMall: Mall = .cm29
    @State private var selectedCategory: Category = .fashion
    @State private var selectedListType: ListType = .wishlist

    let onSave: (Item) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("상품 정보") {
                    TextField("상품명", text: $title)
                    TextField("가격(숫자만)", text: $priceText)
                        .keyboardType(.numberPad)
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
                        ForEach(ListType.allCases, id: \.self) { listType in
                            Text(listType.displayName).tag(listType)
                        }
                    }
                }
            }
            .navigationTitle("아이템 추가")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("저장") {
                        let newItem = Item(
                            id: UUID(),
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                            imageURL: nil,
                            price: Int(priceText.filter(\.isNumber)),
                            productURL: "https://example.com",
                            mall: selectedMall,
                            category: selectedCategory,
                            listType: selectedListType
                        )
                        onSave(newItem)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
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
                        .foregroundStyle(UCTheme.textSecondary)
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
