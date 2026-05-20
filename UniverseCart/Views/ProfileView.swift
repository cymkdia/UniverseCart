import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("프로필")
                .font(.title2.bold())
            Text("M1에서는 자리만 만들어둡니다.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UCTheme.background)
    }
}
