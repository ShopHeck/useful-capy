import SwiftUI

@main
struct InterfaceForgeApp: App {
    @StateObject private var generatorViewModel = GeneratorViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(generatorViewModel)
        }
    }
}
