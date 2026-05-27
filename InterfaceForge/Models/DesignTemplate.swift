import SwiftUI

struct DesignTemplate: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let shortDescription: String
    let iconName: String
    let defaultPrompt: String
    let tags: [String]

    static let all: [DesignTemplate] = [
        // ── Original 5 ──────────────────────────────────────────────
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
        ),

        // ── New templates (6-20) ────────────────────────────────────
        DesignTemplate(
            id: "testimonial-carousel",
            title: "Testimonial carousel",
            shortDescription: "A scrollable social proof block with avatars and star ratings.",
            iconName: "star.bubble.fill",
            defaultPrompt: "Customer testimonial carousel for a B2B SaaS landing page",
            tags: ["Testimonial", "Social proof", "Reviews"]
        ),
        DesignTemplate(
            id: "feature-grid",
            title: "Feature grid",
            shortDescription: "A responsive grid of product features with icons and descriptions.",
            iconName: "square.grid.2x2.fill",
            defaultPrompt: "Feature grid for a project management tool highlighting collaboration features",
            tags: ["Features", "Grid", "Product"]
        ),
        DesignTemplate(
            id: "cta-banner",
            title: "CTA banner",
            shortDescription: "A full-width call-to-action banner with urgency elements.",
            iconName: "megaphone.fill",
            defaultPrompt: "Call-to-action banner for a limited-time product launch offer",
            tags: ["CTA", "Banner", "Conversion"]
        ),
        DesignTemplate(
            id: "blog-card",
            title: "Blog card",
            shortDescription: "A content card with featured image area, author, and read time.",
            iconName: "doc.richtext.fill",
            defaultPrompt: "Blog post card for a tech startup's engineering blog",
            tags: ["Blog", "Content", "Article"]
        ),
        DesignTemplate(
            id: "login-screen",
            title: "Login screen",
            shortDescription: "A clean authentication screen with social login options.",
            iconName: "person.badge.key.fill",
            defaultPrompt: "Mobile login screen for a fitness app with social auth buttons",
            tags: ["Login", "Auth", "Form"]
        ),
        DesignTemplate(
            id: "settings-panel",
            title: "Settings panel",
            shortDescription: "An organized settings page with toggle groups and sections.",
            iconName: "gearshape.2.fill",
            defaultPrompt: "App settings panel with notification preferences and account controls",
            tags: ["Settings", "Preferences", "Controls"]
        ),
        DesignTemplate(
            id: "stats-overview",
            title: "Stats overview",
            shortDescription: "A full-width statistics section with animated counters.",
            iconName: "number.circle.fill",
            defaultPrompt: "Company stats overview showing team size, customers, and uptime",
            tags: ["Stats", "Numbers", "Overview"]
        ),
        DesignTemplate(
            id: "notification-toast",
            title: "Notification toast",
            shortDescription: "A floating notification with icon, message, and dismiss action.",
            iconName: "bell.badge.fill",
            defaultPrompt: "Success notification toast for a file upload completion",
            tags: ["Notification", "Toast", "Alert"]
        ),
        DesignTemplate(
            id: "team-roster",
            title: "Team roster",
            shortDescription: "A team grid with photos, roles, and social links.",
            iconName: "person.3.fill",
            defaultPrompt: "Team roster section for a startup's about page with four founders",
            tags: ["Team", "About", "People"]
        ),
        DesignTemplate(
            id: "faq-accordion",
            title: "FAQ accordion",
            shortDescription: "An expandable question-and-answer list with smooth animations.",
            iconName: "questionmark.circle.fill",
            defaultPrompt: "FAQ section for a subscription product covering billing and cancellation",
            tags: ["FAQ", "Accordion", "Support"]
        ),
        DesignTemplate(
            id: "image-gallery",
            title: "Image gallery",
            shortDescription: "A masonry-style photo gallery with lightbox placeholders.",
            iconName: "photo.on.rectangle.angled",
            defaultPrompt: "Photo gallery for a travel photography portfolio",
            tags: ["Gallery", "Images", "Portfolio"]
        ),
        DesignTemplate(
            id: "timeline-feed",
            title: "Timeline feed",
            shortDescription: "A vertical timeline with events, dates, and status indicators.",
            iconName: "calendar.day.timeline.leading",
            defaultPrompt: "Product roadmap timeline showing past releases and upcoming features",
            tags: ["Timeline", "Roadmap", "Feed"]
        ),
        DesignTemplate(
            id: "email-signup",
            title: "Email signup",
            shortDescription: "A minimal email capture form with a compelling value proposition.",
            iconName: "envelope.badge.fill",
            defaultPrompt: "Newsletter signup section for a weekly AI research digest",
            tags: ["Email", "Signup", "Newsletter"]
        ),
        DesignTemplate(
            id: "comparison-table",
            title: "Comparison table",
            shortDescription: "A side-by-side feature comparison between product tiers.",
            iconName: "tablecells.fill",
            defaultPrompt: "Feature comparison table for free vs pro tiers of a design tool",
            tags: ["Comparison", "Table", "Pricing"]
        ),
        DesignTemplate(
            id: "empty-state",
            title: "Empty state",
            shortDescription: "A friendly empty state with illustration placeholder and CTA.",
            iconName: "tray.fill",
            defaultPrompt: "Empty state for a to-do app when all tasks are completed",
            tags: ["Empty state", "Placeholder", "Onboarding"]
        ),
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
    case testimonialCarousel = "testimonial-carousel"
    case featureGrid = "feature-grid"
    case ctaBanner = "cta-banner"
    case blogCard = "blog-card"
    case loginScreen = "login-screen"
    case settingsPanel = "settings-panel"
    case statsOverview = "stats-overview"
    case notificationToast = "notification-toast"
    case teamRoster = "team-roster"
    case faqAccordion = "faq-accordion"
    case imageGallery = "image-gallery"
    case timelineFeed = "timeline-feed"
    case emailSignup = "email-signup"
    case comparisonTable = "comparison-table"
    case emptyState = "empty-state"

    var id: String { rawValue }
}
