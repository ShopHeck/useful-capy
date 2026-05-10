import SwiftUI

struct PortfolioCardPreview: View {
    let design: GeneratedDesign
    @State private var liked = false

    var body: some View {
        GlassCard(radius: design.configuration.visualStyle.cornerRadius) {
            VStack(alignment: .leading, spacing: 18) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(design.configuration.theme.gradient)
                        .frame(height: 190)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Case study", systemImage: "rectangle.stack.fill")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(.white.opacity(0.2), in: Capsule())
                        Text(design.headline)
                            .font(.system(size: 32, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .padding(20)
                }

                Text(design.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    StatPill(value: "42%", label: "lift")
                    StatPill(value: "3 days", label: "built")
                    StatPill(value: "A+", label: "grade")
                }

                HStack {
                    Button {
                        withAnimation(design.configuration.motionLevel.spring) {
                            liked.toggle()
                        }
                    } label: {
                        Label(liked ? "Saved" : "Save", systemImage: liked ? "heart.fill" : "heart")
                    }
                    .buttonStyle(.bordered)
                    .tint(liked ? .pink : design.configuration.theme.accent)
                    .accessibilityLabel(liked ? "Saved project" : "Save project")

                    Spacer()

                    Button("View project") { }
                        .font(.headline)
                        .buttonStyle(.borderedProminent)
                        .tint(design.configuration.theme.accent)
                }
            }
        }
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.black))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
