import SwiftUI

struct ShareWishlistSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthSession.self) private var auth

    @Binding var shareProfile: ProfileRecord?

    @State private var isShareBusy = false
    @State private var didCopyLink = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if auth.isAuthenticated {
                        shareContent
                    } else {
                        signInPrompt
                    }
                }
                .padding(16)
            }
            .background(UCColor.bg.ignoresSafeArea())
            .navigationTitle("위시리스트 공유")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    UCToolbarButton(title: "닫기") { dismiss() }
                }
            }
        }
        .task {
            await loadShareProfile()
        }
    }

    private var signInPrompt: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("로그인이 필요해요")
                .font(.headline)

            Text("프로필 탭에서 이메일로 로그인하면 위시리스트를 친구에게 공유할 수 있어요.")
                .font(.subheadline)
                .foregroundStyle(UCColor.textSecond)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var shareContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("친구가 웹 링크로 내 위시리스트를 볼 수 있어요. 장바구니 항목은 공개되지 않아요.")
                .font(.subheadline)
                .foregroundStyle(UCColor.textSecond)
                .fixedSize(horizontal: false, vertical: true)

            Toggle("위시리스트 공개", isOn: shareEnabledBinding)
                .font(.subheadline)
                .disabled(isShareBusy)

            if shareProfile?.shareEnabled == true, let slug = shareProfile?.shareSlug {
                shareLinkSection(slug: slug)
            } else {
                Text("공개를 켜면 공유 링크가 만들어져요.")
                    .font(.caption)
                    .foregroundStyle(UCColor.textSecond)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func shareLinkSection(slug: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("공유 주소")
                .font(.caption)
                .foregroundStyle(UCColor.textSecond)

            if let url = ShareProfileService.shareURL(slug: slug) {
                Text(url)
                    .font(.caption)
                    .foregroundStyle(UCColor.textPrimary)
                    .textSelection(.enabled)

                HStack(spacing: UCButtonMetrics.inlineSpacing) {
                    Button(didCopyLink ? "복사됨" : "링크 복사") {
                        UIPasteboard.general.string = url
                        didCopyLink = true
                    }
                    .buttonStyle(UCBorderedButtonStyle())

                    ShareLink(item: url) {
                        Text("다른 앱으로 공유")
                    }
                    .buttonStyle(UCPrimaryButtonStyle())
                }
                .padding(.top, 16)
            } else {
                Text("SupabaseSecrets.plist에 SHARE_WEB_BASE_URL을 넣어 주세요.")
                    .font(.caption)
                    .foregroundStyle(UCColor.textSecond)
            }
        }
    }

    private var shareEnabledBinding: Binding<Bool> {
        Binding(
            get: { shareProfile?.shareEnabled == true },
            set: { newValue in
                Task { await setShareEnabled(newValue) }
            }
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
