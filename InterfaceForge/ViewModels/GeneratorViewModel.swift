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
            if !aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AnalyticsService.shared.track(.apiKeySet)
            }
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
        AnalyticsService.shared.track(.quickStartTap, properties: ["prompt": String(text.prefix(60))])
    }

    // MARK: - Entitlement-aware generation

    /// Check whether the user can generate right now.
    /// Returns a human-readable reason string if blocked, or nil if allowed.
    func generationBlockReason(storeKit: StoreKitManager, usage: UsageTracker) -> String? {
        if storeKit.isPro { return nil }
        let hasKey = !aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasKey && usage.canGenerateForFree { return nil }
        if hasKey && !usage.canGenerateForFree {
            return "You've used all \(UsageTracker.freeGenerationsPerDay) free generations today. Upgrade to Pro for unlimited."
        }
        // No key and not pro
        return nil // still allow generation — will fall back to template
    }

    func generate(historyStore: DesignHistoryStore? = nil, storeKit: StoreKitManager? = nil, usage: UsageTracker? = nil) async {
        generationTask?.cancel()
        let task = Task { [weak self] in
            await self?.runGeneration(historyStore: historyStore, storeKit: storeKit, usage: usage)
        }
        generationTask = task
        await task.value
    }

    // MARK: - Iterative refinement

    @Published var refinementPrompt: String = ""
    @Published var isRefining = false

    func refine(historyStore: DesignHistoryStore? = nil, storeKit: StoreKitManager? = nil, usage: UsageTracker? = nil) async {
        guard let existingDesign = generatedDesign else { return }
        let prompt = refinementPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }

        isRefining = true
        generationStatus = "Refining component..."

        let isPro = storeKit?.isPro ?? false
        let effectiveKey: String
        let effectiveEndpoint: String
        let effectiveModel: String

        if isPro && ProxyService.isConfigured, let proxyURL = ProxyService.baseURL {
            effectiveKey = "pro-proxy-token"
            effectiveEndpoint = proxyURL.absoluteString
            effectiveModel = ProxyService.defaultModel
        } else {
            effectiveKey = aiAPIKey
            effectiveEndpoint = aiEndpoint
            effectiveModel = aiModel
        }

        let refined = await generator.refine(
            existingDesign: existingDesign,
            refinementPrompt: prompt,
            apiKey: effectiveKey,
            endpoint: effectiveEndpoint,
            model: effectiveModel
        )

        generatedDesign = refined
        generationError = refined.generationError
        generationStatus = refined.generationStatus
        makeExportPackage(outputType: configuration.outputType)

        if !isPro {
            usage?.recordGeneration()
        }

        historyStore?.save(refined)
        refinementPrompt = ""
        isRefining = false

        AnalyticsService.shared.track(.refine)
    }

    func cancelGeneration() {
        generationTask?.cancel()
        AnalyticsService.shared.track(.cancelGeneration)
    }

    private func runGeneration(historyStore: DesignHistoryStore?, storeKit: StoreKitManager?, usage: UsageTracker?) async {
        isGenerating = true
        generationProgress = 0
        generationError = nil

        let isPro = storeKit?.isPro ?? false
        let hasKey = !aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if isPro && ProxyService.isConfigured {
            generationStatus = "Generating via Pro hosted AI."
        } else if hasKey {
            generationStatus = "Contacting the configured AI provider."
        } else {
            generationStatus = "AI unavailable until an API key is saved; a labeled fallback will be generated."
        }

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

        // Determine which key and endpoint to use
        let effectiveKey: String
        let effectiveEndpoint: String
        let effectiveModel: String

        if isPro && ProxyService.isConfigured, let proxyURL = ProxyService.baseURL {
            // Pro users go through the hosted proxy
            effectiveKey = "pro-proxy-token"  // The proxy handles auth via receipt
            effectiveEndpoint = proxyURL.absoluteString
            effectiveModel = ProxyService.defaultModel
        } else {
            // BYOK flow (free tier or proxy not configured)
            effectiveKey = aiAPIKey
            effectiveEndpoint = aiEndpoint
            effectiveModel = aiModel
        }

        let design = await generator.generate(
            prompt: prompt,
            selectedTemplate: selectedTemplate,
            configuration: configuration,
            apiKey: effectiveKey,
            endpoint: effectiveEndpoint,
            model: effectiveModel
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

        // Analytics
        AnalyticsService.shared.track(.generate)
        if design.generationMode == .ai {
            AnalyticsService.shared.track(.generateAI)
        } else {
            AnalyticsService.shared.track(.generateFallback)
        }

        // Track usage for free tier
        if !isPro {
            usage?.recordGeneration()
        }

        historyStore?.save(design)
    }

    func makeExportPackage(outputType: OutputType) {
        configuration.outputType = outputType
        guard let generatedDesign else { return }
        let package = exportService.makePackage(for: generatedDesign, outputType: outputType)
        exportPackage = package

        // Track export event with format
        AnalyticsService.shared.track(.export)
        switch outputType {
        case .react:    AnalyticsService.shared.track(.exportReact)
        case .html:     AnalyticsService.shared.track(.exportHTML)
        case .tailwind: AnalyticsService.shared.track(.exportTailwind)
        case .swiftUI:  AnalyticsService.shared.track(.exportSwiftUI)
        }
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
        AnalyticsService.shared.track(.connectionTest)
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
