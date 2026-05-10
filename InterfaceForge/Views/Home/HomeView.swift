import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                StepRail(activeStep: viewModel.selectedStep)
                    .padding(.horizontal, -16)

                VStack(alignment: .leading, spacing: 18) {
                    Label("InterfaceForge", systemImage: "hammer.circle.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(viewModel.configuration.theme.accent)

                    Text("Generate beautiful interactive UI and export usable code in one tap.")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .lineSpacing(-2)
                        .minimumScaleFactor(0.82)

                    Text("Describe what you need, choose a style, preview the live component, then share a beginner-ready code package for your website or app.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)

                    NavigationLink(value: AppRoute.composer) {
                        Label("Create an interface", systemImage: "sparkles")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .foregroundStyle(.white)
                            .background(viewModel.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .accessibilityLabel("Create an interface")
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 14) {
                    Text("One simple flow")
                        .font(.title2.weight(.bold))
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                        ForEach(FlowStep.allCases) { step in
                            GlassCard(radius: 24) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Image(systemName: icon(for: step))
                                        .font(.title2)
                                        .foregroundStyle(viewModel.configuration.theme.gradient)
                                    Text(step.rawValue)
                                        .font(.headline)
                                    Text(copy(for: step))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                GlassCard(radius: 30) {
                    HStack(alignment: .top, spacing: 16) {
                        Image(systemName: "shippingbox.fill")
                            .font(.largeTitle)
                            .foregroundStyle(viewModel.configuration.theme.gradient)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Export packages made for beginners")
                                .font(.title3.weight(.bold))
                            Text("Every export includes the component file, styles, and a plain-English README that explains exactly where the files go.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 22)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .onAppear { viewModel.selectedStep = .describe }
    }

    private func icon(for step: FlowStep) -> String {
        switch step {
        case .describe: return "text.bubble.fill"
        case .generate: return "wand.and.stars"
        case .customize: return "paintpalette.fill"
        case .preview: return "hand.tap.fill"
        case .export: return "square.and.arrow.up.fill"
        }
    }

    private func copy(for step: FlowStep) -> String {
        switch step {
        case .describe: return "Write one plain sentence or tap an example."
        case .generate: return "Local templates turn your idea into a component."
        case .customize: return "Pick color, style, motion, and code format."
        case .preview: return "Tap, swipe, and test the real interaction."
        case .export: return "Copy or share files with install steps included."
        }
    }
}
