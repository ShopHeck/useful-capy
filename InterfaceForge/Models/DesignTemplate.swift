import SwiftUI

struct DesignTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let shortDescription: String
    let iconName: String
    let defaultPrompt: String
    let tags: [String]

    static let all: [DesignTemplate] = [
        DesignTemplate(
            id: "pricing-card",
            title: "Pricing card",
            shortDescription: "A conversion-focused plan card with billing controls.",
            iconName: "creditcard.and.123",
            defaultPrompt: "SaaS pricing card for a creator analytics product",
            tags: ["SaaS pricing card", "Subscription", "CTA"]
        ),
        DesignTemplate(
            id: "dashboard-widget",
            title: "Dashboard widget",
            shortDescription: "A compact analytics panel with tappable metrics.",
            iconName: "chart.xyaxis.line",
            defaultPrompt: "AI dashboard widget for weekly growth insights",
            tags: ["AI dashboard widget", "Metrics", "Charts"]
        ),
        DesignTemplate(
            id: "onboarding-hero",
            title: "Onboarding hero",
            shortDescription: "A swipeable hero for introducing product benefits.",
            iconName: "sparkles.rectangle.stack",
            defaultPrompt: "Mobile onboarding hero for a habit coaching app",
            tags: ["Mobile onboarding hero", "Features", "Launch"]
        ),
        DesignTemplate(
            id: "checkout-form",
            title: "Checkout form",
            shortDescription: "A friendly form with clear validation feedback.",
            iconName: "checklist.checked",
            defaultPrompt: "Checkout form for a premium design resource shop",
            tags: ["Checkout form", "Contact form", "Validation"]
        ),
        DesignTemplate(
            id: "portfolio-card",
            title: "Portfolio card",
            shortDescription: "A polished project card with links and stats.",
            iconName: "rectangle.stack.badge.play",
            defaultPrompt: "Portfolio project card for a freelance product designer",
            tags: ["Portfolio project card", "Case study", "Gallery"]
        )
    ]

    static var fallback: DesignTemplate {
        all.first ?? DesignTemplate(
            id: "pricing-card",
            title: "Pricing card",
            shortDescription: "A conversion-focused plan card with billing controls.",
            iconName: "creditcard.and.123",
            defaultPrompt: "SaaS pricing card",
            tags: ["SaaS pricing card"]
        )
    }
}

enum TemplateKind: String, CaseIterable, Identifiable {
    case pricingCard = "pricing-card"
    case dashboardWidget = "dashboard-widget"
    case onboardingHero = "onboarding-hero"
    case checkoutForm = "checkout-form"
    case portfolioCard = "portfolio-card"

    var id: String { rawValue }
}
