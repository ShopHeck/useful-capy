import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var storeKit: StoreKitManager
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: PlanOption = .yearly

    private enum PlanOption: String, CaseIterable, Identifiable {
        case monthly, yearly
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header
                VStack(spacing: 14) {
                    GradientIconBadge(
                        systemImage: "crown.fill",
                        theme: viewModel.configuration.theme,
                        size: 64
                    )

                    Text("Unlock InterfaceForge Pro")
                        .font(.system(.title, design: .rounded, weight: .black))
                        .multilineTextAlignment(.center)

                    Text("Generate unlimited UI components, export all formats, and skip API key setup.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 16)

                // Feature list
                featureList

                // Plan selector
                planSelector

                // Purchase button
                purchaseButton

                // Restore + legal
                VStack(spacing: 12) {
                    Button("Restore Purchases") {
                        Task { await storeKit.restorePurchases() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(viewModel.configuration.theme.accent)

                    Text("Payment will be charged to your Apple ID account. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Error message
                if let error = storeKit.purchaseError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .readableContentFrame(maxWidth: 540)
        }
        .appBackground(theme: viewModel.configuration.theme)
        .navigationTitle("Pro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Skip") { dismiss() }
                    .font(.subheadline.weight(.semibold))
            }
        }
        .onChange(of: storeKit.currentTier) { _, newTier in
            if newTier == .pro { dismiss() }
        }
    }

    // MARK: - Feature list

    private var featureList: some View {
        GlassCard(radius: 24) {
            VStack(alignment: .leading, spacing: 14) {
                FeatureRow(icon: "sparkles", title: "Unlimited AI generations", subtitle: "No daily cap — generate as many components as you want")
                FeatureRow(icon: "server.rack", title: "Hosted AI — no API key needed", subtitle: "We handle the AI provider so you don't have to set anything up")
                FeatureRow(icon: "square.and.arrow.up.fill", title: "Export all formats", subtitle: "React, HTML/CSS, Tailwind, and SwiftUI starter packages")
                FeatureRow(icon: "clock.arrow.circlepath", title: "Full design history", subtitle: "Every generation saved and searchable")
            }
        }
    }

    // MARK: - Plan selector

    private var planSelector: some View {
        HStack(spacing: 12) {
            PlanCard(
                title: "Monthly",
                price: storeKit.proMonthly?.displayPrice ?? "$6.99",
                detail: "per month",
                badge: nil,
                isSelected: selectedPlan == .monthly,
                theme: viewModel.configuration.theme
            ) { selectedPlan = .monthly }

            PlanCard(
                title: "Yearly",
                price: storeKit.proYearly?.displayPrice ?? "$49.99",
                detail: "per year",
                badge: "SAVE 40%",
                isSelected: selectedPlan == .yearly,
                theme: viewModel.configuration.theme
            ) { selectedPlan = .yearly }
        }
    }

    // MARK: - Purchase button

    private var purchaseButton: some View {
        PrimaryButton(
            title: storeKit.isLoading ? "Processing..." : "Subscribe to Pro",
            systemImage: "crown.fill",
            theme: viewModel.configuration.theme,
            isEnabled: !storeKit.isLoading && selectedProduct != nil
        ) {
            guard let product = selectedProduct else { return }
            Task { await storeKit.purchase(product) }
        }
    }

    private var selectedProduct: Product? {
        selectedPlan == .yearly ? storeKit.proYearly : storeKit.proMonthly
    }
}

// MARK: - Subviews

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(.green.gradient, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PlanCard: View {
    let title: String
    let price: String
    let detail: String
    let badge: String?
    let isSelected: Bool
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                if let badge {
                    Text(badge)
                        .font(.caption2.weight(.black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(theme.accent, in: Capsule())
                }

                Text(title)
                    .font(.headline)

                Text(price)
                    .font(.system(.title2, design: .rounded, weight: .black))

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isSelected ? AnyShapeStyle(theme.accent.opacity(0.12)) : AnyShapeStyle(.thinMaterial), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? AnyShapeStyle(theme.accent) : AnyShapeStyle(Color.white.opacity(0.24)), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) plan, \(price) \(detail)")
        .accessibilityHint(isSelected ? "Currently selected" : "Tap to select")
    }
}
