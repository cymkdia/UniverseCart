import Foundation

enum ItemStore {
    private static let storageKey = "universe_cart_saved_items"

    static func load() -> [Item]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        return try? JSONDecoder().decode([Item].self, from: data)
    }

    static func save(_ items: [Item]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
