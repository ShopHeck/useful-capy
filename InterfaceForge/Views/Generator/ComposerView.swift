import SwiftUI

struct ComposerView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    private var canGenerate: Bool {
        !viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.selectedTemplate != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepRail(activeStep: viewModel.selectedStep)
                    .padding(.horizontal, -16)

                SectionHeader(
                    "Describe the component",
                    eyebrow: "Create",
                    subtitle: "Start with a sentence or pick a template hint. AI generation uses your configured provider, with a labeled fallback when unavailable.",
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
                            subtitle: "Test the generated component before exporting.",
                            systemImage: "play.rectangle.fill",
                            theme: viewModel.configuration.theme
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                    .accessibilityLabel("Open interactive preview")
                    .accessibilityHint("Shows the generated component with live interactions")
                }
            }
            .padding(.vertical, 18)
        }
        .navigationTitle("Create")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .onAppear { viewModel.selectedStep = .describe }
    }

    private var promptCard: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    GradientIconBadge(systemImage: "pencil.and.scribble", theme: viewModel.configuration.theme, size: 42)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What should the UI do?")
                            .font(.headline)
                        Text("Mention the product, audience, or goal. Short prompts work well.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $viewModel.prompt)
                        .frame(minHeight: 132)
                        .padding(12)
                        .scrollContentBackground(.hidden)
                        .background(Color(.secondarySystemBackground).opacity(0.86), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(viewModel.configuration.theme.accent.opacity(viewModel.prompt.isEmpty ? 0.14 : 0.34), lineWidth: 1)
                        )
                        .accessibilityLabel("Describe your component")
                        .accessibilityHint("Type a short description such as a friendly pricing card for a design course")

                    if viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Example: A friendly pricing card for my design course with a clear start button")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding(.top, 20)
                            .padding(.leading, 18)
                            .padding(.trailing, 18)
                            .allowsHitTesting(false)
                    }
                }

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
            VStack(alignment: .leading, spacing: 8) {
                PrimaryButton(title: "Generate interface", systemImage: "wand.and.stars", theme: viewModel.configuration.theme, isEnabled: canGenerate) {
                    guard canGenerate else { return }
                    Task { await viewModel.generate() }
                }
                .accessibilityHint(canGenerate ? "Sends the prompt to the configured AI provider when an API key is available, otherwise creates a labeled fallback" : "Add a prompt or select a template first")

                GenerationStatusView()

                if viewModel.generatedDesign != nil {
                    Text("Generated. Continue to preview, or adjust customization and generate again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct AIEngineSettingsCard: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    GradientIconBadge(systemImage: "network", theme: viewModel.configuration.theme, size: 42)
                    SectionHeader(
                        "AI engine",
                        eyebrow: "Provider settings",
                        subtitle: "Prompts are sent to the OpenAI-compatible endpoint below. If no valid key is available, InterfaceForge uses a labeled template fallback instead of presenting it as AI output.",
                        theme: viewModel.configuration.theme
                    )
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("API key")
                        .font(.caption.weight(.bold))
                    SecureField("sk-...", text: $viewModel.aiAPIKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(13)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("AI provider API key")
                    Text("Stored on this device with app storage for the MVP. Do not enter a shared or public key.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Endpoint")
                        .font(.caption.weight(.bold))
                    TextField("https://api.openai.com/v1/chat/completions", text: $viewModel.aiEndpoint)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .padding(13)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("AI chat completions endpoint")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.caption.weight(.bold))
                    TextField("gpt-4.1-mini", text: $viewModel.aiModel)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(13)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .accessibilityLabel("AI model name")
                }
            }
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
        } else {
            Label(viewModel.generationStatus, systemImage: viewModel.aiAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "key.slash" : "checkmark.seal.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct TemplatePicker: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                "Choose a starting point",
                subtitle: "Optional hint for the AI engine. The prompt still has priority, and fallback uses this when AI is unavailable.",
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
                        .foregroundStyle(isSelected ? .white.opacity(0.84) : .secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text(isSelected ? "Selected template" : "Tap to select")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .foregroundStyle(isSelected ? viewModel.configuration.theme.accent : .secondary)
                    .background(isSelected ? AnyShapeStyle(Color.white) : AnyShapeStyle(.thinMaterial), in: Capsule())
            }
            .frame(width: 190, minHeight: 176, alignment: .topLeading)
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
        .accessibilityHint(isSelected ? "Selected template" : "Selects this template for generation")
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
                        "Customize",
                        eyebrow: "Live style",
                        subtitle: "Changes refresh the preview and export package when a component exists.",
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
    @State private var sparkle = false

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    GradientIconBadge(systemImage: "sparkles", theme: viewModel.configuration.theme, size: 44)
                        .scaleEffect(sparkle ? 1.08 : 0.94)
                        .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: sparkle)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Generating with AI engine")
                            .font(.headline)
                        Text(viewModel.progressMessage)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                ProgressView(value: viewModel.generationProgress)
                    .tint(viewModel.configuration.theme.accent)
            }
        }
        .onAppear { sparkle = true }
        .accessibilityLabel("Generation progress")
        .accessibilityHint("Uses the configured AI provider when available and reports fallback status when unavailable")
    }
}
