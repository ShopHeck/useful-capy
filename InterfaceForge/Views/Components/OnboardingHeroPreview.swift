import SwiftUI

struct OnboardingHeroPreview: View {
    let design: GeneratedDesign
    @State private var selectedPage = 0

    private let features = [
        (title: "Describe it", icon: "text.bubble.fill", copy: "Start with a plain sentence. No design language required."),
        (title: "Preview live", icon: "hand.tap.fill", copy: "Test the tap and swipe states before you export."),
        (title: "Ship the code", icon: "shippingbox.fill", copy: "Share a small package with beginner steps included.")
    ]

    var body: some View {
        GlassCard(radius: design.configuration.visualStyle.cornerRadius) {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(design.configuration.theme.darkGradient)
                        .frame(height: 220)
                    VStack(spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 44))
                            .foregroundStyle(.white)
                        Text(design.headline)
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        Text("Swipe the cards below")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .padding()
                }

                TabView(selection: $selectedPage) {
                    ForEach(features.indices, id: \.self) { index in
                        VStack(spacing: 10) {
                            Image(systemName: features[index].icon)
                                .font(.largeTitle)
                                .foregroundStyle(design.configuration.theme.gradient)
                            Text(features[index].title)
                                .font(.title3.weight(.bold))
                            Text(features[index].copy)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .tag(index)
                    }
                }
                .frame(height: 150)
                .tabViewStyle(.page(indexDisplayMode: .always))
                .accessibilityLabel("Swipeable onboarding feature cards")

                HStack {
                    Button("Back") {
                        withAnimation(design.configuration.motionLevel.spring) {
                            selectedPage = max(0, selectedPage - 1)
                        }
                    }
                    .disabled(selectedPage == 0)
                    Spacer()
                    Button(selectedPage == features.count - 1 ? "Ready" : "Next") {
                        withAnimation(design.configuration.motionLevel.spring) {
                            selectedPage = min(features.count - 1, selectedPage + 1)
                        }
                    }
                    .font(.headline)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
