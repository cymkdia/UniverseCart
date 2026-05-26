import SwiftUI

struct OnboardingFlowView: View {
    let onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var page = 0
    @State private var savedItem: Item?

    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            OnboardingTopBar(
                step: page,
                totalSteps: totalSteps,
                showsSkip: page < totalSteps - 1,
                onSkip: finish
            )

            ZStack {
                switch page {
                case 0:
                    OnboardingShareGuidePage {
                        goToPage(1)
                    }
                    .transition(.opacity)
                case 1:
                    OnboardingPasteLinkPage(
                        onItemSaved: { item in
                            savedItem = item
                            goToPage(2)
                        },
                        onSkip: finish
                    )
                    .transition(.opacity)
                case 2:
                    if let savedItem {
                        OnboardingCompletePage(
                            item: savedItem,
                            onViewList: finish
                        )
                        .transition(.opacity)
                    }
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(UCColor.bg.ignoresSafeArea())
    }

    private func goToPage(_ next: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            page = next
        }
    }

    private func finish() {
        OnboardingPreferences.markCompleted(openListTab: true)
        NotificationCenter.default.post(name: .onboardingDidFinish, object: nil)
        onFinish()
        dismiss()
    }
}

#Preview {
    OnboardingFlowView(onFinish: {})
}
