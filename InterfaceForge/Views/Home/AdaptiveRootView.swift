import SwiftUI

/// iPad-optimized layout: NavigationSplitView with sidebar + detail.
/// On iPhone, falls back to the standard NavigationStack flow via RootView.
struct AdaptiveRootView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @EnvironmentObject private var historyStore: DesignHistoryStore
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var selectedSection: SidebarSection? = .create

    enum SidebarSection: String, CaseIterable, Identifiable {
        case create = "Create"
        case preview = "Preview"
        case export = "Export"
        case history = "History"
        case prompts = "Prompt Library"
        case gallery = "Gallery"
        case settings = "Settings"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .create: return "wand.and.stars"
            case .preview: return "play.rectangle.fill"
            case .export: return "shippingbox.fill"
            case .history: return "clock.arrow.circlepath"
            case .prompts: return "bookmark.fill"
            case .gallery: return "person.2.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        if sizeClass == .regular {
            // iPad: split view
            NavigationSplitView {
                sidebar
            } detail: {
                detailView
            }
            .tint(viewModel.configuration.theme.accent)
        } else {
            // iPhone: standard stack
            RootView()
        }
    }

    private var sidebar: some View {
        List(SidebarSection.allCases, selection: $selectedSection) { section in
            Label(section.rawValue, systemImage: section.icon)
                .tag(section)
        }
        .navigationTitle("InterfaceForge")
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var detailView: some View {
        NavigationStack {
            switch selectedSection {
            case .create:
                ComposerView()
            case .preview:
                PreviewScreen()
            case .export:
                ExportScreen()
            case .history:
                DesignHistoryScreen()
            case .prompts:
                PromptLibraryScreen()
            case .gallery:
                GalleryScreen()
            case .settings:
                PaywallView()
            case nil:
                ContentUnavailableView("Select a section", systemImage: "sidebar.left", description: Text("Choose a section from the sidebar to get started."))
            }
        }
    }
}
