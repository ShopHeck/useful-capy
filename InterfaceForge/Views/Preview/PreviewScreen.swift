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
                                    let refreshed = GeneratedDesign(
                                        template: design.template,
                                        prompt: design.prompt,
                                        configuration: newValue,
                                        headline: design.headline,
                                        subheadline: design.subheadline,
                                        createdAt: design.createdAt
                                    )
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
                        Text(design.template.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(viewModel.configuration.theme.accent)
                        Text(design.subheadline)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
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
        switch design.template.id {
        case "pricing-card": PricingCardPreview(design: design)
        case "dashboard-widget": DashboardWidgetPreview(design: design)
        case "onboarding-hero": OnboardingHeroPreview(design: design)
        case "checkout-form": CheckoutFormPreview(design: design)
        case "portfolio-card": PortfolioCardPreview(design: design)
        default: PricingCardPreview(design: design)
        }
    }
}
