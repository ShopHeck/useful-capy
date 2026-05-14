import Foundation

struct SavedPrompt: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var text: String
    var createdAt: Date

    init(name: String, text: String, createdAt: Date = Date()) {
        self.name = name
        self.text = text
        self.createdAt = createdAt
    }
}
