import Foundation

enum OnboardingPreferences {
    private static let completedKey = "universe_cart_has_completed_onboarding"
    private static let openListTabKey = "universe_cart_open_list_tab_after_onboarding"

    static var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    static func markCompleted(openListTab: Bool = true) {
        hasCompleted = true
        UserDefaults.standard.set(openListTab, forKey: openListTabKey)
    }

    static func consumeOpenListTabRequest() -> Bool {
        let shouldOpen = UserDefaults.standard.bool(forKey: openListTabKey)
        if shouldOpen {
            UserDefaults.standard.removeObject(forKey: openListTabKey)
        }
        return shouldOpen
    }

    #if DEBUG
    static func resetForTesting() {
        hasCompleted = false
    }
    #endif
}

extension Notification.Name {
    static let localItemsDidChange = Notification.Name("universe_cart_local_items_did_change")
    static let onboardingDidFinish = Notification.Name("universe_cart_onboarding_did_finish")
}
