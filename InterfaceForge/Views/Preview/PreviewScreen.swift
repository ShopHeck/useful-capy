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
                    subtitle: "Try the live component, then adjust style controls to refresh the package.",
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

                    GlassCard(radius: 30) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 12) {
                                GradientIconBadge(systemImage: "arrow.triangle.2.circlepath", theme: viewModel.configuration.theme, size: 42)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Customize while you preview")
                                        .font(.headline)
                                    Text("Every control below updates this preview and rebuilds the export package so the copied code matches what you see.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            StyleControlsView()
                                .onChange(of: viewModel.configuration) { _, newValue in
                                    var refreshed = GeneratedDesign(
                                        template: design.template,
                                        prompt: design.prompt,
                                        configuration: newValue,
                                        headline: design.headline,
                                        subheadline: design.subheadline,
                                        createdAt: design.createdAt,
                                        kicker: design.kicker,
                                        primaryAction: design.primaryAction,
                                        secondaryAction: design.secondaryAction,
                                        sections: design.sections,
                                        metrics: design.metrics,
                                        formFields: design.formFields,
                                        reactCode: design.reactCode,
                                        htmlCode: design.htmlCode,
                                        cssCode: design.cssCode,
                                        swiftUICode: design.swiftUICode,
                                        generationMode: design.generationMode,
                                        generationStatus: design.generationStatus,
                                        generationError: design.generationError
                                    )
                                    refreshed.generationStatus = design.generationStatus
                                    viewModel.generatedDesign = refreshed
                                    viewModel.makeExportPackage(outputType: newValue.outputType)
                                }
                        }
                    }
                    .padding(.horizontal)

                    NavigationLink(value: AppRoute.export) {
                        Label("Export code package", systemImage: "shippingbox.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                            .background(viewModel.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: viewModel.configuration.theme.accent.opacity(0.28), radius: 22, y: 12)
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Export code package")
                    .accessibilityHint("Opens copy and share options for the generated files")
                } else {
                    ContentUnavailableView("No preview yet", systemImage: "wand.and.stars", description: Text("Generate an interface first, then come back here to test it."))
                }
            }
            .padding(.vertical, 18)
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
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    GradientIconBadge(systemImage: design.template.iconName, theme: viewModel.configuration.theme, size: 48)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(design.headline)
                            .font(.title3.weight(.black))
                            .fixedSize(horizontal: false, vertical: true)
                        Text("\(design.template.title) · \(design.generationMode.rawValue)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(viewModel.configuration.theme.accent)
                        Text(design.subheadline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if let error = design.generationError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Label(design.generationStatus, systemImage: "checkmark.seal.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                FlowLayout(spacing: 8) {
                    MetricPill(title: design.configuration.theme.rawValue, detail: "Theme", systemImage: "paintpalette", theme: viewModel.configuration.theme)
                    MetricPill(title: design.configuration.visualStyle.rawValue, detail: "Style", systemImage: "sparkles", theme: viewModel.configuration.theme)
                    MetricPill(title: design.configuration.outputType.rawValue, detail: "Export", systemImage: "doc.text", theme: viewModel.configuration.theme)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preview summary for \(design.template.title), \(design.configuration.theme.rawValue) theme, \(design.configuration.outputType.rawValue) export")
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
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(design.configuration.theme.darkGradient)
                        .frame(minHeight: 180)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(design.kicker)
                            .font(.caption.weight(.black))
                            .tracking(0.8)
                            .textCase(.uppercase)
                            .foregroundStyle(.white.opacity(0.78))
                        Text(design.headline)
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(design.subheadline)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(22)
                }

                if !design.metrics.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                        ForEach(design.metrics) { metric in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(metric.value)
                                    .font(.title2.weight(.black))
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
                        }
                    }
                }

                if !design.formFields.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(design.formFields) { field in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(field.label)
                                    .font(.caption.weight(.bold))
                                if field.kind == "textarea" {
                                    TextField(field.placeholder, text: .constant(""), axis: .vertical)
                                        .lineLimit(3, reservesSpace: true)
                                        .padding(14)
                                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                } else {
                                    TextField(field.placeholder, text: .constant(""))
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(field.kind == "email" ? .emailAddress : .default)
                                        .padding(14)
                                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                            }
                        }
                    }
                    .accessibilityElement(children: .contain)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(previewSections) { section in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: section.iconName.isEmpty ? "sparkles" : section.iconName)
                                .frame(width: 30, height: 30)
                                .foregroundStyle(.white)
                                .background(design.configuration.theme.gradient, in: Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(section.title)
                                    .font(.headline)
                                Text(section.detail)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        withAnimation(design.configuration.motionLevel.spring) {
                            submitted.toggle()
                        }
                    } label: {
                        Label(submitted ? "Ready" : design.primaryAction, systemImage: submitted ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(design.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(design.secondaryAction) { }
                        .font(.headline)
                        .buttonStyle(.bordered)
                        .tint(design.configuration.theme.accent)
                }
            }
        }
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
