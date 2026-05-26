import SwiftUI

private enum OnboardingCompleteLayout {
    /// 상단 여백 (콘텐츠 영역 대비) — 시안: 성공 메시지가 화면 중상단
    static let topInsetRatio: CGFloat = 0.18
    static let heroToCardSpacing: CGFloat = 32
    static let cardToInfoSpacing: CGFloat = 16
}

struct OnboardingCompletePage: View {
    let item: Item
    let onViewList: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var shareProfile: ProfileRecord?
    @State private var showingShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: geometry.size.height * OnboardingCompleteLayout.topInsetRatio)

                        heroBlock

                        Spacer()
                            .frame(height: OnboardingCompleteLayout.heroToCardSpacing)

                        OnboardingItemPreviewCard(item: item)

                        Spacer()
                            .frame(height: OnboardingCompleteLayout.cardToInfoSpacing)

                        infoBox

                        Spacer(minLength: 16)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                    .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                }
            }

            footer
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .padding(.top, OnboardingMetrics.footerTopPadding)
                .padding(.bottom, OnboardingMetrics.footerBottomPadding)
                .safeAreaPadding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UCColor.bg)
        .sheet(isPresented: $showingShareSheet) {
            ShareWishlistSheet(shareProfile: $shareProfile)
        }
    }

    private var heroBlock: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(Color(hex: "03C75A"))
                .clipShape(Circle())

            Text("첫 위시를 담았어요!")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(UCColor.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var infoBox: some View {
        Text(
            "이제 다른 몰에서 마음에 드는 게 보일 때마다 ‘공유’로 담아보세요. 여러 몰의 위시가 모일수록 한눈에 보기 좋아져요."
        )
        .font(.subheadline)
        .foregroundStyle(UCColor.textSecond)
        .lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UCColor.bg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }

    private var footer: some View {
        VStack(spacing: UCButtonMetrics.inlineSpacing) {
            Button {
                closeAndViewList()
            } label: {
                Text("내 리스트 보기")
            }
            .buttonStyle(UCPrimaryButtonStyle())

            UCSecondaryCTA(title: "위시리스트 친구에게 공유하기") {
                showingShareSheet = true
            }
        }
    }

    private func closeAndViewList() {
        OnboardingPreferences.markCompleted(openListTab: true)
        NotificationCenter.default.post(name: .onboardingDidFinish, object: nil)
        onViewList()
        dismiss()
    }
}
