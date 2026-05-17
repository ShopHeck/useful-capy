import Foundation
import SwiftUI

@MainActor
final class DesignHistoryStore: ObservableObject {
    @Published var entries: [GeneratedDesign] = []
    @Published var lastError: String?

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
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
            lastError = nil
        } catch {
            lastError = "Couldn't save design history: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            entries = try JSONDecoder().decode([GeneratedDesign].self, from: data)
        } catch {
            lastError = "Couldn't load design history: \(error.localizedDescription). Older entries are temporarily hidden."
        }
    }
}
