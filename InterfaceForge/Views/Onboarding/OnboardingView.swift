import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @EnvironmentObject private var storeKit: StoreKitManager
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage = 0
    @State private var showPaywall = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "text.bubble.fill",
            title: "Describe any UI",
            subtitle: "Type a plain-English prompt like \"SaaS pricing card\" or \"onboarding hero for a fitness app.\" Pick a color theme and style, and you're ready to generate.",
            accentColors: [Color(red: 0.30, green: 0.84, blue: 0.68), Color(red: 0.22, green: 0.48, blue: 0.96)]
        ),
        OnboardingPage(
            icon: "wand.and.stars",
            title: "Preview instantly",
            subtitle: "Your prompt becomes a live UI component with sections, metrics, forms, and CTAs — all adaptive to your chosen style and theme.",
            accentColors: [Color(red: 0.20, green: 0.50, blue: 0.96), Color(red: 0.10, green: 0.78, blue: 0.86)]
        ),
        OnboardingPage(
            icon: "square.and.arrow.up.fill",
            title: "Export starter code",
            subtitle: "Get production-ready React, HTML/CSS, Tailwind, or SwiftUI packages — each with a README, tokens, and beginner setup guide.",
            accentColors: [Color(red: 0.96, green: 0.36, blue: 0.83), Color(red: 0.53, green: 0.38, blue: 1.00)]
        )
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.35), value: currentPage)

                // Controls
                VStack(spacing: 16) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? viewModel.configuration.theme.accent : Color.secondary.opacity(0.3))
                                .frame(width: index == currentPage ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.35), value: currentPage)
                        }
                    }
                    .padding(.bottom, 6)

                    if currentPage == pages.count - 1 {
                        // Final page — show "Get Started" + "Try Pro"
                        PrimaryButton(
                            title: "Get Started",
                            systemImage: "arrow.right",
                            theme: viewModel.configuration.theme
                        ) {
                            completeOnboarding()
                        }

                        Button {
                            showPaywall = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(viewModel.configuration.theme.accent)
                                Text("Unlock Pro — unlimited generations, no API key needed")
                                    .foregroundStyle(.primary)
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                    } else {
                        PrimaryButton(
                            title: "Next",
                            systemImage: "arrow.right",
                            theme: viewModel.configuration.theme
                        ) {
                            withAnimation { currentPage += 1 }
                        }

                        Button("Skip") { completeOnboarding() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .appBackground(theme: viewModel.configuration.theme)
            .navigationDestination(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 28) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.accentColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: page.accentColors.first?.opacity(0.35) ?? .clear, radius: 40, y: 20)

                Image(systemName: page.icon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(.white)
            }
            .accessibilityHidden(true)

            VStack(spacing: 14) {
                Text(page.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 20)

            Spacer()
            Spacer()
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let subtitle: String
    let accentColors: [Color]
}
