import SwiftUI

struct ComposerView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @EnvironmentObject private var historyStore: DesignHistoryStore
    @EnvironmentObject private var promptStore: PromptLibraryStore
    @EnvironmentObject private var storeKit: StoreKitManager
    @EnvironmentObject private var usageTracker: UsageTracker

    private var canGenerate: Bool {
        !viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.selectedTemplate != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepRail(activeStep: viewModel.selectedStep)
                    .padding(.horizontal, -16)

                SectionHeader(
                    "Create an interface",
                    eyebrow: "Guided AI setup",
                    subtitle: "Describe the result you want, then connect your OpenAI-compatible provider when you are ready. Missing or failed AI calls produce a clearly labeled template fallback.",
                    systemImage: "text.bubble.fill",
                    theme: viewModel.configuration.theme
                )
                .padding(.horizontal)

                promptCard
                    .padding(.horizontal)

                AIEngineSettingsCard()
                    .padding(.horizontal)

                TemplatePicker()
                    .padding(.horizontal)

                StyleControlsView()
                    .padding(.horizontal)

                generationAction

                if viewModel.generatedDesign != nil, !viewModel.isGenerating {
                    NavigationLink(value: AppRoute.preview) {
                        SecondaryLinkRow(
                            title: "Open interactive preview",
                            subtitle: "Review the generated component, AI or fallback status, and tap states before exporting.",
                            systemImage: "play.rectangle.fill",
                            theme: viewModel.configuration.theme
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .accessibilityLabel("Open interactive preview")
                    .accessibilityHint("Shows the generated component with live interactions and generation status")
                }
            }
            .readableContentFrame(maxWidth: 980)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .onAppear { viewModel.selectedStep = .describe }
    }

    private var promptCard: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    GradientIconBadge(systemImage: "pencil.and.scribble", theme: viewModel.configuration.theme, size: 42)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tell InterfaceForge what to make")
                            .font(.headline)
                        Text("Plain language is enough. Mention the audience, product, state, or conversion goal when it matters.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.prompt)
                        .frame(minHeight: 144)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(Color(.secondarySystemBackground).opacity(0.86), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(viewModel.configuration.theme.accent.opacity(viewModel.prompt.isEmpty ? 0.16 : 0.40), lineWidth: 1)
                        )
                        .accessibilityLabel("Interface prompt")
                        .accessibilityHint("Type a short description such as a waitlist hero for a space tourism startup with safety stats")

                    if viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Example: A waitlist hero for a space tourism startup with signup form and safety stats")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 20)
                            .padding(.leading, 18)
                            .padding(.trailing, 18)
                            .allowsHitTesting(false)
                    }
                }

                InfoCallout(
                    title: "What gets sent",
                    message: "When you generate with a key, the prompt, selected template hint, style choices, endpoint, and model are used for a remote provider request.",
                    systemImage: "paperplane.fill",
                    theme: viewModel.configuration.theme
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick starts")
                        .font(.subheadline.weight(.bold))
                    FlowLayout(spacing: 8) {
                        ForEach(viewModel.quickStartPrompts, id: \.self) { prompt in
                            Chip(title: prompt, isSelected: viewModel.prompt == prompt, theme: viewModel.configuration.theme) {
                                viewModel.useQuickStart(prompt)
                            }
                        }
                    }
                }

                if !viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        let name = viewModel.prompt
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .components(separatedBy: " ")
                            .prefix(6)
                            .joined(separator: " ")
                        promptStore.save(SavedPrompt(name: name, text: viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines)))
                    } label: {
                        Label("Save to prompt library", systemImage: "bookmark")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.configuration.theme.accent)
                    .accessibilityLabel("Save this prompt to your library")
                }

                if !canGenerate {
                    Label("Add a prompt or select a template to enable generation.", systemImage: "info.circle")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Add a prompt or select a template to enable generation")
                }
            }
        }
    }

    @ViewBuilder
    private var generationAction: some View {
        if viewModel.isGenerating {
            GenerationProgressView()
                .padding(.horizontal)
        } else {
            GlassCard(radius: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    PrimaryButton(title: "Generate interface", systemImage: "wand.and.stars", theme: viewModel.configuration.theme, isEnabled: canGenerate) {
                        guard canGenerate else { return }
                        Task { await viewModel.generate(historyStore: historyStore, storeKit: storeKit, usage: usageTracker) }
                    }
                    .accessibilityHint(canGenerate ? "Sends the prompt to the configured provider when an API key is available, otherwise creates a labeled template fallback" : "Add a prompt or select a template first")

                    // Free-tier usage indicator
                    if !storeKit.isPro {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkle")
                                .foregroundStyle(usageTracker.canGenerateForFree ? viewModel.configuration.theme.accent : .orange)
                            Text("\(usageTracker.freeGenerationsRemaining) free generation\(usageTracker.freeGenerationsRemaining == 1 ? "" : "s") left today")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            NavigationLink(value: AppRoute.paywall) {
                                Text("Go Pro")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(viewModel.configuration.theme.gradient, in: Capsule())
                            }
                        }
                        .padding(.top, 4)
                    }

                    GenerationStatusView()

                    if viewModel.generatedDesign != nil {
                        Text("Generated. Continue to preview, or adjust style choices and generate again.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct AIEngineSettingsCard: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    private var hasKey: Bool {
        !viewModel.aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    GradientIconBadge(systemImage: "lock.shield.fill", theme: viewModel.configuration.theme, size: 42)
                    SectionHeader(
                        "AI provider connection",
                        eyebrow: "Your key, your provider",
                        subtitle: "InterfaceForge calls the OpenAI-compatible chat completions endpoint you configure. Your API key is stored in the iOS Keychain on this device, and only HTTPS endpoints (or localhost during development) are allowed.",
                        theme: viewModel.configuration.theme
                    )
                }

                FlowLayout(spacing: 8) {
                    StatusBadge(title: hasKey ? "Key added" : "No key yet", detail: hasKey ? "Remote AI enabled" : "Fallback available", systemImage: hasKey ? "checkmark.seal.fill" : "key.slash.fill", tint: hasKey ? .green : .orange)
                    StatusBadge(title: "Endpoint", detail: "Chat completions", systemImage: "network", tint: viewModel.configuration.theme.accent)
                    StatusBadge(title: "Model", detail: viewModel.aiModel.isEmpty ? "Default allowed" : viewModel.aiModel, systemImage: "cpu.fill", tint: viewModel.configuration.theme.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ProviderField(
                        title: "API key",
                        helper: "Use a private provider key. Do not enter a shared or public key.",
                        systemImage: "key.fill",
                        theme: viewModel.configuration.theme
                    ) {
                        SecureField("Paste provider key", text: $viewModel.aiAPIKey)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityLabel("AI provider API key")
                            .accessibilityHint("Stored securely in the iOS Keychain on this device")
                    }

                    ProviderField(
                        title: "Chat completions endpoint",
                        helper: "Default: https://api.openai.com/v1/chat/completions. Compatible providers may use a different URL.",
                        systemImage: "link",
                        theme: viewModel.configuration.theme
                    ) {
                        TextField("https://api.openai.com/v1/chat/completions", text: $viewModel.aiEndpoint)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                            .accessibilityLabel("AI chat completions endpoint")
                            .accessibilityHint("Prompts are sent to this remote endpoint during AI generation")
                    }

                    ProviderField(
                        title: "Model",
                        helper: "Use a model string supported by your provider, such as gpt-4.1-mini.",
                        systemImage: "cpu",
                        theme: viewModel.configuration.theme
                    ) {
                        TextField("gpt-4.1-mini", text: $viewModel.aiModel)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .accessibilityLabel("AI model name")
                            .accessibilityHint("Model used by the configured provider request")
                    }
                }

                InfoCallout(
                    title: "Fallback stays honest",
                    message: "If the key is missing, the endpoint fails, or the provider returns unusable JSON, the preview and export are labeled as template fallback starter code.",
                    systemImage: "tag.fill",
                    theme: viewModel.configuration.theme
                )

                HStack(spacing: 8) {
                    Button {
                        Task { await viewModel.testConnection() }
                    } label: {
                        Label("Test connection", systemImage: "bolt.horizontal.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.configuration.theme.accent)
                    .accessibilityHint("Validates that the endpoint URL is HTTPS and a key is present, without spending API credits")

                    if let status = viewModel.connectionTestStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

private struct ProviderField<Content: View>: View {
    let title: String
    let helper: String
    let systemImage: String
    let theme: ColorTheme
    let content: Content

    init(title: String, helper: String, systemImage: String, theme: ColorTheme, @ViewBuilder content: () -> Content) {
        self.title = title
        self.helper = helper
        self.systemImage = systemImage
        self.theme = theme
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
            content
                .font(.body)
                .padding(14)
                .frame(minHeight: 48)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.accent.opacity(0.16), lineWidth: 1)
                )
            Text(helper)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct GenerationStatusView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        if let error = viewModel.generationError {
            Label(error, systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Generation fallback status. \(error)")
        } else {
            Label(viewModel.generationStatus, systemImage: viewModel.aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "key.slash" : "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityLabel("Generation status. \(viewModel.generationStatus)")
        }
    }
}

struct TemplatePicker: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 14) {
                SectionHeader(
                    "Choose a starting point",
                    subtitle: "Optional. A template helps set structure, but your prompt still has priority when remote AI generation succeeds.",
                    systemImage: "rectangle.stack.fill",
                    theme: viewModel.configuration.theme
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(DesignTemplate.all) { template in
                            TemplateCard(template: template, isSelected: viewModel.selectedTemplate?.id == template.id) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                                    viewModel.selectedTemplate = template
                                }
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .accessibilityLabel("Template choices")
            }
        }
    }
}

private struct TemplateCard: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    let template: DesignTemplate
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    GradientIconBadge(systemImage: template.iconName, theme: viewModel.configuration.theme, size: 42)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .accessibilityHidden(true)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(template.title)
                        .font(.headline)
                    Text(template.shortDescription)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.86) : .secondary)
                        .lineLimit(4)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(isSelected ? "Selected template" : "Use as hint")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .foregroundStyle(isSelected ? viewModel.configuration.theme.accent : .secondary)
                    .background(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(.thinMaterial), in: Capsule())
            }
            .frame(width: 210, minHeight: 184, alignment: .topLeading)
            .padding(16)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(isSelected ? Color.white.opacity(0.34) : Color.white.opacity(0.26), lineWidth: 1)
            )
            .shadow(color: viewModel.configuration.theme.accent.opacity(isSelected ? 0.24 : 0.08), radius: isSelected ? 22 : 12, y: isSelected ? 12 : 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Template \(template.title)")
        .accessibilityHint(isSelected ? "Selected as a structure hint" : "Selects this template as an optional generation hint")
    }

    private var cardBackground: some ShapeStyle {
        isSelected ? AnyShapeStyle(viewModel.configuration.theme.gradient) : AnyShapeStyle(.ultraThinMaterial)
    }
}

struct StyleControlsView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 12) {
                    GradientIconBadge(systemImage: "slider.horizontal.3", theme: viewModel.configuration.theme, size: 42)
                    SectionHeader(
                        "Customize output",
                        eyebrow: "Live style",
                        subtitle: "These choices shape the preview and the next export package.",
                        theme: viewModel.configuration.theme
                    )
                    Spacer(minLength: 0)
                }

                ControlChipGroup(
                    title: "Color theme",
                    options: ColorTheme.allCases,
                    selection: $viewModel.configuration.theme,
                    theme: viewModel.configuration.theme,
                    label: { $0.rawValue }
                )
                .accessibilityLabel("Color theme")

                ControlChipGroup(
                    title: "Visual style",
                    options: VisualStyle.allCases,
                    selection: $viewModel.configuration.visualStyle,
                    theme: viewModel.configuration.theme,
                    label: { $0.rawValue }
                )
                .accessibilityLabel("Visual style")

                ControlChipGroup(
                    title: "Motion level",
                    options: MotionLevel.allCases,
                    selection: $viewModel.configuration.motionLevel,
                    theme: viewModel.configuration.theme,
                    label: { $0.rawValue }
                )
                .accessibilityLabel("Motion level")

                ControlChipGroup(
                    title: "Export format",
                    options: OutputType.allCases,
                    selection: $viewModel.configuration.outputType,
                    theme: viewModel.configuration.theme,
                    label: { $0.rawValue }
                )
                .accessibilityLabel("Target platform or output type")
            }
        }
    }
}

private struct ControlChipGroup<Value: Hashable & Identifiable>: View {
    let title: String
    let options: [Value]
    @Binding var selection: Value
    let theme: ColorTheme
    let label: (Value) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.subheadline.weight(.black))
            FlowLayout(spacing: 8) {
                ForEach(options) { option in
                    Chip(title: label(option), isSelected: selection == option, theme: theme) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            selection = option
                        }
                    }
                }
            }
        }
    }
}

struct GenerationProgressView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sparkle = false

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    GradientIconBadge(systemImage: "sparkles", theme: viewModel.configuration.theme, size: 44)
                        .scaleEffect(sparkle && !reduceMotion ? 1.08 : 0.96)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: sparkle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Generating with configured provider")
                            .font(.headline)
                        Text(viewModel.progressMessage)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                ProgressView(value: viewModel.generationProgress)
                    .tint(viewModel.configuration.theme.accent)

                Button(role: .cancel) {
                    viewModel.cancelGeneration()
                } label: {
                    Label("Cancel generation", systemImage: "xmark.circle.fill")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Stops the in-flight provider request and clears progress")
            }
        }
        .onAppear { sparkle = true }
        .accessibilityLabel("Generation progress")
        .accessibilityHint("Uses the configured AI provider when available and reports fallback status when unavailable")
    }
}
