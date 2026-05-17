import Foundation
import SwiftUI

@MainActor
final class PromptLibraryStore: ObservableObject {
    @Published var prompts: [SavedPrompt] = []
    @Published var lastError: String?

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
        do {
            let data = try JSONEncoder().encode(prompts)
            UserDefaults.standard.set(data, forKey: storageKey)
            lastError = nil
        } catch {
            lastError = "Couldn't save prompt library: \(error.localizedDescription)"
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            prompts = try JSONDecoder().decode([SavedPrompt].self, from: data)
        } catch {
            lastError = "Couldn't load saved prompts: \(error.localizedDescription). Starting with an empty library."
        }
    }
}
