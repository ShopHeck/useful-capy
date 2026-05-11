import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                StepRail(activeStep: viewModel.selectedStep)
                    .padding(.horizontal, -16)

                hero
                    .padding(.horizontal)

                flowSection
                    .padding(.horizontal)

                proofSection
                    .padding(.horizontal)
            }
            .padding(.vertical, 22)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .onAppear { viewModel.selectedStep = .describe }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                GradientIconBadge(systemImage: "hammer.fill", theme: viewModel.configuration.theme, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text("INTERFACEFORGE")
                        .font(.caption.weight(.black))
                        .tracking(0.8)
                        .foregroundStyle(viewModel.configuration.theme.accent)
                    Text("AI UI generator")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("InterfaceForge, AI UI generator")

            Text("Turn a plain idea into a polished interface package.")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .lineLimit(4)
                .minimumScaleFactor(0.72)
                .fixedSize(horizontal: false, vertical: true)

            Text("Describe a component, tune the style, test the interaction, then copy or share beginner-ready files. Bring your own OpenAI-compatible API key, or use clearly labeled fallback templates when AI is unavailable.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink(value: AppRoute.composer) {
                Label("Create an interface", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .foregroundStyle(.white)
                    .background(viewModel.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: viewModel.configuration.theme.accent.opacity(0.28), radius: 24, y: 14)
            }
            .accessibilityLabel("Create an interface")
            .accessibilityHint("Opens the prompt composer")

            FlowLayout(spacing: 8) {
                MetricPill(title: "AI", detail: "Bring your key", systemImage: "network", theme: viewModel.configuration.theme)
                MetricPill(title: "Guided", detail: "5-step flow", systemImage: "list.bullet.rectangle", theme: viewModel.configuration.theme)
                MetricPill(title: "Export", detail: "README included", systemImage: "shippingbox", theme: viewModel.configuration.theme)
            }
        }
    }

    private var flowSection: some View {
        GlassCard(radius: 32) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    "One simple flow",
                    eyebrow: "From idea to files",
                    subtitle: "Each screen moves you closer to a component you can preview and hand off.",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    theme: viewModel.configuration.theme
                )

                VStack(spacing: 10) {
                    ForEach(Array(FlowStep.allCases.enumerated()), id: \.element.id) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.configuration.theme.gradient)
                                Text("\(index + 1)")
                                    .font(.caption.weight(.black))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 30, height: 30)
                            .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 3) {
                                Text(step.rawValue)
                                    .font(.headline)
                                Text(copy(for: step))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)

                            Image(systemName: icon(for: step))
                                .font(.headline)
                                .foregroundStyle(viewModel.configuration.theme.gradient)
                                .accessibilityHidden(true)
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Step \(index + 1), \(step.rawValue). \(copy(for: step))")
                    }
                }
            }
        }
    }

    private var proofSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                "Built for confident exports",
                subtitle: "App Store-friendly proof points for screenshots without overstating the MVP.",
                systemImage: "checkmark.seal.fill",
                theme: viewModel.configuration.theme
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ProofCard(icon: "network", title: "Provider-ready", copy: "Use your own OpenAI-compatible chat endpoint.")
                ProofCard(icon: "wand.and.stars", title: "Guided creation", copy: "Prompt examples and template hints help users start fast.")
                ProofCard(icon: "doc.text.fill", title: "Beginner-ready", copy: "Exports include code, styles, and setup steps.")
                ProofCard(icon: "hand.tap.fill", title: "Interactive", copy: "Preview taps, forms, swipes, and states before export.")
            }
        }
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
        case .describe: return "Write one plain sentence or choose a template."
        case .generate: return "The AI engine builds a prompt-specific spec, or a labeled fallback if unavailable."
        case .customize: return "Pick color, style, motion, and code format."
        case .preview: return "Tap, swipe, and test the live interaction."
        case .export: return "Copy or share files with install steps included."
        }
    }
}

private struct ProofCard: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    let icon: String
    let title: String
    let copy: String

    var body: some View {
        GlassCard(radius: 24) {
            VStack(alignment: .leading, spacing: 10) {
                GradientIconBadge(systemImage: icon, theme: viewModel.configuration.theme, size: 38)
                Text(title)
                    .font(.headline)
                Text(copy)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}
