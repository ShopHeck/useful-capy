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
    @Published var generationError: String?
    @Published var generationStatus = "Add an API key to enable AI-powered generation."
    @Published var selectedStep: FlowStep = .describe

    @AppStorage("interfaceforge.ai.apiKey") var aiAPIKey: String = ""
    @AppStorage("interfaceforge.ai.endpoint") var aiEndpoint: String = "https://api.openai.com/v1/chat/completions"
    @AppStorage("interfaceforge.ai.model") var aiModel: String = "gpt-4.1-mini"

    let quickStartPrompts = [
        "SaaS pricing card",
        "AI dashboard widget",
        "Mobile onboarding hero",
        "Checkout form",
        "Portfolio project card"
    ]

    let progressMessages = [
        "Reading your idea and style settings...",
        "Asking the configured AI engine for a structured UI spec...",
        "Validating the returned JSON component data...",
        "Building a responsive preview from the spec...",
        "Assembling export-ready code files..."
    ]

    private let generator = DesignGenerator()
    private let exportService = CodeExportService()

    func useQuickStart(_ text: String) {
        prompt = text
        selectedTemplate = generator.matchedTemplate(for: text, selectedTemplate: nil)
        selectedStep = .describe
    }

    func generate(historyStore: DesignHistoryStore? = nil) async {
        isGenerating = true
        generationProgress = 0
        generationError = nil
        generationStatus = aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "AI unavailable until an API key is saved; a labeled fallback will be generated." : "Contacting the configured AI provider."
        selectedStep = .generate

        for index in progressMessages.indices {
            progressMessage = progressMessages[index]
            generationProgress = Double(index + 1) / Double(progressMessages.count + 1)
            try? await Task.sleep(nanoseconds: 320_000_000)
        }

        let design = await generator.generate(
            prompt: prompt,
            selectedTemplate: selectedTemplate,
            configuration: configuration,
            apiKey: aiAPIKey,
            endpoint: aiEndpoint,
            model: aiModel
        )
        generatedDesign = design
        generationError = design.generationError
        generationStatus = design.generationStatus
        generationProgress = 1
        makeExportPackage(outputType: configuration.outputType)
        isGenerating = false
        selectedStep = .preview

        historyStore?.save(design)
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
        generationError = nil
        generationStatus = aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Add an API key to enable AI-powered generation." : "AI engine configured."
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
