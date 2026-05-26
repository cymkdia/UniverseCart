import SwiftUI

struct OnboardingFlowView: View {
    let onFinish: () -> Void

    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(step: page, totalSteps: 2, onSkip: finish)

            ZStack {
                if page == 0 {
                    OnboardingShareGuidePage {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            page = 1
                        }
                    }
                    .transition(.opacity)
                } else {
                    OnboardingPasteLinkPage(onFinish: finish)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(UCColor.bg.ignoresSafeArea())
    }

    private func finish() {
        OnboardingPreferences.markCompleted()
        onFinish()
    }
}

#Preview {
    OnboardingFlowView(onFinish: {})
}
