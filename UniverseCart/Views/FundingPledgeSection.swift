import SwiftUI

/// 위시 상품 상세 — 약속 펀딩 + 코디네이션 (상태별 UI)
struct FundingPledgeSection: View {
    @Environment(\.openURL) private var openURL

    let item: Item
    let context: FundingCoordinationContext
    var isLoading: Bool = false
    var pledgeWebURL: URL?
    var isShareEnabled: Bool = false
    var currentUserId: UUID?
    var ownerUserId: UUID?

    var onVolunteerAsBuyer: () -> Void = {}
    var onOpenSettlement: () -> Void = {}
    var onMarkPurchased: () -> Void = {}
    var onMarkReceived: () -> Void = {}

    private var effectiveState: FundingCoordinationState {
        context.effectiveState
    }

    private var isOwner: Bool {
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
        context.isGoalMet ? UCColor.funding.opacity(0.15) : UCColor.border.opacity(0.35)
    }

    @ViewBuilder
    private var stateContent: some View {
        Text(effectiveState.statusMessage)
            .font(.footnote)
            .foregroundStyle(UCColor.textSecond)

        switch effectiveState {
        case .collecting:
            if context.summary.pledges.isEmpty {
                Text("아직 약속이 없어요. 위시리스트 링크를 공유해 보세요.")
                    .font(.footnote)
                    .foregroundStyle(UCColor.textSecond)
            } else {
                progressBlock
                participantList
            }

        case .goalReached:
            progressBlock
            participantList
            if isParticipant, !isOwner {
                Text("참여자라면 「내가 대표로 살게요」를 눌러 구매를 맡아 주세요.")
                    .font(.caption)
                    .foregroundStyle(UCColor.fundingText)
            } else if isOwner {
                Text("참여자 중 대표 구매자를 기다리는 중이에요.")
                    .font(.caption)
                    .foregroundStyle(UCColor.textSecond)
            }

        case .buyerAssigned, .purchased:
            progressBlock
            participantList

        case .received:
            progressBlock
            if let message = context.record?.thankYouMessage, !message.isEmpty {
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
            pledgeWebButton

        case .goalReached:
            if isParticipant, !isOwner {
                UCPrimaryCTA("내가 대표로 살게요", systemImage: "hand.raised") {
                    onVolunteerAsBuyer()
                }
            }
            pledgeWebButton

        case .buyerAssigned:
            if context.record?.hasSettlementAccount == true {
                UCPrimaryCTA("정산 안내 보기", systemImage: "wonsign.circle") {
                    onOpenSettlement()
                }
            }
            if isBuyer {
                UCSecondaryCTA(title: "구매 완료") {
                    onMarkPurchased()
                }
            }

        case .purchased:
            if isOwner {
                UCPrimaryCTA("선물 받음", systemImage: "gift.fill") {
                    onMarkReceived()
                }
            } else if context.record?.hasSettlementAccount == true {
                UCSecondaryCTA(title: "정산 안내 보기") {
                    onOpenSettlement()
                }
            }

        case .received:
            EmptyView()
        }
    }

    @ViewBuilder
    private var pledgeWebButton: some View {
        if isShareEnabled, let pledgeWebURL {
            UCSecondaryCTA(title: "같이 선물하기") {
                openURL(pledgeWebURL)
            }
        } else if !isShareEnabled {
            Text("프로필에서 위시리스트 공개를 켜면 같이 선물하기 페이지를 열 수 있어요.")
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
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
