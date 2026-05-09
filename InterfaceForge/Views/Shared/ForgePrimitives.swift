import SwiftUI

struct AppBackground: ViewModifier {
    let theme: ColorTheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    theme.background.ignoresSafeArea()
                    Circle()
                        .fill(theme.accent.opacity(0.18))
                        .frame(width: 260, height: 260)
                        .blur(radius: 50)
                        .offset(x: -160, y: -320)
                    Circle()
                        .fill(theme.secondary.opacity(0.16))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: 160, y: 320)
                }
            )
    }
}

extension View {
    func appBackground(theme: ColorTheme) -> some View {
        modifier(AppBackground(theme: theme))
    }
}

struct StepRail: View {
    let activeStep: FlowStep

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FlowStep.allCases) { step in
                    HStack(spacing: 6) {
                        Image(systemName: icon(for: step))
                        Text(step.rawValue)
                    }
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .foregroundStyle(step == activeStep ? .white : .secondary)
                    .background(step == activeStep ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.thinMaterial), in: Capsule())
                    .accessibilityLabel("Flow step \(step.rawValue)")
                }
            }
            .padding(.horizontal)
        }
    }

    private func icon(for step: FlowStep) -> String {
        switch step {
        case .describe: return "text.bubble"
        case .generate: return "sparkles"
        case .customize: return "slider.horizontal.3"
        case .preview: return "play.rectangle"
        case .export: return "square.and.arrow.up"
        }
    }
}

struct PrimaryButton: View {
    let title: String
    let systemImage: String
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(theme.gradient, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: theme.accent.opacity(0.28), radius: 24, y: 14)
        .accessibilityLabel(title)
    }
}

struct GlassCard<Content: View>: View {
    let radius: CGFloat
    let content: Content

    init(radius: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.white.opacity(0.42), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
    }
}

struct Chip: View {
    let title: String
    var isSelected = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .foregroundStyle(isSelected ? .white : .primary)
                .background(isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.thinMaterial), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
