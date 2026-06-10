import SwiftUI

struct ContentView: View {
    private enum Tab: Int {
        case list = 0
        case profile = 1
    }

    @Environment(AuthSession.self) private var auth
    @Environment(FundingNotificationCenter.self) private var notificationCenter
    @State private var selectedTab: Tab = .list
    @State private var sharedFundingItemId: UUID?

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                MainListView()
                    .tabItem {
                        Label("내 리스트", systemImage: "list.bullet.rectangle")
                    }
                    .tag(Tab.list)
                    .badge(notificationCenter.unreadCount > 0 ? notificationCenter.unreadCount : 0)

                ProfileView()
                    .tabItem {
                        Label("프로필", systemImage: "person.crop.circle")
                    }
                    .tag(Tab.profile)
            }
            .tint(UCColor.textPrimary)

            if let toast = notificationCenter.toast {
                InAppNotificationBanner(
                    title: toast.title,
                    subtitle: toast.subtitle,
                    style: toast.style
                ) {
                    notificationCenter.dismissToast()
                }
            }
        }
        .onAppear {
            openListTabIfNeeded()
            Task { await notificationCenter.refresh(auth: auth) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .onboardingDidFinish)) { _ in
            selectedTab = .list
        }
        .onChange(of: auth.isAuthenticated) { _, isAuthenticated in
            guard isAuthenticated else { return }
            Task { await notificationCenter.refresh(auth: auth) }
        }
        .sheet(isPresented: Binding(
            get: { sharedFundingItemId != nil },
            set: { if !$0 { sharedFundingItemId = nil } }
        )) {
            if let itemId = sharedFundingItemId {
                SharedFundingDetailLoader(itemId: itemId) {
                    sharedFundingItemId = nil
                }
                .environment(auth)
                .environment(notificationCenter)
            }
        }
    }

    private func openListTabIfNeeded() {
        guard OnboardingPreferences.consumeOpenListTabRequest() else { return }
        selectedTab = .list
    }
}

#Preview {
    ContentView()
        .environment(AuthSession())
        .environment(FundingNotificationCenter())
}
