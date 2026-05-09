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
}
