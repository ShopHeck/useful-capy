import SwiftUI

struct DashboardWidgetPreview: View {
    let design: GeneratedDesign
    @State private var selectedMetric = "Revenue"
    private let metrics = ["Revenue", "Users", "Conversion"]

    var body: some View {
        GlassCard(radius: design.configuration.visualStyle.cornerRadius) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(design.headline)
                            .font(.title.weight(.black))
                        Text("Live preview component")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(design.configuration.theme.accent)
                    }
                    Spacer()
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(design.configuration.theme.gradient)
                }

                HStack(spacing: 8) {
                    ForEach(metrics, id: \.self) { metric in
                        Button(metric) {
                            withAnimation(design.configuration.motionLevel.spring) {
                                selectedMetric = metric
                            }
                        }
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .foregroundStyle(selectedMetric == metric ? .white : .primary)
                        .background(selectedMetric == metric ? AnyShapeStyle(design.configuration.theme.gradient) : AnyShapeStyle(.thinMaterial), in: Capsule())
                        .accessibilityLabel("Show \(metric) metric")
                    }
                }

                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(chartValues, id: \.self) { value in
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(design.configuration.theme.gradient)
                            .frame(height: CGFloat(value))
                            .opacity(value == chartValues.max() ? 1 : 0.55)
                    }
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)

                HStack {
                    VStack(alignment: .leading) {
                        Text(metricValue)
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                        Text("\(selectedMetric) this week")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Label("+18%", systemImage: "arrow.up.right")
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .foregroundStyle(.green)
                        .background(.green.opacity(0.12), in: Capsule())
                }
            }
        }
    }

    private var chartValues: [Int] {
        switch selectedMetric {
        case "Users": return [58, 76, 68, 108, 124, 112]
        case "Conversion": return [42, 50, 64, 72, 66, 92]
        default: return [64, 82, 78, 116, 132, 146]
        }
    }

    private var metricValue: String {
        switch selectedMetric {
        case "Users": return "12.8k"
        case "Conversion": return "8.4%"
        default: return "$48.2k"
        }
    }
}
