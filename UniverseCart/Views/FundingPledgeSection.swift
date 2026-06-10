import SwiftUI

/// 위시 상품 상세 — 약속 펀딩 + 코디네이션 (viewer × state 매트릭스)
struct FundingPledgeSection: View {
    @Environment(\.openURL) private var openURL

    let item: Item
    let context: FundingCoordinationContext
    var isLoading: Bool = false
    var pledgeWebURL: URL?
    var isShareEnabled: Bool = false
    var currentUserId: UUID?
    var ownerUserId: UUID?

    var onShareWishlist: () -> Void = {}
    var onVolunteerAsBuyer: () -> Void = {}
    var onOpenSettlement: () -> Void = {}
    var onMarkPurchased: () -> Void = {}
    var onMarkReceived: () -> Void = {}

    private var effectiveState: FundingCoordinationState {
        context.effectiveState
    }

    private var viewerIsOwner: Bool {
        guard let currentUserId, let ownerUserId else { return false }
        return currentUserId == ownerUserId
    }

    private var isBuyer: Bool {
        guard let currentUserId,
              let buyerId = context.record?.buyerUserId
        else { return false }
        return currentUserId == buyerId
    }

    private var isParticipant: Bool {
        guard let currentUserId else { return false }
        return context.summary.pledges.contains { $0.contributorUserId == currentUserId }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            stateBadge

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                stateContent
            }

            actionButtons
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

    private var stateBadge: some View {
        HStack {
            Text(effectiveState.displayTitle)
                .font(.caption.weight(.bold))
                .foregroundStyle(badgeForeground)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeBackground)
                .clipShape(Capsule())

            Spacer()

            if let progress = context.progress, context.isGoalMet {
                Text("100%")
                    .font(.title3.bold())
                    .foregroundStyle(UCColor.fundingText)
            } else if let progress = context.progress {
                Text("\(Int(progress * 100))%")
                    .font(.title3.bold())
            }
        }
    }

    private var badgeForeground: Color {
        context.isGoalMet ? UCColor.fundingText : UCColor.textSecond
    }

    private var badgeBackground: Color {
        context.isGoalMet ? UCColor.fundingSoft : UCColor.border.opacity(0.35)
    }

    private var viewerStatusMessage: String {
        switch effectiveState {
        case .collecting:
            return "친구들의 약속을 모으고 있어요."
        case .goalReached:
            if viewerIsOwner {
                return "친구 한 명이 대표로 구매할 차례예요"
            }
            return "약속 금액이 모였어요. 대표 구매자를 정해 주세요."
        case .buyerAssigned:
            return "참여자들이 대표에게 송금한 뒤, 대표가 구매해 주세요."
        case .purchased:
            if viewerIsOwner {
                return "곧 선물이 도착해요"
            }
            return "대표가 구매를 완료했어요. 선물을 받으면 확인해 주세요."
        case .received:
            if viewerIsOwner {
                return "받은 선물 아카이브에 보관됐어요"
            }
            return "선물을 받았어요."
        }
    }

    @ViewBuilder
    private var stateContent: some View {
        Text(viewerStatusMessage)
            .font(.footnote)
            .foregroundStyle(UCColor.textSecond)

        switch effectiveState {
        case .collecting:
            if context.summary.pledges.isEmpty {
                if viewerIsOwner {
                    Text("아직 약속이 없어요. 위시리스트를 공유해 보세요.")
                        .font(.footnote)
                        .foregroundStyle(UCColor.textSecond)
                } else {
                    Text("아직 약속이 없어요.")
                        .font(.footnote)
                        .foregroundStyle(UCColor.textSecond)
                }
            } else {
                progressBlock
                participantList
            }

        case .goalReached:
            progressBlock
            participantList
            if isParticipant, !viewerIsOwner {
                Text("참여자라면 「내가 대표로 살게요」를 눌러 구매를 맡아 주세요.")
                    .font(.caption)
                    .foregroundStyle(UCColor.fundingText)
            } else if viewerIsOwner {
                Text("대표를 기다리고 있어요")
                    .font(.caption)
                    .foregroundStyle(UCColor.textSecond)
            }

        case .buyerAssigned, .purchased:
            progressBlock
            participantList

        case .received:
            progressBlock
            if !viewerIsOwner,
               let message = context.record?.thankYouMessage,
               !message.isEmpty
            {
                Text("감사 메시지: \(message)")
                    .font(.caption)
                    .foregroundStyle(UCColor.textSecond)
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch effectiveState {
        case .collecting:
            if viewerIsOwner {
                ownerCollectingActions
            } else {
                friendCollectingActions
            }

        case .goalReached:
            if !viewerIsOwner, isParticipant {
                UCFundingCTA("내가 대표로 살게요", systemImage: "hand.raised") {
                    onVolunteerAsBuyer()
                }
            }

        case .buyerAssigned:
            if !viewerIsOwner, isBuyer {
                buyerAssignedActions
            }

        case .purchased:
            if viewerIsOwner {
                UCFundingCTA("선물 받음", systemImage: "gift.fill") {
                    onMarkReceived()
                }
            }

        case .received:
            EmptyView()
        }
    }

    @ViewBuilder
    private var ownerCollectingActions: some View {
        UCPrimaryCTA("위시리스트 공유하기", systemImage: "square.and.arrow.up") {
            onShareWishlist()
        }

        Text("친구들에게 공유해서 함께 모아보세요")
            .font(.caption)
            .foregroundStyle(UCColor.textSecond)
    }

    @ViewBuilder
    private var friendCollectingActions: some View {
        if isShareEnabled, let pledgeWebURL {
            UCPrimaryCTA("같이 선물하기", systemImage: "gift") {
                openURL(pledgeWebURL)
            }
        } else if !isShareEnabled {
            Text("위시리스트 공개가 꺼져 있어 같이 선물하기를 할 수 없어요.")
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
        }
    }

    @ViewBuilder
    private var buyerAssignedActions: some View {
        if context.record?.hasSettlementAccount == true {
            UCFundingCTA("정산 안내 보기", systemImage: "wonsign.circle") {
                onOpenSettlement()
            }
        }

        UCFundingCTA("구매 완료") {
            onMarkPurchased()
        }
    }

    @ViewBuilder
    private var progressBlock: some View {
        if let price = item.price, let progress = context.progress {
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(UCColor.border.opacity(0.55))
                        Capsule()
                            .fill(UCColor.funding)
                            .frame(width: geometry.size.width * min(progress, 1))
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("\(formatPrice(context.summary.totalAmount)) 모였어요")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(UCColor.fundingText)
                    Spacer()
                    if context.isGoalMet {
                        Text("목표 달성")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(UCColor.fundingText)
                    } else if let remaining = context.summary.remaining(for: price) {
                        Text("\(formatPrice(remaining)) 남았어요")
                            .font(.caption)
                            .foregroundStyle(UCColor.textSecond)
                    }
                }
            }
        } else if !context.summary.pledges.isEmpty {
            Text("\(formatPrice(context.summary.totalAmount)) · \(context.summary.participantCount)명 참여")
                .font(.subheadline.weight(.semibold))
        }
    }

    private var participantList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("참여한 친구")
                .font(.caption.weight(.semibold))
                .foregroundStyle(UCColor.textSecond)

            ForEach(context.summary.pledges) { pledge in
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
                        HStack(spacing: 4) {
                            Text(pledge.displayContributorName)
                                .font(.subheadline.weight(.semibold))
                            if pledge.contributorUserId == context.record?.buyerUserId {
                                Text("대표")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(UCColor.fundingText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(UCColor.fundingSoft)
                                    .clipShape(Capsule())
                            }
                        }

                        if let message = pledge.message, !message.isEmpty {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(UCColor.textSecond)
                        }
                    }

                    Spacer(minLength: 8)

                    Text(formatPrice(pledge.amount))
                        .font(.subheadline.weight(.bold))
                }
                .padding(10)
                .background(UCColor.bg)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private var disclaimer: some View {
        Text("실제 송금·구매는 카톡·계좌·쇼핑몰에서 진행해 주세요.")
            .font(.caption2)
            .foregroundStyle(UCColor.textDisabled)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func formatPrice(_ value: Int) -> String {
        RemittanceDeepLinkBuilder.formatPrice(value)
    }
}
