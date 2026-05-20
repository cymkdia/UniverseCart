import Foundation

enum SharedItemStore {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupConstants.id)
    }

    static func loadPending() -> [SharedPendingItem] {
        guard let defaults,
              let data = defaults.data(forKey: AppGroupConstants.pendingItemsKey) else {
            return []
        }

        return (try? JSONDecoder().decode([SharedPendingItem].self, from: data)) ?? []
    }

    static func append(_ item: SharedPendingItem) {
        var items = loadPending()
        items.insert(item, at: 0)
        save(items)
    }

    static func clearPending() {
        defaults?.removeObject(forKey: AppGroupConstants.pendingItemsKey)
    }

    private static func save(_ items: [SharedPendingItem]) {
        guard let defaults,
              let data = try? JSONEncoder().encode(items) else {
            return
        }
        defaults.set(data, forKey: AppGroupConstants.pendingItemsKey)
    }
}
