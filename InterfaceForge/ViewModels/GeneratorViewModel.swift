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
    @Published var exportError: String?
    @Published var isGenerating = false
    @Published var progressMessage = "Reading your idea..."
    @Published var generationProgress = 0.0
    @Published var generationError: String?
    @Published var generationStatus = "Add an API key to enable AI-powered generation."
    @Published var selectedStep: FlowStep = .describe
    @Published var connectionTestStatus: String?

    @Published var aiAPIKey: String = "" {
        didSet {
            guard aiAPIKey != oldValue else { return }
            KeychainStore.shared.set(aiAPIKey, for: .aiAPIKey)
        }
    }

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
    private var generationTask: Task<Void, Never>?

    init() {
        KeychainStore.shared.migrateLegacyDefaultsKeyIfNeeded()
        aiAPIKey = KeychainStore.shared.string(for: .aiAPIKey)
    }

    func useQuickStart(_ text: String) {
        prompt = text
        selectedTemplate = generator.matchedTemplate(for: text, selectedTemplate: nil)
        selectedStep = .describe
    }

    func generate(historyStore: DesignHistoryStore? = nil) async {
        generationTask?.cancel()
        let task = Task { [weak self] in
            await self?.runGeneration(historyStore: historyStore)
        }
        generationTask = task
        await task.value
    }

    func cancelGeneration() {
        generationTask?.cancel()
    }

    private func runGeneration(historyStore: DesignHistoryStore?) async {
        isGenerating = true
        generationProgress = 0
        generationError = nil
        generationStatus = aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "AI unavailable until an API key is saved; a labeled fallback will be generated." : "Contacting the configured AI provider."
        selectedStep = .generate

        for index in progressMessages.indices {
            if Task.isCancelled { break }
            progressMessage = progressMessages[index]
            generationProgress = Double(index + 1) / Double(progressMessages.count + 1)
            try? await Task.sleep(nanoseconds: 320_000_000)
        }

        if Task.isCancelled {
            isGenerating = false
            generationStatus = "Generation cancelled."
            return
        }

        let design = await generator.generate(
            prompt: prompt,
            selectedTemplate: selectedTemplate,
            configuration: configuration,
            apiKey: aiAPIKey,
            endpoint: aiEndpoint,
            model: aiModel
        )

        if Task.isCancelled {
            isGenerating = false
            generationStatus = "Generation cancelled."
            return
        }

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
        do {
            exportFolderURL = try exportService.writePackageToTemporaryFolder(package)
            exportError = nil
        } catch {
            exportFolderURL = nil
            exportError = "Couldn't stage shareable folder: \(error.localizedDescription). You can still copy code from the file previews."
        }
    }

    func testConnection() async {
        let key = aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            connectionTestStatus = "Add an API key first."
            return
        }
        connectionTestStatus = "Testing endpoint..."
        let result = await generator.validateEndpoint(endpoint: aiEndpoint, apiKey: key)
        connectionTestStatus = result
    }

    func resetToDescribe() {
        selectedStep = .describe
        generatedDesign = nil
        exportPackage = nil
        exportFolderURL = nil
        exportError = nil
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
