import Foundation
import SwiftUI

@MainActor
final class DesignHistoryStore: ObservableObject {
    @Published var entries: [GeneratedDesign] = []

    private let maxEntries: Int
    private let storageKey: String

    init(maxEntries: Int = 50, storageKey: String = "interfaceforge.history.entries") {
        self.maxEntries = maxEntries
        self.storageKey = storageKey
        load()
    }

    func save(_ design: GeneratedDesign) {
        var list = entries
        list.insert(design, at: 0)
        if list.count > maxEntries {
            list = Array(list.prefix(maxEntries))
        }
        entries = list
        persist()
    }

    func remove(_ design: GeneratedDesign) {
        entries.removeAll { $0.id == design.id }
        persist()
    }

    func removeAll() {
        entries.removeAll()
        persist()
    }

    func clear() {
        removeAll()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([GeneratedDesign].self, from: data) else { return }
        entries = decoded
    }
}
