import SwiftUI

struct ContentView: View {
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
        .tint(UCTheme.textPrimary)
    }
}

#Preview {
    ContentView()
}
