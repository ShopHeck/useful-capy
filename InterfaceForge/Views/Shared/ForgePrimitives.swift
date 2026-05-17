import SwiftUI

struct AppBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let theme: ColorTheme

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    baseGradient.ignoresSafeArea()

                    RadialGradient(
                        colors: [theme.accent.opacity(colorScheme == .dark ? 0.34 : 0.22), .clear],
                        center: .topLeading,
                        startRadius: 24,
                        endRadius: 430
                    )
                    .ignoresSafeArea()

                    RadialGradient(
                        colors: [theme.secondary.opacity(colorScheme == .dark ? 0.28 : 0.18), .clear],
                        center: .bottomTrailing,
                        startRadius: 20,
                        endRadius: 480
                    )
                    .ignoresSafeArea()

                    Circle()
                        .fill(theme.accent.opacity(colorScheme == .dark ? 0.20 : 0.12))
                        .frame(width: 260, height: 260)
                        .blur(radius: 64)
                        .offset(x: -150, y: -320)

                    Circle()
                        .fill(theme.secondary.opacity(colorScheme == .dark ? 0.18 : 0.10))
                        .frame(width: 340, height: 340)
                        .blur(radius: 76)
                        .offset(x: 170, y: 330)

                    LinearGradient(
                        colors: [.white.opacity(colorScheme == .dark ? 0.03 : 0.26), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                    .ignoresSafeArea()
                }
            }
    }

    private var baseGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color(red: 0.045, green: 0.05, blue: 0.075), theme.background.opacity(0.96), Color(red: 0.02, green: 0.025, blue: 0.035)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [theme.background, Color(.systemBackground), theme.accent.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    func appBackground(theme: ColorTheme) -> some View {
        modifier(AppBackground(theme: theme))
    }

    func readableContentFrame(maxWidth: CGFloat = 980, alignment: Alignment = .center) -> some View {
        frame(maxWidth: maxWidth, alignment: alignment)
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
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(step == activeStep ? 0.24 : 0.36), lineWidth: 1)
                    )
                    .accessibilityLabel("Flow step \(step.rawValue)")
                    .accessibilityHint(step == activeStep ? "Current step" : "Upcoming app flow step")
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
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.72))
        .background(buttonBackground, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(isEnabled ? 0.20 : 0.10), lineWidth: 1)
        )
        .shadow(color: theme.accent.opacity(isEnabled ? 0.28 : 0), radius: 24, y: 14)
        .accessibilityLabel(title)
    }

    private var buttonBackground: some ShapeStyle {
        isEnabled ? AnyShapeStyle(theme.gradient) : AnyShapeStyle(Color.secondary.opacity(0.34))
    }
}

struct GlassCard<Content: View>: View {
    @ScaledMetric(relativeTo: .body) private var cardPadding: CGFloat = 20
    let radius: CGFloat
    let content: Content

    init(radius: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .padding(cardPadding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(colors: [.white.opacity(0.58), .white.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.09), radius: 28, y: 14)
    }
}

struct StatusBadge: View {
    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.black))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .font(.caption.weight(.black))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)
                .background(tint.opacity(0.14), in: Circle())
        }
        .labelStyle(.titleAndIcon)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(tint.opacity(0.22), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(detail)")
    }
}

struct InfoCallout: View {
    let title: String
    let message: String
    let systemImage: String
    let theme: ColorTheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(theme.accent)
                .frame(width: 32, height: 32)
                .background(theme.accent.opacity(0.14), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct SectionHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?
    var systemImage: String?
    var theme: ColorTheme?

    init(_ title: String, eyebrow: String? = nil, subtitle: String? = nil, systemImage: String? = nil, theme: ColorTheme? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.theme = theme
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Text(eyebrow.uppercased())
                    .font(.caption.weight(.black))
                    .tracking(0.8)
                    .foregroundStyle(theme?.accent ?? .secondary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                if let systemImage, let theme {
                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(theme.gradient)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(.title2.weight(.black))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct GradientIconBadge: View {
    let systemImage: String
    let theme: ColorTheme
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                .fill(theme.gradient)
            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: theme.accent.opacity(0.26), radius: 16, y: 8)
        .accessibilityHidden(true)
    }
}

struct MetricPill: View {
    let title: String
    let detail: String
    let systemImage: String
    let theme: ColorTheme

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.gradient)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.caption.weight(.black))
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(.thinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.30), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(detail)")
    }
}

struct SecondaryLinkRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let theme: ColorTheme

    var body: some View {
        HStack(spacing: 12) {
            GradientIconBadge(systemImage: systemImage, theme: theme, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct Chip: View {
    let title: String
    var isSelected = false
    var theme: ColorTheme?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.black))
                }
                Text(title)
                    .lineLimit(2)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(backgroundStyle, in: Capsule())
            .overlay(Capsule().stroke(borderStyle, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityHint(isSelected ? "Selected" : "Tap to select")
    }

    private var backgroundStyle: some ShapeStyle {
        if isSelected, let theme {
            return AnyShapeStyle(theme.gradient)
        }
        return isSelected ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.thinMaterial)
    }

    private var borderStyle: some ShapeStyle {
        isSelected ? AnyShapeStyle(Color.white.opacity(0.32)) : AnyShapeStyle(Color.white.opacity(0.24))
    }
}

struct StoreErrorBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(message)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: dismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss error")
        }
        .padding(14)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Storage error. \(message)")
    }
}
