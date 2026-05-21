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
        await runAuthAction(message: "카카오로 로그인했어요") {
            guard let client = SupabaseService.shared.client else {
                throw AuthSessionError.notConfigured
            }

            _ = try await client.auth.signInWithOAuth(
                provider: .kakao,
                redirectTo: AuthRedirect.callbackURL
            )
        }
    }

    func handleOpenURL(_ url: URL) async {
        guard let client = SupabaseService.shared.client else { return }

        do {
            _ = try await client.auth.session(from: url)
            refreshFromCurrentSession()
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

        let text = error.localizedDescription
        if text.localizedCaseInsensitiveContains("cancel") {
            return "로그인을 취소했어요."
        }

        return text
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
