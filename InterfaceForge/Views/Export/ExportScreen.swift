import SwiftUI
import UIKit

struct ExportScreen: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @State private var selectedFileID: ExportFile.ID?
    @State private var copied = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepRail(activeStep: .export)
                    .padding(.horizontal, -16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Export package")
                        .font(.largeTitle.weight(.black))
                    Text("Your design is converted into beginner-friendly files with a README you can follow step by step.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                Picker("Export format", selection: $viewModel.configuration.outputType) {
                    ForEach(OutputType.allCases) { outputType in
                        Text(outputType.rawValue).tag(outputType)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.configuration.outputType) { _, outputType in
                    viewModel.makeExportPackage(outputType: outputType)
                }
                .accessibilityLabel("Export format")

                if let package = viewModel.exportPackage {
                    PackageSummary(package: package)
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        Button {
                            UIPasteboard.general.string = package.combinedText
                            withAnimation { copied = true }
                        } label: {
                            Label(copied ? "Copied" : "Copy code", systemImage: copied ? "checkmark.circle.fill" : "doc.on.doc")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .accessibilityLabel("Copy code")

                        if let folderURL = viewModel.exportFolderURL {
                            ShareLink(item: folderURL) {
                                Label("Share package", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .foregroundStyle(.white)
                                    .background(viewModel.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .accessibilityLabel("Share package")
                        }
                    }
                    .padding(.horizontal)

                    BeginnerGuideCard(package: package)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Files in this package")
                            .font(.headline)
                        ForEach(package.files) { file in
                            FilePreviewRow(file: file, isExpanded: selectedFileID == file.id) {
                                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                                    selectedFileID = selectedFileID == file.id ? nil : file.id
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    ContentUnavailableView("Nothing to export", systemImage: "shippingbox", description: Text("Generate an interface first, then return to export the package."))
                }
            }
            .padding(.vertical, 18)
        }
        .navigationTitle("Export")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .onAppear {
            viewModel.selectedStep = .export
            viewModel.makeExportPackage(outputType: viewModel.configuration.outputType)
        }
    }
}

struct PackageSummary: View {
    let package: ExportPackage

    var body: some View {
        GlassCard(radius: 30) {
            HStack(alignment: .top, spacing: 16) {
                Image(systemName: "shippingbox.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 8) {
                    Text(package.packageName)
                        .font(.title3.weight(.bold))
                    Text("Includes \(package.files.count) files: component code, styles, and a README with copy-paste instructions.")
                        .foregroundStyle(.secondary)
                    Text(package.outputType.rawValue)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.thinMaterial, in: Capsule())
                }
            }
        }
    }
}

struct BeginnerGuideCard: View {
    let package: ExportPackage

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 12) {
                Label("Beginner install guide", systemImage: "graduationcap.fill")
                    .font(.headline)
                Text(package.beginnerGuide)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityLabel("Beginner install guide")
    }
}

struct FilePreviewRow: View {
    let file: ExportFile
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: action) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(.blue)
                    Text(file.name)
                        .font(.headline)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView(.horizontal) {
                    Text(file.contents)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(16)
                }
                .background(Color(.secondarySystemBackground))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityLabel("File \(file.name)")
    }

    private var icon: String {
        if file.name.hasSuffix(".css") { return "paintbrush.fill" }
        if file.name.hasSuffix(".md") { return "book.closed.fill" }
        return "chevron.left.forwardslash.chevron.right"
    }
}
