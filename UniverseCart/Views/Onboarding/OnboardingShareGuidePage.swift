import SwiftUI

struct OnboardingShareGuidePage: View {
    let onNext: () -> Void

    var body: some View {
        OnboardingPageScaffold {
            VStack(alignment: .leading, spacing: OnboardingMetrics.sectionSpacing) {
                OnboardingHeader(
                    title: "쇼핑하다 마음에 들면,\n‘공유’로 담아요",
                    subtitle: "딱 한 번만 익혀두면, 다음부턴 공유 한 번이면 끝이에요."
                )

                OnboardingFlowDiagram()

                OnboardingImportantBox(steps: [
                    "공유 앱 목록 맨 끝 ‘더 보기(···)’를 눌러요.",
                    "‘편집’을 선택해요.",
                    "Universe Cart를 켜고 맨 위로 올려 즐겨찾기에 고정해요.",
                ])
            }
            .padding(.bottom, 24)
        } footer: {
            OnboardingPrimaryButton(title: "다음", action: onNext)
        }
    }
}
