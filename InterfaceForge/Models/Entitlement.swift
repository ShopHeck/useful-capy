import Foundation

enum AppTier: String, Codable {
    case free
    case pro
}

@MainActor
final class UsageTracker: ObservableObject {
    @Published private(set) var generationsToday: Int = 0

    static let freeGenerationsPerDay = 3

    private let storageKey = "interfaceforge.usage.generations"
    private let dateKey = "interfaceforge.usage.date"

    init() { loadToday() }

    var freeGenerationsRemaining: Int {
        max(0, Self.freeGenerationsPerDay - generationsToday)
    }

    var canGenerateForFree: Bool { freeGenerationsRemaining > 0 }

    func recordGeneration() {
        loadToday()
        generationsToday += 1
        UserDefaults.standard.set(generationsToday, forKey: storageKey)
    }

    private func loadToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let stored = UserDefaults.standard.object(forKey: dateKey) as? Date ?? .distantPast
        if Calendar.current.isDate(stored, inSameDayAs: today) {
            generationsToday = UserDefaults.standard.integer(forKey: storageKey)
        } else {
            generationsToday = 0
            UserDefaults.standard.set(0, forKey: storageKey)
            UserDefaults.standard.set(today, forKey: dateKey)
        }
    }
}
