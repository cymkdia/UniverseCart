import SwiftUI

struct ContentView: View {
    private enum Tab: Int {
        case list = 0
        case profile = 1
    }

    @Environment(AuthSession.self) private var auth
    @State private var selectedTab: Tab = .list

    var body: some View {
        TabView(selection: $selectedTab) {
            MainListView()
                .tabItem {
                    Label("내 리스트", systemImage: "list.bullet.rectangle")
                }
                .tag(Tab.list)

            ProfileView()
                .tabItem {
                    Label("프로필", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)
        }
        .tint(UCColor.textPrimary)
        .onAppear(perform: openListTabIfNeeded)
        .onReceive(NotificationCenter.default.publisher(for: .onboardingDidFinish)) { _ in
            selectedTab = .list
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
}
