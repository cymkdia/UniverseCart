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

    var mappedCategory: Category? {
        switch self {
        case .all: return nil
        case .fashion: return .fashion
        case .home: return .home
        case .food: return .food
        }
    }
}

struct MainListView: View {
    @State private var items: [Item] = DummyItems.sample
    @State private var selectedSegment: HomeSegment = .all
    @State private var selectedChip: CategoryChip = .all
    @State private var isGrid = false

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
    }

    private var topBar: some View {
        HStack {
            Text("Universe Cart")
                .font(.title3.bold())
                .foregroundStyle(UCTheme.textPrimary)

            Spacer()

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

    private var segmentPicker: some View {
        Picker("세그먼트", selection: $selectedSegment) {
            ForEach(HomeSegment.allCases, id: \.self) { segment in
                Text(segment.rawValue).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }

    private var summaryBar: some View {
        HStack(spacing: 8) {
            Text("담은 것 \(totalCount)개")
            Text("·")
            Text("합계 \(currency(totalPrice))")
            Text("·")
            Text("위시 \(wishlistCount)개")
        }
        .font(.subheadline)
        .foregroundStyle(UCTheme.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(UCTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(UCTheme.border, lineWidth: 1)
        )
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

    @ViewBuilder
    private var contentArea: some View {
        if isGrid {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(filteredItems) { item in
                        GridCard(item: item)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
        } else {
            List {
                ForEach(filteredItems) { item in
                    ListRow(item: item)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private func currency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}

private struct ListRow: View {
    let item: Item

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

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(UCTheme.mallColor(item.mall))
                        .frame(width: 8, height: 8)

                    Text("\(item.mall.displayName) · \(item.category.displayName)")
                        .font(.caption)
                        .foregroundStyle(UCTheme.textSecondary)
                }

                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UCTheme.textPrimary)
                    .lineLimit(2)

                if let price = item.price {
                    HStack(spacing: 6) {
                        if item.mall == .wconcept {
                            Text("₩\(Int(Double(price) * 1.2))")
                                .font(.caption)
                                .foregroundStyle(UCTheme.textLight)
                                .strikethrough()
                        }
                        Text(currency(price))
                            .font(.subheadline.bold())
                            .foregroundStyle(UCTheme.textPrimary)
                    }
                } else {
                    Text("가격 입력하기")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(UCTheme.textSecondary)
                }
            }

            Spacer()

            Image(systemName: item.listType == .wishlist ? "heart.fill" : "heart")
                .foregroundStyle(item.listType == .wishlist ? .pink : UCTheme.textLight)
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

            Text(item.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UCTheme.textPrimary)
                .lineLimit(2)

            if let price = item.price {
                Text(currency(price))
                    .font(.subheadline.bold())
                    .foregroundStyle(UCTheme.textPrimary)
            } else {
                Text("가격 입력하기")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(UCTheme.textSecondary)
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
