import SwiftUI

struct ContentView: View {
    @Environment(AuthSession.self) private var auth

    var body: some View {
        TabView {
            MainListView()
                .tabItem {
                    Label("내 리스트", systemImage: "list.bullet.rectangle")
                }

            ProfileView()
                .tabItem {
                    Label("프로필", systemImage: "person.crop.circle")
                }
        }
        .tint(UCColor.textPrimary)
    }
}

#Preview {
    ContentView()
        .environment(AuthSession())
}
