import SwiftUI

struct PreviewScreen: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepRail(activeStep: .preview)
                    .padding(.horizontal, -16)

                SectionHeader(
                    "Interactive preview",
                    eyebrow: "Test before export",
                    subtitle: "Confirm the generated content, AI or fallback status, responsive sections, and tap states before sharing starter files.",
                    systemImage: "play.rectangle.fill",
                    theme: viewModel.configuration.theme
                )
                .padding(.horizontal)

                if let design = viewModel.generatedDesign {
                    PreviewSummaryCard(design: design)
                        .padding(.horizontal)

                    InteractiveComponentView(design: design)
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))

                    LiveEditPanel()
                        .padding(.horizontal)

                    StyleControlsView()
                        .padding(.horizontal)
                        .onChange(of: viewModel.configuration) { _, newValue in
                            viewModel.updateConfiguration(newValue)
                        }

                    NavigationLink(value: AppRoute.export) {
                        Label("Export starter package", systemImage: "shippingbox.fill")
                            .font(.headline)
                            .frame(maxWidth: 480)
                            .frame(minHeight: 54)
                            .foregroundStyle(.white)
                            .background(viewModel.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: viewModel.configuration.theme.accent.opacity(0.28), radius: 22, y: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .accessibilityLabel("Export starter package")
                    .accessibilityHint("Opens copy and share options for the generated files")
                } else {
                    ContentUnavailableView("No preview yet", systemImage: "wand.and.stars", description: Text("Generate an interface first, then come back here to test it."))
                        .padding(.horizontal)
                }
            }
            .readableContentFrame(maxWidth: 1080)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Preview")
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .onAppear { viewModel.selectedStep = .preview }
    }
}

private struct PreviewSummaryCard: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    let design: GeneratedDesign

    var body: some View {
        GlassCard(radius: 30) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    GradientIconBadge(systemImage: design.template.iconName, theme: viewModel.configuration.theme, size: 48)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(design.headline)
                            .font(.title3.weight(.black))
                            .fixedSize(horizontal: false, vertical: true)
                        FlowLayout(spacing: 8) {
                            GenerationModeBadge(design: design, theme: viewModel.configuration.theme)
                            MetricPill(title: design.template.title, detail: "Component", systemImage: "rectangle.stack", theme: viewModel.configuration.theme)
                        }
                        Text(design.subheadline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let error = design.generationError {
                    InfoCallout(title: "Template fallback active", message: error, systemImage: "exclamationmark.triangle.fill", theme: viewModel.configuration.theme)
                        .accessibilityLabel("Fallback status. \(error)")
                } else {
                    InfoCallout(title: "AI output active", message: design.generationStatus, systemImage: "checkmark.seal.fill", theme: viewModel.configuration.theme)
                        .accessibilityLabel("AI output status. \(design.generationStatus)")
                }

                FlowLayout(spacing: 8) {
                    MetricPill(title: design.configuration.theme.rawValue, detail: "Theme", systemImage: "paintpalette", theme: viewModel.configuration.theme)
                    MetricPill(title: design.configuration.visualStyle.rawValue, detail: "Style", systemImage: "sparkles", theme: viewModel.configuration.theme)
                    MetricPill(title: design.configuration.outputType.rawValue, detail: "Export", systemImage: "doc.text", theme: viewModel.configuration.theme)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preview summary for \(design.template.title), \(design.generationMode.rawValue), \(design.configuration.outputType.rawValue) export")
    }
}

private struct GenerationModeBadge: View {
    let design: GeneratedDesign
    let theme: ColorTheme

    var body: some View {
        let tint: Color = design.generationMode == .ai ? theme.accent : .orange
        StatusBadge(
            title: design.generationMode.rawValue,
            detail: design.generationMode == .ai ? "Provider generated" : "Clearly labeled",
            systemImage: design.generationMode == .ai ? "sparkles" : "tag.fill",
            tint: tint
        )
    }
}

struct InteractiveComponentView: View {
    let design: GeneratedDesign

    var body: some View {
        if design.generationMode == .ai {
            AdaptiveAIPreview(design: design)
        } else {
            switch design.template.id {
            case "pricing-card": PricingCardPreview(design: design)
            case "dashboard-widget": DashboardWidgetPreview(design: design)
            case "onboarding-hero": OnboardingHeroPreview(design: design)
            case "checkout-form": CheckoutFormPreview(design: design)
            case "portfolio-card": PortfolioCardPreview(design: design)
            default: AdaptiveAIPreview(design: design)
            }
        }
    }
}

private struct AdaptiveAIPreview: View {
    let design: GeneratedDesign
    @State private var submitted = false

    var body: some View {
        GlassCard(radius: design.configuration.visualStyle.cornerRadius) {
            VStack(alignment: .leading, spacing: 20) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        heroPanel
                            .frame(maxWidth: 520)
                        VStack(alignment: .leading, spacing: 14) {
                            modeStrip
                            metricsBlock
                        }
                        .frame(maxWidth: 360, alignment: .topLeading)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        heroPanel
                        modeStrip
                        metricsBlock
                    }
                }

                if !design.formFields.isEmpty {
                    formBlock
                }

                sectionsBlock
                actionRow
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Adaptive preview for \(design.headline). \(design.generationMode.rawValue).")
    }

    private var heroPanel: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(design.configuration.theme.darkGradient)
                .frame(minHeight: 210)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: design.generationMode == .ai ? "sparkles" : "tag.fill")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.72))
                        .padding(20)
                        .accessibilityHidden(true)
                }
            VStack(alignment: .leading, spacing: 10) {
                Text(design.kicker)
                    .font(.caption.weight(.black))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(.white.opacity(0.80))
                Text(design.headline)
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(design.subheadline)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.84))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
        }
    }

    private var modeStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preview source")
                .font(.caption.weight(.black))
                .foregroundStyle(design.configuration.theme.accent)
                .textCase(.uppercase)
            Text(design.generationMode == .ai ? "Prompt-specific AI output" : "Template fallback output")
                .font(.headline)
            Text(design.generationMode == .ai ? "Generated from the structured provider response and ready for starter-code export." : "Built from local fallback templates because AI generation was unavailable.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var metricsBlock: some View {
        if !design.metrics.isEmpty {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 116), spacing: 10)], spacing: 10) {
                ForEach(design.metrics) { metric in
                    MetricTile(metric: metric, theme: design.configuration.theme)
                }
            }
        }
    }

    private var formBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated form fields")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ForEach(design.formFields) { field in
                    GeneratedFieldView(field: field)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var sectionsBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated structure")
                .font(.headline)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 12)], spacing: 12) {
                ForEach(previewSections) { section in
                    PreviewSectionTile(section: section, theme: design.configuration.theme)
                }
            }
        }
    }

    private var actionRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                primaryActionButton
                secondaryActionButton
            }
            VStack(spacing: 12) {
                primaryActionButton
                secondaryActionButton
            }
        }
    }

    private var primaryActionButton: some View {
        Button {
            withAnimation(design.configuration.motionLevel.spring) {
                submitted.toggle()
            }
        } label: {
            Label(submitted ? "Ready" : design.primaryAction, systemImage: submitted ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 50)
                .foregroundStyle(.white)
                .background(design.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(submitted ? "Primary preview action complete" : "Primary preview action, \(design.primaryAction)")
        .accessibilityHint("Toggles the preview action state")
    }

    private var secondaryActionButton: some View {
        Button(design.secondaryAction) { }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .buttonStyle(.bordered)
            .tint(design.configuration.theme.accent)
            .accessibilityLabel("Secondary preview action, \(design.secondaryAction)")
    }

    private var previewSections: [GeneratedSection] {
        if !design.sections.isEmpty { return design.sections }
        return [
            GeneratedSection(title: "Prompt-specific layout", detail: "AI output can render arbitrary component content here."),
            GeneratedSection(title: "Export ready", detail: "The same structured fields feed React, HTML, CSS, and SwiftUI exports."),
            GeneratedSection(title: "Accessible by default", detail: "The preview favors clear labels, readable spacing, and large touch targets.")
        ]
    }
}

private struct MetricTile: View {
    let metric: GeneratedMetric
    let theme: ColorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(metric.value)
                .font(.title2.weight(.black))
                .minimumScaleFactor(0.8)
            Text(metric.label)
                .font(.caption)
                .foregroundStyle(.secondary)
            if !metric.trend.isEmpty {
                Text(metric.trend)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(theme.accent.opacity(0.14), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Metric \(metric.label), \(metric.value) \(metric.trend)")
    }
}

private struct GeneratedFieldView: View {
    let field: GeneratedFormField

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(field.required ? "\(field.label) required" : field.label)
                .font(.caption.weight(.bold))
            if field.kind == "textarea" {
                TextField(field.placeholder, text: .constant(""), axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel(field.label)
            } else {
                TextField(field.placeholder, text: .constant(""))
                    .textInputAutocapitalization(.never)
                    .keyboardType(field.kind == "email" ? .emailAddress : .default)
                    .padding(14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel(field.label)
            }
        }
    }
}

private struct PreviewSectionTile: View {
    let section: GeneratedSection
    let theme: ColorTheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: section.iconName.isEmpty ? "sparkles" : section.iconName)
                .font(.subheadline.weight(.bold))
                .frame(width: 34, height: 34)
                .foregroundStyle(.white)
                .background(theme.gradient, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(.headline)
                Text(section.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

private struct LiveEditPanel: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        GlassCard(radius: 28) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    GradientIconBadge(systemImage: "pencil.line", theme: viewModel.configuration.theme, size: 42)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Edit live")
                            .font(.headline)
                        Text("Tweak the copy. The preview and the export package update as you type.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                EditField(label: "Kicker", placeholder: "Short eyebrow text", binding: textBinding(\.kicker))
                EditField(label: "Headline", placeholder: "Main title", binding: textBinding(\.headline))
                EditField(label: "Subheadline", placeholder: "Supporting copy", binding: textBinding(\.subheadline), multiline: true)
                EditField(label: "Primary action", placeholder: "Button label", binding: textBinding(\.primaryAction))
                EditField(label: "Secondary action", placeholder: "Link or secondary button", binding: textBinding(\.secondaryAction))

                HStack(spacing: 10) {
                    Button {
                        viewModel.cycleThemeVariant()
                    } label: {
                        Label("Cycle theme", systemImage: "paintpalette.fill")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.configuration.theme.accent)
                    .accessibilityHint("Switches to the next color theme and rebuilds the export")

                    Button(role: .destructive) {
                        viewModel.resetEdits()
                    } label: {
                        Label("Reset edits", systemImage: "arrow.uturn.backward")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .disabled(!viewModel.hasEdits)
                    .accessibilityHint("Restores the original generated copy and theme")
                }
            }
        }
    }

    private func textBinding(_ keyPath: WritableKeyPath<GeneratedDesign, String>) -> Binding<String> {
        Binding(
            get: { viewModel.generatedDesign?[keyPath: keyPath] ?? "" },
            set: { viewModel.updateDesignText(keyPath, to: $0) }
        )
    }
}

private struct EditField: View {
    let label: String
    let placeholder: String
    @Binding var binding: String
    var multiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            if multiline {
                TextField(placeholder, text: $binding, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(label)
            } else {
                TextField(placeholder, text: $binding)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(label)
            }
        }
    }
}
