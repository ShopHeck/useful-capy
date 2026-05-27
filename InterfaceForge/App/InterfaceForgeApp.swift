import SwiftUI

@main
struct InterfaceForgeApp: App {
    @StateObject private var generatorViewModel = GeneratorViewModel()
    @StateObject private var historyStore = DesignHistoryStore()
    @StateObject private var promptStore = PromptLibraryStore()
    @StateObject private var storeKitManager = StoreKitManager()
    @StateObject private var usageTracker = UsageTracker()

    @AppStorage("interfaceforge.hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    RootView()
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .environmentObject(generatorViewModel)
            .environmentObject(historyStore)
            .environmentObject(promptStore)
            .environmentObject(storeKitManager)
            .environmentObject(usageTracker)
        }
    }
}
