import Foundation
import SwiftUI

@MainActor
final class DesignHistoryStore: ObservableObject {
    @Published var entries: [GeneratedDesign] = []
    @Published var lastError: String?

    let cloudSync = CloudSyncService()

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

        // Fire-and-forget cloud save
        cloudSync.save(design: design)
    }

    func remove(_ design: GeneratedDesign) {
        entries.removeAll { $0.id == design.id }
        persist()

        Task { await cloudSync.delete(designID: design.id) }
    }

    func removeAll() {
        entries.removeAll()
        persist()
    }

    func clear() {
        removeAll()
    }

    /// Pull designs from CloudKit and merge with local entries.
    /// Cloud records that don't exist locally are added; local remains source of truth for conflicts.
    func syncFromCloud() async {
        let available = await cloudSync.checkAccountStatus()
        guard available else { return }
        await cloudSync.ensureZone()

        let cloudRecords = await cloudSync.fetchAll()
        let localIDs = Set(entries.map { $0.id })

        var merged = entries
        for record in cloudRecords {
            guard let design = record.design, !localIDs.contains(design.id) else { continue }
            merged.append(design)
        }

        // Sort by date, cap at max
        merged.sort { $0.createdAt > $1.createdAt }
        if merged.count > maxEntries {
            merged = Array(merged.prefix(maxEntries))
        }

        if merged.count != entries.count {
            entries = merged
            persist()
        }
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
