import Foundation
import SwiftUI

@MainActor
final class PromptLibraryStore: ObservableObject {
    @Published var prompts: [SavedPrompt] = []

    private let storageKey: String

    init(storageKey: String = "interfaceforge.prompts.library") {
        self.storageKey = storageKey
        load()
    }

    func save(_ prompt: SavedPrompt) {
        var list = prompts
        list.insert(prompt, at: 0)
        prompts = list
        persist()
    }

    func update(_ prompt: SavedPrompt) {
        guard let index = prompts.firstIndex(where: { $0.id == prompt.id }) else { return }
        prompts[index] = prompt
        persist()
    }

    func remove(_ prompt: SavedPrompt) {
        prompts.removeAll { $0.id == prompt.id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(prompts) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([SavedPrompt].self, from: data) else { return }
        prompts = decoded
    }
}
