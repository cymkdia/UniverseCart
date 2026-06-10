import SwiftUI

/// 위시 상품 상세 — 약속 펀딩 현황 (읽기 전용, 참여는 웹)
struct FundingPledgeSection: View {
    @Environment(\.openURL) private var openURL

    let item: Item
    let summary: FundingPledgeSummary
    var isLoading: Bool = false
    var pledgeWebURL: URL?
    var isShareEnabled: Bool = false

    private var progress: Double? {
        summary.progress(for: item.price)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else if summary.pledges.isEmpty {
                emptyState
            } else {
                progressBlock
                participantList
            }

            pledgeWebAction

            disclaimer
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("약속 펀딩")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UCColor.textPrimary)

            Text("친구가 공유 웹에서 금액을 약속해요. UC는 결제를 받지 않아요.")
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
        }
    }

    private var emptyState: some View {
        Text("아직 약속이 없어요. 위시리스트 링크를 공유해 보세요.")
            .font(.footnote)
            .foregroundStyle(UCColor.textSecond)
    }

    @ViewBuilder
    private var progressBlock: some View {
        if let price = item.price, let progress {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("모인 약속")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(UCColor.textSecond)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.title3.bold())
                        .foregroundStyle(UCColor.textPrimary)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(UCColor.border.opacity(0.55))
                        Capsule()
                            .fill(UCColor.funding)
                            .frame(width: geometry.size.width * progress)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(formatPrice(summary.totalAmount)) 모였어요")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(UCColor.fundingText)
                    Spacer()
                    if let remaining = summary.remaining(for: price) {
                        Text("\(formatPrice(remaining)) 남았어요")
                            .font(.caption)
                            .foregroundStyle(UCColor.textSecond)
                    }
                }
            }
        } else {
            Text("\(formatPrice(summary.totalAmount)) · \(summary.participantCount)명 참여")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UCColor.textPrimary)
        }
    }

    private var participantList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("참여한 친구")
                .font(.caption.weight(.semibold))
                .foregroundStyle(UCColor.textSecond)

            ForEach(summary.pledges) { pledge in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(UCColor.border)
                        .frame(width: 28, height: 28)
                        .overlay {
                            Text(String(pledge.displayContributorName.prefix(1)))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(UCColor.textSecond)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(pledge.displayContributorName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(UCColor.textPrimary)

                        if let message = pledge.message, !message.isEmpty {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(UCColor.textSecond)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(formatPrice(pledge.amount))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(UCColor.textPrimary)
                }
                .padding(10)
                .background(UCColor.bg)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    @ViewBuilder
    private var pledgeWebAction: some View {
        if isShareEnabled, let pledgeWebURL {
            UCPrimaryCTA("같이 선물하기", systemImage: "gift") {
                openURL(pledgeWebURL)
            }
        } else if !isShareEnabled {
            Text("프로필에서 위시리스트 공개를 켜면 같이 선물하기 페이지를 열 수 있어요.")
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var disclaimer: some View {
        Text("실제 송금·구매는 카톡·계좌·쇼핑몰에서 진행해 주세요.")
            .font(.caption2)
            .foregroundStyle(UCColor.textDisabled)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func formatPrice(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "₩\(number)"
    }
}
