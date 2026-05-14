import SwiftUI

@main
struct InterfaceForgeApp: App {
    @StateObject private var generatorViewModel = GeneratorViewModel()
    @StateObject private var historyStore = DesignHistoryStore()
    @StateObject private var promptStore = PromptLibraryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(generatorViewModel)
                .environmentObject(historyStore)
                .environmentObject(promptStore)
        }
    }
}
