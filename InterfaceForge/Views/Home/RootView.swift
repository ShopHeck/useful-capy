import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .composer:
                        ComposerView()
                    case .preview:
                        PreviewScreen()
                    case .export:
                        ExportScreen()
                    case .history:
                        DesignHistoryScreen()
                    case .promptLibrary:
                        PromptLibraryScreen()
                    case .paywall:
                        PaywallView()
                    }
                }
        }
        .tint(viewModel.configuration.theme.accent)
    }
}

enum AppRoute: Hashable {
    case composer
    case preview
    case export
    case history
    case promptLibrary
    case paywall
}
