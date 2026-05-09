import SwiftUI

struct PreviewScreen: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                StepRail(activeStep: .preview)
                    .padding(.horizontal, -16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Interactive preview")
                        .font(.largeTitle.weight(.black))
                    Text("Tap, swipe, and test the generated component before exporting it.")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)

                if let design = viewModel.generatedDesign {
                    InteractiveComponentView(design: design)
                        .padding(.horizontal)
                        .transition(.scale.combined(with: .opacity))

                    StyleControlsView()
                        .padding(.horizontal)
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

                    NavigationLink(value: AppRoute.export) {
                        Label("Export code package", systemImage: "shippingbox.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                            .background(viewModel.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .padding(.horizontal)
                    .accessibilityLabel("Export code package")
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
