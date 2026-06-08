import Foundation

actor ResponseCache {
    struct Entry {
        let data: Data
        let storedAt: Date
    }

    private var store: [String: Entry] = [:]
    private let ttl: TimeInterval

    init(ttl: TimeInterval = 300) {
        self.ttl = ttl
    }

    func value(forKey key: String) -> Data? {
        guard let entry = store[key] else { return nil }
        guard Date().timeIntervalSince(entry.storedAt) < ttl else {
            store[key] = nil
            return nil
        }
        return entry.data
    }

    func setValue(_ data: Data, forKey key: String) {
        store[key] = Entry(data: data, storedAt: Date())
    }

    func removeAll() {
        store.removeAll()
    }
}
