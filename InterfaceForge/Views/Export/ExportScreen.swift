import SwiftUI
import UIKit

struct ExportScreen: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @EnvironmentObject private var storeKit: StoreKitManager
    @State private var selectedFileID: ExportFile.ID?
    @State private var copied = false
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepRail(activeStep: .export)
                    .padding(.horizontal, -16)

                SectionHeader(
                    "Export starter package",
                    eyebrow: "Handoff ready",
                    subtitle: "Copy all files or share the generated folder. Exports are beginner-friendly starter code and include setup notes for the selected format.",
                    systemImage: "shippingbox.fill",
                    theme: viewModel.configuration.theme
                )
                .padding(.horizontal)

                outputPicker

                if let package = viewModel.exportPackage {
                    PackageSummary(package: package)
                        .padding(.horizontal)

                    if storeKit.isPro {
                        actionBar(package: package)
                            .padding(.horizontal)
                    } else {
                        proExportGate
                            .padding(.horizontal)
                    }

                    BeginnerGuideCard(package: package)
                        .padding(.horizontal)

                    filesSection(package: package)
                        .padding(.horizontal)
                } else {
                    ContentUnavailableView("Nothing to export", systemImage: "shippingbox", description: Text("Generate an interface first, then return to export the starter package."))
                        .padding(.horizontal)
                }
            }
            .readableContentFrame(maxWidth: 980)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .sheet(isPresented: $showPaywall) {
            NavigationStack {
                PaywallView()
            }
        }
        .onAppear {
            viewModel.selectedStep = .export
            viewModel.makeExportPackage(outputType: viewModel.configuration.outputType)
        }
    }

    private var proExportGate: some View {
        GlassCard(radius: 28) {
            VStack(spacing: 16) {
                GradientIconBadge(systemImage: "crown.fill", theme: viewModel.configuration.theme, size: 50)
                Text("Export is a Pro feature")
                    .font(.title3.weight(.black))
                Text("You can preview the generated files above, but copying and sharing requires a Pro subscription.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "Unlock Pro", systemImage: "crown.fill", theme: viewModel.configuration.theme) {
                    showPaywall = true
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var outputPicker: some View {
        GlassCard(radius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    GradientIconBadge(systemImage: "chevron.left.forwardslash.chevron.right", theme: viewModel.configuration.theme, size: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Choose export format")
                            .font(.headline)
                        Text("Switching formats rebuilds the package so copied and shared files match the selected output.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Picker("Export format", selection: $viewModel.configuration.outputType) {
                    ForEach(OutputType.allCases) { outputType in
                        Text(outputType.rawValue).tag(outputType)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: viewModel.configuration.outputType) { _, outputType in
                    copied = false
                    viewModel.makeExportPackage(outputType: outputType)
                }
                .accessibilityLabel("Export format")
                .accessibilityHint("Selects the code format for the generated starter package")
            }
        }
        .padding(.horizontal)
    }

    private func actionBar(package: ExportPackage) -> some View {
        GlassCard(radius: 28) {
            VStack(alignment: .leading, spacing: 12) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        copyButton(package: package)
                        shareButton
                    }
                    VStack(spacing: 12) {
                        copyButton(package: package)
                        shareButton
                    }
                }

                InfoCallout(
                    title: "Which action should I use?",
                    message: "Use Copy all code for pasting into an editor. Use Share folder when handing files to another app or saving the package. Generated files are starter code, not a production guarantee.",
                    systemImage: "hand.point.up.left.fill",
                    theme: viewModel.configuration.theme
                )
            }
        }
    }

    private func copyButton(package: ExportPackage) -> some View {
        Button {
            UIPasteboard.general.string = package.combinedText
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { copied = true }
        } label: {
            Label(copied ? "Copied all files" : "Copy all files", systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .foregroundStyle(copied ? .white : .primary)
                .background(copied ? AnyShapeStyle(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)) : AnyShapeStyle(.thinMaterial), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(copied ? "Copied all generated files" : "Copy all generated files")
        .accessibilityHint("Copies every generated file and file name to the clipboard")
    }

    @ViewBuilder
    private var shareButton: some View {
        if let folderURL = viewModel.exportFolderURL {
            ShareLink(item: folderURL) {
                Label("Share folder", systemImage: "square.and.arrow.up.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .foregroundStyle(.white)
                    .background(viewModel.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .accessibilityLabel("Share package folder")
            .accessibilityHint("Opens the iOS share sheet for the generated folder")
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Label(viewModel.exportError == nil ? "Preparing share folder" : "Share folder unavailable", systemImage: viewModel.exportError == nil ? "hourglass" : "exclamationmark.triangle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .foregroundStyle(viewModel.exportError == nil ? .secondary : .orange)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                if let error = viewModel.exportError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityLabel(viewModel.exportError == nil ? "Preparing share folder" : "Share folder unavailable")
        }
    }

    private func filesSection(package: ExportPackage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                "Files in this package",
                subtitle: "Open a row to inspect the exact text included in copy and share. README files explain setup steps in beginner language.",
                systemImage: "folder.fill",
                theme: viewModel.configuration.theme
            )
            ForEach(package.files) { file in
                FilePreviewRow(file: file, isExpanded: selectedFileID == file.id) {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        selectedFileID = selectedFileID == file.id ? nil : file.id
                    }
                }
            }
        }
    }
}

struct PackageSummary: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    let package: ExportPackage

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    GradientIconBadge(systemImage: "shippingbox.fill", theme: viewModel.configuration.theme, size: 50)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(package.packageName)
                            .font(.title3.weight(.black))
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Includes \(package.files.count) files: component code, styles when needed, and a README with copy-paste setup steps.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], spacing: 10) {
                    MetricPill(title: package.outputType.rawValue, detail: "Format", systemImage: "doc.text", theme: viewModel.configuration.theme)
                    MetricPill(title: "\(package.files.count) files", detail: "Generated", systemImage: "folder", theme: viewModel.configuration.theme)
                    MetricPill(title: "README", detail: "Guide included", systemImage: "book.closed", theme: viewModel.configuration.theme)
                    MetricPill(title: "Starter", detail: "Handoff code", systemImage: "graduationcap", theme: viewModel.configuration.theme)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Package \(package.packageName), \(package.files.count) files, \(package.outputType.rawValue)")
    }
}

struct BeginnerGuideCard: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    let package: ExportPackage

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    GradientIconBadge(systemImage: "graduationcap.fill", theme: viewModel.configuration.theme, size: 42)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Beginner handoff guide")
                            .font(.headline)
                        Text("Included in README.md so the package is easier to hand to a learner, designer, or developer.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(package.beginnerGuide)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityLabel("Beginner handoff guide")
    }
}

struct FilePreviewRow: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    let file: ExportFile
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                HStack(spacing: 12) {
                    GradientIconBadge(systemImage: icon, theme: viewModel.configuration.theme, size: 36)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(file.name)
                            .font(.headline)
                        Text("\(fileTypeDescription) · \(lineCount) lines")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                        .font(.title3)
                        .foregroundStyle(isExpanded ? viewModel.configuration.theme.accent : .secondary)
                        .accessibilityHidden(true)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("File \(file.name), \(fileTypeDescription), \(lineCount) lines")
            .accessibilityHint(isExpanded ? "Collapse code preview" : "Expand code preview")

            if isExpanded {
                ScrollView(.horizontal) {
                    Text(file.contents)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color(.secondarySystemBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding([.horizontal, .bottom], 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .accessibilityLabel("Preview contents of \(file.name)")
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isExpanded ? viewModel.configuration.theme.accent.opacity(0.40) : Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    private var lineCount: Int {
        max(1, file.contents.split(separator: "\n", omittingEmptySubsequences: false).count)
    }

    private var icon: String {
        if file.name.hasSuffix(".css") { return "paintbrush.fill" }
        if file.name.hasSuffix(".md") { return "book.closed.fill" }
        if file.name.hasSuffix(".html") { return "safari.fill" }
        if file.name.hasSuffix(".swift") { return "swift" }
        return "chevron.left.forwardslash.chevron.right"
    }

    private var fileTypeDescription: String {
        if file.name.hasSuffix(".css") { return "Stylesheet" }
        if file.name.hasSuffix(".md") { return "Beginner README" }
        if file.name.hasSuffix(".html") { return "HTML page" }
        if file.name.hasSuffix(".swift") { return "SwiftUI source" }
        if file.name.hasSuffix(".jsx") { return "React component" }
        return "Generated source file"
    }
}
