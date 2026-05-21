import AuthenticationServices
import Foundation
import Supabase

@MainActor
@Observable
final class AuthSession {
    var isConfigured = SupabaseConfig.isConfigured
    var isAuthenticated = false
    var userEmail: String?
    var userDisplayLabel: String?
    var isBusy = false
    var statusMessage: String?

    private var authListenerTask: Task<Void, Never>?

    init() {
        startAuthListenerIfNeeded()
        refreshFromCurrentSession()
    }

    func signIn(email: String, password: String) async {
        await runAuthAction(message: "로그인했어요") {
            guard let client = SupabaseService.shared.client else {
                throw AuthSessionError.notConfigured
            }

            _ = try await client.auth.signIn(email: email, password: password)
        }
    }

    func signUp(email: String, password: String) async {
        await runAuthAction(message: "회원가입이 완료됐어요. 이메일 확인이 켜져 있으면 메일함을 확인해 주세요.") {
            guard let client = SupabaseService.shared.client else {
                throw AuthSessionError.notConfigured
            }

            _ = try await client.auth.signUp(email: email, password: password)
        }
    }

    func signInWithApple(idToken: String, nonce: String) async {
        await runAuthAction(message: "Apple로 로그인했어요") {
            guard let client = SupabaseService.shared.client else {
                throw AuthSessionError.notConfigured
            }

            _ = try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
        }
    }

    func signInWithKakao() async {
        isBusy = true
        statusMessage = nil
        defer { isBusy = false }

        guard let client = SupabaseService.shared.client else {
            statusMessage = AuthSessionError.notConfigured.errorDescription
            return
        }

        do {
            // account_email·openid 는 개인 앱에서 KOE205 원인이 될 수 있어 닉네임·프로필만 요청
            _ = try await client.auth.signInWithOAuth(
                provider: .kakao,
                redirectTo: AuthRedirect.callbackURL,
                scopes: "profile_nickname profile_image"
            ) { session in
                session.prefersEphemeralWebBrowserSession = false
            }
            refreshFromCurrentSession()
            statusMessage = isAuthenticated
                ? "카카오로 로그인했어요."
                : "로그인이 끝나지 않았어요. Supabase Redirect URLs를 확인해 주세요."
        } catch {
            statusMessage = friendlyAuthMessage(for: error)
        }
    }

    func handleOpenURL(_ url: URL) async {
        guard let client = SupabaseService.shared.client else { return }

        do {
            _ = try await client.auth.session(from: url)
            refreshFromCurrentSession()
            if isAuthenticated {
                statusMessage = "카카오로 로그인했어요."
            }
        } catch {
            statusMessage = friendlyAuthMessage(for: error)
        }
    }

    func signOut() async {
        await runAuthAction(message: "로그아웃했어요") {
            guard let client = SupabaseService.shared.client else {
                throw AuthSessionError.notConfigured
            }

            try await client.auth.signOut()
        }
    }

    func currentUserId() -> UUID? {
        SupabaseService.shared.client?.auth.currentUser?.id
    }

    private func startAuthListenerIfNeeded() {
        guard authListenerTask == nil,
              let client = SupabaseService.shared.client
        else {
            return
        }

        authListenerTask = Task {
            for await (_, session) in await client.auth.authStateChanges {
                apply(session: session)
            }
        }
    }

    private func refreshFromCurrentSession() {
        apply(session: SupabaseService.shared.client?.auth.currentSession)
    }

    private func apply(session: Session?) {
        isAuthenticated = session != nil
        userEmail = session?.user.email
        userDisplayLabel = resolvedDisplayLabel(from: session)
    }

    private func resolvedDisplayLabel(from session: Session?) -> String? {
        guard let session else { return nil }

        if let email = session.user.email, !email.isEmpty {
            return email
        }

        if case let .string(email) = session.user.userMetadata["email"], !email.isEmpty {
            return email
        }

        if let identities = session.user.identities {
            for identity in identities {
                if let data = identity.identityData,
                   case let .string(email) = data["email"],
                   !email.isEmpty {
                    return email
                }
            }
        }

        if let name = session.user.userMetadata["full_name"]?.stringValue
            ?? session.user.userMetadata["name"]?.stringValue,
           !name.isEmpty {
            return name
        }

        return "로그인됨"
    }

    private func runAuthAction(
        message: String,
        action: () async throws -> Void
    ) async {
        isBusy = true
        statusMessage = nil
        defer { isBusy = false }

        do {
            try await action()
            refreshFromCurrentSession()
            statusMessage = message
        } catch {
            statusMessage = friendlyAuthMessage(for: error)
        }
    }

    private func friendlyAuthMessage(for error: Error) -> String {
        if let authError = error as? ASAuthorizationError,
           authError.code == .canceled {
            return "로그인을 취소했어요."
        }

        let text = [
            error.localizedDescription,
            (error as NSError).localizedFailureReason,
            (error as NSError).userInfo["message"] as? String,
        ]
        .compactMap { $0 }
        .joined(separator: " ")

        if text.localizedCaseInsensitiveContains("cancel") {
            return "로그인을 취소했어요."
        }
        if text.contains("KOE205") || text.localizedCaseInsensitiveContains("invalid_scope") {
            return "카카오 동의항목이 맞지 않아요. 동의항목에서 닉네임·프로필 사진을 켜고, Supabase Kakao에서 ‘이메일 없이 허용’을 ON 해 주세요."
        }
        if text.contains("KOE006") || text.localizedCaseInsensitiveContains("redirect_uri") {
            return "카카오 Redirect URI가 맞지 않아요. Supabase callback 주소가 카카오에 등록됐는지 확인해 주세요."
        }
        if text.contains("KOE004") {
            return "카카오 로그인이 꺼져 있어요. 카카오 개발자 → 제품 설정 → 카카오 로그인 → ON"
        }
        if text.localizedCaseInsensitiveContains("provider")
            && text.localizedCaseInsensitiveContains("not enabled") {
            return "Supabase → Authentication → Providers → Kakao를 켜 주세요."
        }
        if text.localizedCaseInsensitiveContains("pkce")
            || text.localizedCaseInsensitiveContains("redirect") {
            return "앱으로 돌아오지 못했어요. Supabase Redirect URLs에 cymk.UniverseCart://auth-callback 가 있는지 확인해 주세요."
        }

        return text.isEmpty ? "로그인에 실패했어요. 다시 시도해 주세요." : text
    }
}

enum AuthSessionError: LocalizedError {
    case notConfigured
    case missingAppleToken

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase 설정이 필요해요. SupabaseSecrets.plist를 확인해 주세요."
        case .missingAppleToken:
            return "Apple 로그인 정보를 받지 못했어요. 다시 시도해 주세요."
        }
    }
}

private extension AnyJSON {
    var stringValue: String? {
        if case let .string(value) = self {
            return value
        }
        return nil
    }
}
