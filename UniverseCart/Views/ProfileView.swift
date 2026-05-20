import SwiftUI

struct ProfileView: View {
    @Environment(AuthSession.self) private var auth

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("프로필")
                    .font(.title2.bold())
                    .foregroundStyle(UCColor.textPrimary)

                if !auth.isConfigured {
                    setupNeededCard
                } else if auth.isAuthenticated {
                    signedInCard
                } else {
                    signInCard
                }

                if let status = auth.statusMessage {
                    Text(status)
                        .font(.footnote)
                        .foregroundStyle(UCColor.textSecond)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
        }
        .background(UCColor.bg)
    }

    private var setupNeededCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Supabase 연결 설정")
                .font(.headline)

            Text("Config/SupabaseSecrets.plist.example 을 복사해 SupabaseSecrets.plist 를 만들고, Project URL과 anon key를 넣은 뒤 다시 실행해 주세요.")
                .font(.subheadline)
                .foregroundStyle(UCColor.textSecond)
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

    private var signedInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("로그인됨")
                .font(.headline)

            if let email = auth.userEmail {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(UCColor.textSecond)
            }

            Text("내 리스트가 이 계정과 동기화됩니다.")
                .font(.footnote)
                .foregroundStyle(UCColor.textSecond)

            Button("로그아웃") {
                Task { await auth.signOut() }
            }
            .buttonStyle(.bordered)
            .disabled(auth.isBusy)
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

    private var signInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("계정")
                .font(.headline)

            TextField("이메일", text: $email)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .padding(12)
                .background(UCColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            SecureField("비밀번호 (6자 이상)", text: $password)
                .padding(12)
                .background(UCColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 12) {
                Button("로그인") {
                    Task { await auth.signIn(email: email, password: password) }
                }
                .buttonStyle(.borderedProminent)
                .tint(UCColor.accent)

                Button("회원가입") {
                    Task { await auth.signUp(email: email, password: password) }
                }
                .buttonStyle(.bordered)
            }
            .disabled(auth.isBusy || email.isEmpty || password.count < 6)
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
