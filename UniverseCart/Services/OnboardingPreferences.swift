import Foundation

enum OnboardingPreferences {
    private static let completedKey = "universe_cart_has_completed_onboarding"

    static var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    static func markCompleted() {
        hasCompleted = true
    }

    #if DEBUG
    static func resetForTesting() {
        hasCompleted = false
    }
    #endif
}

extension Notification.Name {
    static let localItemsDidChange = Notification.Name("universe_cart_local_items_did_change")
}
