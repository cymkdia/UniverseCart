import SwiftUI

struct SettlementGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    let itemTitle: String
    let coordination: FundingCoordinationRecord
    let pledges: [FundingPledgeRecord]
    let buyerDisplayName: String
    let currentUserId: UUID?

    @State private var copiedFallbackMessage: String?

    private var contributorRows: [FundingPledgeRecord] {
        pledges.filter { $0.contributorUserId != coordination.ownerUserId }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    policyBanner

                    if coordination.hasSettlementAccount {
                        accountSummary
                    }

                    participantSection

                    if let shareText = settlementShareText {
                        ShareLink(item: shareText) {
                            Label("카카오톡으로 정산 안내 공유", systemImage: "square.and.arrow.up")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: UCButtonMetrics.actionHeight)
                                .background(UCColor.gray950)
                                .foregroundStyle(UCColor.bg)
                                .clipShape(RoundedRectangle(cornerRadius: UCButtonMetrics.cornerRadius))
                        }
                    }

                    if let copiedFallbackMessage {
                        Text(copiedFallbackMessage)
                            .font(.caption)
                            .foregroundStyle(UCColor.fundingText)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(20)
            }
            .background(UCColor.bg)
            .navigationTitle("정산 안내")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") { dismiss() }
                }
            }
        }
    }

    private var policyBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("UC는 결제·송금을 처리하지 않아요")
                .font(.subheadline.weight(.semibold))
            Text("아래 버튼으로 카카오페이·토스 앱에서 직접 송금해 주세요. UC는 자금을 보관하지 않습니다.")
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UCColor.fundingSoft)
        .clipShape(RoundedRectangle(cornerRadius: UCRadius.md))
    }

    private var accountSummary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("대표 구매자 · \(buyerDisplayName)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(UCColor.textSecond)
            Text("\(coordination.settlementBankName ?? "") \(coordination.settlementAccountNumber ?? "")")
                .font(.subheadline.weight(.semibold))
            Button("계좌번호 복사") {
                UIPasteboard.general.string = coordination.settlementAccountNumber
                copiedFallbackMessage = "계좌번호를 복사했어요."
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(UCColor.accent)
        }
        .padding(12)
        .background(UCColor.bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }

    private var participantSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("참여자별 송금")
                .font(.subheadline.weight(.semibold))

            ForEach(contributorRows) { pledge in
                participantRow(pledge)
            }
        }
    }

    private func participantRow(_ pledge: FundingPledgeRecord) -> some View {
        let isCurrentUser = pledge.contributorUserId == currentUserId
        let bankName = coordination.settlementBankName ?? ""
        let bankCode = coordination.settlementBankCode ?? ""
        let account = coordination.settlementAccountNumber ?? ""
        let fallback = RemittanceDeepLinkBuilder.fallbackAccountText(
            bankName: bankName,
            accountNumber: account,
            amount: pledge.amount,
            recipientLabel: buyerDisplayName
        )

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pledge.displayContributorName)
                    .font(.subheadline.weight(.semibold))
                if isCurrentUser {
                    Text("나")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(UCColor.fundingSoft)
                        .clipShape(Capsule())
                }
                Spacer()
                Text(RemittanceDeepLinkBuilder.formatPrice(pledge.amount))
                    .font(.subheadline.weight(.bold))
            }

            HStack(spacing: 8) {
                remittanceButton(
                    title: "카카오페이",
                    url: RemittanceDeepLinkBuilder.kakaoPayURL(
                        bankCode: bankCode,
                        accountNumber: account,
                        amount: pledge.amount
                    ),
                    fallback: fallback
                )
                remittanceButton(
                    title: "토스",
                    url: RemittanceDeepLinkBuilder.tossURL(
                        bankName: bankName,
                        accountNumber: account,
                        amount: pledge.amount
                    ),
                    fallback: fallback
                )
            }
        }
        .padding(12)
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func remittanceButton(title: String, url: URL?, fallback: String) -> some View {
        Button(title) {
            if let url {
                let opened = RemittanceDeepLinkBuilder.openURL(url, fallbackText: fallback)
                copiedFallbackMessage = opened
                    ? "\(title) 앱으로 이동했어요."
                    : "앱을 열지 못해 계좌 정보를 복사했어요."
            } else {
                UIPasteboard.general.string = fallback
                copiedFallbackMessage = "계좌 정보를 복사했어요."
            }
        }
        .buttonStyle(UCBorderedButtonStyle())
    }

    private var settlementShareText: String? {
        guard coordination.hasSettlementAccount else { return nil }

        var lines = [
            "[Universe Cart] \(itemTitle) 정산 안내",
            "대표: \(buyerDisplayName)",
            "계좌: \(coordination.settlementBankName ?? "") \(coordination.settlementAccountNumber ?? "")",
            "",
        ]

        for pledge in contributorRows {
            lines.append("- \(pledge.displayContributorName): \(RemittanceDeepLinkBuilder.formatPrice(pledge.amount))")
        }

        lines.append("")
        lines.append("UC는 결제·송금을 처리하지 않아요. 카카오페이·토스에서 직접 송금해 주세요.")
        return lines.joined(separator: "\n")
    }
}
