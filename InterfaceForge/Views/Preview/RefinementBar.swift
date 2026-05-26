import SwiftUI

/// A compact bar that lets users send follow-up prompts to iteratively refine the current design.
struct RefinementBar: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @EnvironmentObject private var historyStore: DesignHistoryStore
    @EnvironmentObject private var storeKit: StoreKitManager
    @EnvironmentObject private var usageTracker: UsageTracker

    @FocusState private var isFocused: Bool

    private let suggestions = [
        "Make it darker",
        "Add more metrics",
        "Simplify the layout",
        "Make the CTA bolder",
        "Add a testimonial"
    ]

    var body: some View {
        GlassCard(radius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 10) {
                    GradientIconBadge(systemImage: "arrow.triangle.2.circlepath", theme: viewModel.configuration.theme, size: 36)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Refine this design")
                            .font(.headline)
                        Text("Describe what to change — the AI will update the component while keeping everything else.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 10) {
                    TextField("e.g. Make the headline bolder...", text: $viewModel.refinementPrompt, axis: .vertical)
                        .lineLimit(1...3)
                        .textInputAutocapitalization(.sentences)
                        .padding(12)
                        .background(Color(.secondarySystemBackground).opacity(0.86), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(viewModel.configuration.theme.accent.opacity(isFocused ? 0.4 : 0.16), lineWidth: 1)
                        )
                        .focused($isFocused)
                        .accessibilityLabel("Refinement prompt")
                        .accessibilityHint("Describe what to change about the current design")

                    Button {
                        Task {
                            await viewModel.refine(
                                historyStore: historyStore,
                                storeKit: storeKit,
                                usage: usageTracker
                            )
                        }
                    } label: {
                        Group {
                            if viewModel.isRefining {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.body.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(canRefine ? viewModel.configuration.theme.gradient : LinearGradient(colors: [.gray], startPoint: .top, endPoint: .bottom), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!canRefine)
                    .accessibilityLabel("Send refinement")
                    .accessibilityHint(canRefine ? "Sends the follow-up prompt to refine the design" : "Enter a refinement prompt first")
                }

                // Quick suggestion chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            Button {
                                viewModel.refinementPrompt = suggestion
                            } label: {
                                Text(suggestion)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(.thinMaterial, in: Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Use suggestion: \(suggestion)")
                        }
                    }
                }
            }
        }
    }

    private var canRefine: Bool {
        !viewModel.refinementPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && !viewModel.isRefining
        && viewModel.generatedDesign != nil
    }
}
