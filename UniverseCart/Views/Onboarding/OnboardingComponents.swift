import SwiftUI

enum OnboardingMetrics {
    static let horizontalPadding: CGFloat = 24
    static let contentTopPadding: CGFloat = 4
    static let sectionSpacing: CGFloat = 28
    static let footerTopPadding: CGFloat = 16
    static let footerBottomPadding: CGFloat = 12
    static let flowIconSize: CGFloat = 64
    static let primaryButtonHeight: CGFloat = UCButtonMetrics.actionHeight
}

struct OnboardingTopBar: View {
    let step: Int
    let totalSteps: Int
    var showsSkip: Bool = true
    let onSkip: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= step ? UCColor.textPrimary : UCColor.border)
                        .frame(width: 36, height: 3)
                }
            }

            Spacer(minLength: 0)

            if showsSkip {
                UCToolbarButton(title: "건너뛰기", action: onSkip)
            }
        }
        .padding(.horizontal, OnboardingMetrics.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 20)
    }
}

/// 스크롤 콘텐츠 + 하단 고정 푸터 (디자인 시안 비율)
struct OnboardingPageScaffold<Content: View, Footer: View>: View {
    private let content: Content
    private let footer: Footer

    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.content = content()
        self.footer = footer()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                    .padding(.top, OnboardingMetrics.contentTopPadding)
            }

            footer
                .padding(.horizontal, OnboardingMetrics.horizontalPadding)
                .padding(.top, OnboardingMetrics.footerTopPadding)
                .padding(.bottom, OnboardingMetrics.footerBottomPadding)
                .safeAreaPadding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

struct OnboardingHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(UCColor.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(UCColor.textSecond)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        UCPrimaryCTA(title, action: action)
    }
}

struct OnboardingFlowDiagram: View {
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            OnboardingFlowStep(icon: "iphone", label: "상품 보기")
            flowArrow
            OnboardingFlowStep(icon: "square.and.arrow.up", label: "공유 누르기")
            flowArrow
            ucStep
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }

    private var flowArrow: some View {
        Image(systemName: "arrow.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(UCColor.textDisabled)
            .padding(.top, 24)
    }

    private var ucStep: some View {
        VStack(spacing: 10) {
            Text("UC")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(UCColor.bg)
                .frame(width: OnboardingMetrics.flowIconSize, height: OnboardingMetrics.flowIconSize)
                .background(UCColor.textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("담기")
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

struct OnboardingFlowStep: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundStyle(UCColor.textPrimary)
                .frame(width: OnboardingMetrics.flowIconSize, height: OnboardingMetrics.flowIconSize)
                .background(UCColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(UCColor.border, lineWidth: 1)
                )

            Text(label)
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
    }
}

struct OnboardingImportantBox: View {
    let steps: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("중요")
                .font(.caption.weight(.semibold))
                .foregroundStyle(UCColor.accentDeep)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(UCColor.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            Text("공유 시트에 UC가 안 보이나요?")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(UCColor.textPrimary)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(UCColor.textSecond)
                            .frame(width: 16, alignment: .leading)
                        Text(step)
                            .font(.caption)
                            .foregroundStyle(UCColor.textSecond)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(UCColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(UCColor.border, lineWidth: 1)
        )
    }
}
