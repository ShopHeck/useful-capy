import SwiftUI

struct DesignHistoryScreen: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @EnvironmentObject private var historyStore: DesignHistoryStore
    @State private var confirmClear = false
    @State private var navigateToPreview = false

    private let columns = [GridItem(.adaptive(minimum: 280, maximum: 380), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeader(
                    "Design history",
                    eyebrow: "Your generations",
                    subtitle: "Past designs are saved automatically. Tap one to load it for preview and export, or swipe to delete.",
                    systemImage: "clock.arrow.circlepath",
                    theme: viewModel.configuration.theme
                )
                .padding(.horizontal)

                if historyStore.entries.isEmpty {
                    ContentUnavailableView(
                        "No saved designs",
                        systemImage: "clock.badge.questionmark",
                        description: Text("Each design you generate appears here — tap to revisit preview and export any past design.")
                    )
                    .padding(.horizontal)
                } else {
                    actionBar
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(historyStore.entries) { design in
                            HistoryCard(design: design, theme: viewModel.configuration.theme)
                                .onTapGesture {
                                    loadDesign(design)
                                    navigateToPreview = true
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                            historyStore.remove(design)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .readableContentFrame(maxWidth: 1060)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToPreview) {
            PreviewScreen()
        }
        .appBackground(theme: viewModel.configuration.theme)
        .task { await historyStore.syncFromCloud() }
        .confirmationDialog("Clear all history?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Clear all", role: .destructive) {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    historyStore.removeAll()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all saved designs. This action cannot be undone.")
        }
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(historyStore.entries.count) design\(historyStore.entries.count == 1 ? "" : "s")")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()

                Button {
                    Task { await historyStore.syncFromCloud() }
                } label: {
                    Label("Sync", systemImage: cloudSyncIcon)
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(viewModel.configuration.theme.accent)
                .disabled(historyStore.cloudSync.syncStatus == .syncing)

                Button(role: .destructive) {
                    confirmClear = true
                } label: {
                    Label("Clear all", systemImage: "trash")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .tint(.orange)
            }

            // Sync status
            if case .unavailable(let msg) = historyStore.cloudSync.syncStatus {
                HStack(spacing: 6) {
                    Image(systemName: "icloud.slash")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(msg)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if case .synced = historyStore.cloudSync.syncStatus, let date = historyStore.cloudSync.lastSyncDate {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.icloud")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("Synced \(date, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var cloudSyncIcon: String {
        switch historyStore.cloudSync.syncStatus {
        case .syncing: return "arrow.triangle.2.circlepath.icloud"
        case .synced: return "checkmark.icloud"
        case .unavailable: return "icloud.slash"
        case .error: return "exclamationmark.icloud"
        case .idle: return "icloud.and.arrow.down"
        }
    }

    private func loadDesign(_ design: GeneratedDesign) {
        viewModel.generatedDesign = design
        viewModel.configuration = design.configuration
        viewModel.prompt = design.prompt
        viewModel.selectedTemplate = design.template
        viewModel.makeExportPackage(outputType: design.configuration.outputType)
        viewModel.selectedStep = .preview
    }
}

private struct HistoryCard: View {
    let design: GeneratedDesign
    let theme: ColorTheme

    var body: some View {
        GlassCard(radius: 26) {
            HStack(alignment: .top, spacing: 14) {
                GradientIconBadge(
                    systemImage: design.template.iconName,
                    theme: design.configuration.theme,
                    size: 42
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        StatusBadge(
                            title: design.generationMode.rawValue,
                            detail: design.generationMode == .ai ? "Provider output" : "Fallback",
                            systemImage: design.generationMode == .ai ? "sparkles" : "tag.fill",
                            tint: design.generationMode == .ai ? design.configuration.theme.accent : .orange
                        )
                        Spacer()
                        Text(design.createdAt, style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(design.headline)
                        .font(.headline)
                        .lineLimit(2)

                    if !design.prompt.isEmpty {
                        Text(design.prompt)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        MetricPill(
                            title: design.template.title,
                            detail: "Component",
                            systemImage: "rectangle.stack",
                            theme: design.configuration.theme
                        )
                        MetricPill(
                            title: design.configuration.outputType.rawValue,
                            detail: "Export",
                            systemImage: "doc.text",
                            theme: design.configuration.theme
                        )
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Design: \(design.headline), \(design.generationMode.rawValue), created \(design.createdAt.formatted(date: .abbreviated, time: .omitted))")
        .accessibilityHint("Tap to load this design for preview and export")
    }
}
