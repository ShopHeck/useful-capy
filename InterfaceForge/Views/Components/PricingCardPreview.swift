import SwiftUI

struct PricingCardPreview: View {
    let design: GeneratedDesign
    @State private var yearly = true
    @State private var selected = false

    var body: some View {
        GlassCard(radius: design.configuration.visualStyle.cornerRadius) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Label("Best value", systemImage: "sparkle")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .foregroundStyle(.white)
                        .background(design.configuration.theme.gradient, in: Capsule())
                    Spacer()
                    Toggle("Yearly", isOn: $yearly)
                        .labelsHidden()
                        .tint(design.configuration.theme.accent)
                        .accessibilityLabel("Switch billing period")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(design.headline)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                    Text(design.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(yearly ? "$19" : "$24")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                    Text("/mo")
                        .foregroundStyle(.secondary)
                    if yearly {
                        Text("save 20%")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(design.configuration.theme.accent.opacity(0.14), in: Capsule())
                    }
                }
                .contentTransition(.numericText())

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(featureRows, id: \.self) { feature in
                        FeatureRow(text: feature)
                    }
                }

                Button {
                    withAnimation(design.configuration.motionLevel.spring) {
                        selected.toggle()
                    }
                } label: {
                    Label(selected ? "Added to your export" : design.primaryAction, systemImage: selected ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .foregroundStyle(.white)
                        .background(design.configuration.theme.gradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(selected ? "Design selected" : "Choose this design")
            }
        }
    }

    private var featureRows: [String] {
        if !design.sections.isEmpty {
            return design.sections.map(\.title)
        }
        return ["Responsive component code", "Copy-paste install guide", "AI engine or labeled fallback status"]
    }
}

private struct FeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text(text)
                .font(.subheadline.weight(.medium))
        }
    }
}
