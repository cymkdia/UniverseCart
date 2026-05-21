import SwiftUI

enum ComparePriceTrend {
    case current
    case lower
    case higher
}

struct MallPriceCompareRow: Identifiable {
    let id = UUID()
    let mall: Mall
    let price: Int
    let trend: ComparePriceTrend
}

enum ItemDetailSampleData {
    static let sizes = ["XS", "S", "M", "L", "XL"]

    static func compareRows(for item: Item) -> [MallPriceCompareRow] {
        guard let base = item.price else {
            return [
                MallPriceCompareRow(mall: item.mall, price: 0, trend: .current)
            ]
        }

        let others = Mall.allCases.filter { $0 != item.mall }.prefix(2)
        var rows: [MallPriceCompareRow] = [
            MallPriceCompareRow(mall: item.mall, price: base, trend: .current)
        ]

        let offsets: [Double] = [0.96, 1.03]
        for (index, mall) in others.enumerated() {
            let offset = offsets[index % offsets.count]
            let price = Int(Double(base) * offset)
            let trend: ComparePriceTrend
            if price < base {
                trend = .lower
            } else if price > base {
                trend = .higher
            } else {
                trend = .current
            }
            rows.append(MallPriceCompareRow(mall: mall, price: price, trend: trend))
        }

        return rows.sorted { lhs, rhs in
            if lhs.trend == .current { return true }
            if rhs.trend == .current { return false }
            return lhs.price < rhs.price
        }
    }

    static func fundingProgress(for item: Item) -> Double {
        guard let price = item.price, price > 0 else { return 0 }
        let seed = abs(item.id.hashValue) % 55
        return Double(20 + seed) / 100.0
    }

    static func fundingCollected(for item: Item) -> Int {
        guard let price = item.price else { return 0 }
        return Int(Double(price) * fundingProgress(for: item))
    }
}

struct DetailSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(UCColor.textSecond)
            .textCase(.uppercase)
            .kerning(0.5)
    }
}
