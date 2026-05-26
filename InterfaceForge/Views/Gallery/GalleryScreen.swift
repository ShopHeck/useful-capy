import SwiftUI

/// Community gallery: browse, fork, and share AI-generated UI components.
struct GalleryScreen: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @EnvironmentObject private var historyStore: DesignHistoryStore
    @StateObject private var gallery = GalleryService()
    @State private var sortOrder: GallerySortOrder = .recent
    @State private var forkedItemID: UUID?

    private let columns = [GridItem(.adaptive(minimum: 280, maximum: 400), spacing: 16)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                SectionHeader(
                    "Community gallery",
                    eyebrow: "Shared designs",
                    subtitle: "Browse components shared by the community. Fork any design to use it as a starting point for your own work.",
                    systemImage: "person.2.fill",
                    theme: viewModel.configuration.theme
                )
                .padding(.horizontal)

                // Sort picker
                HStack {
                    Picker("Sort", selection: $sortOrder) {
                        ForEach(GallerySortOrder.allCases) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 200)

                    Spacer()

                    if gallery.isLoading {
                        ProgressView()
                            .tint(viewModel.configuration.theme.accent)
                    }
                }
                .padding(.horizontal)

                if let error = gallery.loadError {
                    InfoCallout(
                        title: "Gallery unavailable",
                        message: error,
                        systemImage: "icloud.slash",
                        theme: viewModel.configuration.theme
                    )
                    .padding(.horizontal)
                }

                if gallery.galleryItems.isEmpty && !gallery.isLoading {
                    ContentUnavailableView(
                        "No shared designs yet",
                        systemImage: "person.2.slash",
                        description: Text("Be the first to share a design! Open any generated component and tap \"Share to Gallery\".")
                    )
                    .padding(.horizontal)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(gallery.galleryItems) { item in
                            GalleryCard(item: item, theme: viewModel.configuration.theme, isForked: forkedItemID == item.id) {
                                forkDesign(item)
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
        .navigationTitle("Gallery")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .task { await gallery.fetchGallery(sortBy: sortOrder) }
        .onChange(of: sortOrder) { _, newOrder in
            Task { await gallery.fetchGallery(sortBy: newOrder) }
        }
    }

    private func forkDesign(_ item: GalleryItem) {
        guard let design = item.design else { return }

        viewModel.prompt = design.prompt
        viewModel.selectedTemplate = design.template
        viewModel.configuration = design.configuration
        viewModel.generatedDesign = design
        viewModel.makeExportPackage(outputType: design.configuration.outputType)
        historyStore.save(design)

        withAnimation(.spring(response: 0.3)) {
            forkedItemID = item.id
        }

        Task { await gallery.incrementForkCount(item: item) }
    }
}

private struct GalleryCard: View {
    let item: GalleryItem
    let theme: ColorTheme
    let isForked: Bool
    let onFork: () -> Void

    var body: some View {
        GlassCard(radius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    GradientIconBadge(
                        systemImage: templateIcon(for: item.templateTitle),
                        theme: theme,
                        size: 40
                    )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.headline)
                            .font(.headline)
                            .lineLimit(2)
                        HStack(spacing: 6) {
                            Text(item.templateTitle)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(theme.accent)
                            Text("·")
                                .foregroundStyle(.secondary)
                            Text(item.theme)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }

                Text(item.prompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 16) {
                    Label(item.authorName, systemImage: "person.circle")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Label("\(item.forkCount)", systemImage: "arrow.triangle.branch")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(item.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Spacer()

                    Button {
                        onFork()
                    } label: {
                        Label(isForked ? "Forked" : "Fork", systemImage: isForked ? "checkmark.circle.fill" : "arrow.triangle.branch")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundStyle(isForked ? .green : .white)
                            .background(isForked ? Color.green.opacity(0.2) : theme.accent.opacity(0.9), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isForked)
                    .accessibilityLabel(isForked ? "Already forked" : "Fork this design")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Gallery design: \(item.headline) by \(item.authorName), \(item.forkCount) forks")
    }

    private func templateIcon(for title: String) -> String {
        if let template = DesignTemplate.all.first(where: { $0.title.lowercased() == title.lowercased() }) {
            return template.iconName
        }
        return "sparkles"
    }
}
