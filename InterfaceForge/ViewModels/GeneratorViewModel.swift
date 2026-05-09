import Foundation
import SwiftUI

@MainActor
final class GeneratorViewModel: ObservableObject {
    @Published var prompt: String = ""
    @Published var selectedTemplate: DesignTemplate?
    @Published var configuration = DesignConfiguration()
    @Published var generatedDesign: GeneratedDesign?
    @Published var exportPackage: ExportPackage?
    @Published var exportFolderURL: URL?
    @Published var isGenerating = false
    @Published var progressMessage = "Reading your idea..."
    @Published var generationProgress = 0.0
    @Published var selectedStep: FlowStep = .describe

    let quickStartPrompts = [
        "SaaS pricing card",
        "AI dashboard widget",
        "Mobile onboarding hero",
        "Checkout form",
        "Portfolio project card"
    ]

    let progressMessages = [
        "Reading your idea...",
        "Choosing a beginner-friendly layout...",
        "Mixing theme colors and motion...",
        "Adding interactive states...",
        "Packaging export-ready code..."
    ]

    private let generator = DesignGenerator()
    private let exportService = CodeExportService()

    func useQuickStart(_ text: String) {
        prompt = text
        selectedTemplate = generator.matchedTemplate(for: text, selectedTemplate: nil)
        selectedStep = .describe
    }

    func generate() async {
        isGenerating = true
        generationProgress = 0
        selectedStep = .generate

        for index in progressMessages.indices {
            progressMessage = progressMessages[index]
            generationProgress = Double(index + 1) / Double(progressMessages.count)
            try? await Task.sleep(nanoseconds: 420_000_000)
        }

        let design = generator.generate(prompt: prompt, selectedTemplate: selectedTemplate, configuration: configuration)
        generatedDesign = design
        makeExportPackage(outputType: configuration.outputType)
        isGenerating = false
        selectedStep = .preview
    }

    func makeExportPackage(outputType: OutputType) {
        configuration.outputType = outputType
        guard let generatedDesign else { return }
        let package = exportService.makePackage(for: generatedDesign, outputType: outputType)
        exportPackage = package
        exportFolderURL = try? exportService.writePackageToTemporaryFolder(package)
    }

    func resetToDescribe() {
        selectedStep = .describe
        generatedDesign = nil
        exportPackage = nil
        exportFolderURL = nil
        generationProgress = 0
        progressMessage = progressMessages.first ?? "Reading your idea..."
    }
}

enum FlowStep: String, CaseIterable, Identifiable {
    case describe = "Describe"
    case generate = "Generate"
    case customize = "Customize"
    case preview = "Preview"
    case export = "Export"

    var id: String { rawValue }
}
