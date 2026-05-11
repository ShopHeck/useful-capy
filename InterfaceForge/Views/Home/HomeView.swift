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
            .readableContentFrame(maxWidth: 1060)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity)
        }
        .navigationBarTitleDisplayMode(.inline)
        .appBackground(theme: viewModel.configuration.theme)
        .onAppear { viewModel.selectedStep = .describe }
    }

    private var hero: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 26) {
                heroCopy
                    .frame(maxWidth: 570, alignment: .leading)
                HomePreviewMock(theme: viewModel.configuration.theme)
                    .frame(maxWidth: 380)
            }

            VStack(alignment: .leading, spacing: 22) {
                heroCopy
                HomePreviewMock(theme: viewModel.configuration.theme)
            }
        }
    }

    private var heroCopy: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                GradientIconBadge(systemImage: "hammer.fill", theme: viewModel.configuration.theme, size: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text("INTERFACEFORGE")
                        .font(.caption.weight(.black))
                        .tracking(0.8)
                        .foregroundStyle(viewModel.configuration.theme.accent)
                    Text("AI interface generation")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("InterfaceForge, AI interface generation")

            Text("Design polished UI from one clear prompt.")
                .font(.system(.largeTitle, design: .rounded, weight: .black))
                .lineLimit(4)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Text("Bring your own OpenAI-compatible provider key, describe the interface, then preview and export starter code. If a provider call cannot run, the app clearly marks the result as a template fallback.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink(value: AppRoute.composer) {
                Label("Create with AI", systemImage: "sparkles")
                    .font(.headline)
                    .frame(maxWidth: 420)
                    .frame(minHeight: 54)
                    .foregroundStyle(.white)
                    .background(viewModel.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: viewModel.configuration.theme.accent.opacity(0.28), radius: 24, y: 14)
            }
            .accessibilityLabel("Create with AI")
            .accessibilityHint("Opens the guided prompt composer and provider settings")

            FlowLayout(spacing: 8) {
                MetricPill(title: "Provider key", detail: "You control access", systemImage: "key.fill", theme: viewModel.configuration.theme)
                MetricPill(title: "Remote AI", detail: "Clear disclosure", systemImage: "network", theme: viewModel.configuration.theme)
                MetricPill(title: "Exports", detail: "Starter files", systemImage: "shippingbox", theme: viewModel.configuration.theme)
            }
        }
    }

    private var flowSection: some View {
        GlassCard(radius: 32) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeader(
                    "A guided path from idea to handoff",
                    eyebrow: "No debug panel required",
                    subtitle: "Each step uses plain-language choices so a non-technical user can understand what will be sent, generated, previewed, and exported.",
                    systemImage: "point.3.connected.trianglepath.dotted",
                    theme: viewModel.configuration.theme
                )

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 12)], spacing: 12) {
                    ForEach(Array(FlowStep.allCases.enumerated()), id: \.element.id) { index, step in
                        FlowStepCard(index: index, step: step, copy: copy(for: step), icon: icon(for: step), theme: viewModel.configuration.theme)
                    }
                }
            }
        }
    }

    private var proofSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(
                "Built for conservative release messaging",
                subtitle: "The product explains user-provided provider credentials, remote prompt requests, fallback templates, and starter-code exports without overpromising.",
                systemImage: "checkmark.seal.fill",
                theme: viewModel.configuration.theme
            )

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], spacing: 12) {
                ProofCard(icon: "key.fill", title: "Bring your provider", copy: "Users enter their own OpenAI-compatible endpoint, model, and key.")
                ProofCard(icon: "lock.shield.fill", title: "Trustworthy setup", copy: "Copy explains local MVP storage and provider privacy/billing terms.")
                ProofCard(icon: "tag.fill", title: "Fallback is labeled", copy: "Unavailable AI never masquerades as provider-generated output.")
                ProofCard(icon: "doc.text.fill", title: "Starter handoff", copy: "Exports include code, styles, and README steps, not production guarantees.")
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
        case .describe: return "Write one plain sentence or choose a template hint."
        case .generate: return "Send the prompt to your configured provider, or receive a labeled fallback."
        case .customize: return "Pick color, style, motion, and code format with friendly controls."
        case .preview: return "Review prompt-specific sections, metrics, forms, and tap states."
        case .export: return "Copy or share beginner-ready starter files with setup notes."
        }
    }
}

private struct FlowStepCard: View {
    let index: Int
    let step: FlowStep
    let copy: String
    let icon: String
    let theme: ColorTheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(theme.gradient)
                Text("\(index + 1)")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .foregroundStyle(theme.gradient)
                        .accessibilityHidden(true)
                    Text(step.rawValue)
                        .font(.headline)
                }
                Text(copy)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(index + 1), \(step.rawValue). \(copy)")
    }
}

private struct HomePreviewMock: View {
    let theme: ColorTheme

    var body: some View {
        GlassCard(radius: 34) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    StatusBadge(title: "AI-ready", detail: "Provider key", systemImage: "key.fill", tint: theme.accent)
                    Spacer(minLength: 8)
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.title2)
                        .foregroundStyle(theme.gradient)
                        .accessibilityHidden(true)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt preview")
                        .font(.caption.weight(.black))
                        .foregroundStyle(theme.accent)
                        .textCase(.uppercase)
                    Text("Waitlist hero with signup form")
                        .font(.title3.weight(.black))
                    Text("AI output adapts into sections, form fields, metrics, and export files.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    HomePreviewRow(title: "Remote request", detail: "Only after you add provider settings", icon: "network", theme: theme)
                    HomePreviewRow(title: "Labeled fallback", detail: "Template output stays clearly marked", icon: "tag.fill", theme: theme)
                    HomePreviewRow(title: "Starter export", detail: "React, HTML, CSS, or SwiftUI files", icon: "doc.on.doc.fill", theme: theme)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preview card showing provider setup, labeled fallback, and starter export")
    }
}

private struct HomePreviewRow: View {
    let title: String
    let detail: String
    let icon: String
    let theme: ColorTheme

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(theme.gradient, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
