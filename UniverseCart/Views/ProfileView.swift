import SwiftUI

struct ProfileView: View {
    @Environment(AuthSession.self) private var auth

    @State private var email = ""
    @State private var password = ""

    @State private var shareProfile: ProfileRecord?
    @State private var isShareBusy = false
    @State private var didCopyLink = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("프로필")
                        .font(.title2.bold())
                        .foregroundStyle(UCColor.textPrimary)

                    if !auth.isConfigured {
                        setupNeededCard
                    } else if auth.isAuthenticated {
                        signedInCard
                        shareWishlistCard
                    } else {
                        socialSignInCard
                        signInCard
                    }

                    NavigationLink {
                        PolicyView()
                    } label: {
                        HStack {
                            Text("이용 안내")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(UCColor.textSecond)
                        }
                        .foregroundStyle(UCColor.textPrimary)
                        .padding(12)
                        .background(UCColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(UCColor.border, lineWidth: 1)
                        )
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
        .task(id: auth.isAuthenticated) {
            await loadShareProfile()
        }
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

            if let label = auth.userDisplayLabel {
                Text(label)
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

    private var shareWishlistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("위시리스트 공유")
                .font(.headline)

            Text("친구가 웹 링크로 내 위시리스트를 볼 수 있어요. (장바구니 항목은 공개되지 않아요)")
                .font(.footnote)
                .foregroundStyle(UCColor.textSecond)

            Toggle("위시리스트 공개", isOn: shareEnabledBinding)
                .font(.subheadline)
                .disabled(isShareBusy)

            if shareProfile?.shareEnabled == true, let slug = shareProfile?.shareSlug {
                VStack(alignment: .leading, spacing: 6) {
                    Text("공유 주소")
                        .font(.caption)
                        .foregroundStyle(UCColor.textSecond)

                    if let url = ShareProfileService.shareURL(slug: slug) {
                        Text(url)
                            .font(.caption)
                            .foregroundStyle(UCColor.textPrimary)
                            .textSelection(.enabled)

                        HStack(spacing: 10) {
                            Button(didCopyLink ? "복사됨" : "링크 복사") {
                                UIPasteboard.general.string = url
                                didCopyLink = true
                            }
                            .buttonStyle(.bordered)

                            ShareLink(item: url) {
                                Text("공유하기")
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Text("SupabaseSecrets.plist에 SHARE_WEB_BASE_URL을 넣어 주세요.")
                            .font(.caption)
                            .foregroundStyle(UCColor.textSecond)
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

    private var shareEnabledBinding: Binding<Bool> {
        Binding(
            get: { shareProfile?.shareEnabled == true },
            set: { newValue in
                Task { await setShareEnabled(newValue) }
            }
        )
    }

    private var socialSignInCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("간편 로그인")
                .font(.headline)

            Button {
                Task { await auth.signInWithKakao() }
            } label: {
                Text("카카오로 계속하기")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(red: 0.12, green: 0.12, blue: 0.12))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color(red: 0.99, green: 0.9, blue: 0.0))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(auth.isBusy)

            Text("Supabase에서 카카오 제공자를 켜야 동작해요. (docs/M9-social-login-setup.md)")
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)
                .fixedSize(horizontal: false, vertical: true)
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
            Text("이메일로 로그인")
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

    private func loadShareProfile() async {
        guard auth.isAuthenticated,
              let client = SupabaseService.shared.client,
              let userId = auth.currentUserId()
        else {
            shareProfile = nil
            return
        }

        do {
            shareProfile = try await ShareProfileService.fetchProfile(
                client: client,
                userId: userId
            )
        } catch {
            auth.statusMessage = "공유 설정 불러오기 실패: \(error.localizedDescription)"
        }
    }

    private func setShareEnabled(_ enabled: Bool) async {
        guard let client = SupabaseService.shared.client,
              let userId = auth.currentUserId()
        else {
            return
        }

        isShareBusy = true
        defer { isShareBusy = false }

        do {
            if enabled {
                shareProfile = try await ShareProfileService.enableSharing(
                    client: client,
                    userId: userId,
                    email: auth.userEmail,
                    existing: shareProfile
                )
                auth.statusMessage = "위시리스트 공유를 켰어요."
            } else if let existing = shareProfile {
                try await ShareProfileService.disableSharing(
                    client: client,
                    userId: userId,
                    existing: existing
                )
                auth.statusMessage = "위시리스트 공유를 껐어요."
                await loadShareProfile()
            }
            didCopyLink = false
        } catch {
            auth.statusMessage = "공유 설정 실패: \(error.localizedDescription)"
        }
    }
}
