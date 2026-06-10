import Foundation
import Supabase

@MainActor
@Observable
final class FundingNotificationCenter {
    var notifications: [FundingNotificationRecord] = []
    var toast: InAppToast?
    var unreadCount: Int = 0
    var isLoading = false

    private var shownToastIDs: Set<UUID> = []

    func refresh(auth: AuthSession) async {
        guard auth.isAuthenticated,
              let client = SupabaseService.shared.client,
              let userId = auth.currentUserId()
        else {
            notifications = []
            unreadCount = 0
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await FundingNotificationService.fetchNotifications(
                client: client,
                userId: userId
            )
            notifications = fetched
            unreadCount = fetched.filter(\.isUnread).count
            presentNewToasts(from: fetched)
        } catch {
            auth.statusMessage = "알림을 불러오지 못했어요."
        }
    }

    func markRead(_ notification: FundingNotificationRecord, auth: AuthSession) async {
        guard notification.isUnread,
              let client = SupabaseService.shared.client,
              let userId = auth.currentUserId()
        else {
            return
        }

        do {
            try await FundingNotificationService.markRead(
                client: client,
                notificationId: notification.id,
                userId: userId
            )
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                var updated = notifications[index]
                notifications[index] = FundingNotificationRecord(
                    id: updated.id,
                    userId: updated.userId,
                    itemId: updated.itemId,
                    kind: updated.kind,
                    title: updated.title,
                    body: updated.body,
                    readAt: Date(),
                    createdAt: updated.createdAt
                )
            }
            unreadCount = notifications.filter(\.isUnread).count
        } catch {
            auth.statusMessage = "알림 처리에 실패했어요."
        }
    }

    func dismissToast() {
        toast = nil
    }

    private func presentNewToasts(from fetched: [FundingNotificationRecord]) {
        guard let newestUnread = fetched.first(where: { $0.isUnread }),
              !shownToastIDs.contains(newestUnread.id)
        else {
            return
        }

        shownToastIDs.insert(newestUnread.id)
        toast = FundingNotificationDisplay.toast(for: newestUnread)
    }
}
