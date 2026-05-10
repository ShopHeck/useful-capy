import Foundation

struct DesignGenerator {
    func matchedTemplate(for prompt: String, selectedTemplate: DesignTemplate?) -> DesignTemplate {
        if let selectedTemplate {
            return selectedTemplate
        }

        let lowercasedPrompt = prompt.lowercased()
        let keywordMatches: [(keywords: [String], id: String)] = [
            (["pricing", "plan", "subscription", "saas"], "pricing-card"),
            (["dashboard", "metric", "chart", "analytics", "widget"], "dashboard-widget"),
            (["onboarding", "hero", "welcome", "feature"], "onboarding-hero"),
            (["checkout", "form", "contact", "payment", "email"], "checkout-form"),
            (["portfolio", "project", "case study", "gallery"], "portfolio-card")
        ]

        for match in keywordMatches where match.keywords.contains(where: { lowercasedPrompt.contains($0) }) {
            if let template = DesignTemplate.all.first(where: { $0.id == match.id }) {
                return template
            }
        }

        return DesignTemplate.fallback
    }

    func generate(prompt: String, selectedTemplate: DesignTemplate?, configuration: DesignConfiguration) -> GeneratedDesign {
        let template = matchedTemplate(for: prompt, selectedTemplate: selectedTemplate)
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = cleanPrompt.isEmpty ? template.defaultPrompt : cleanPrompt
        let headline = headlineForTemplate(template, prompt: request)
        let subheadline = subheadlineForTemplate(template, style: configuration.visualStyle)

        return GeneratedDesign(
            template: template,
            prompt: request,
            configuration: configuration,
            headline: headline,
            subheadline: subheadline,
            createdAt: Date()
        )
    }

    private func headlineForTemplate(_ template: DesignTemplate, prompt: String) -> String {
        switch template.id {
        case "pricing-card": return "Launch Plan Pro"
        case "dashboard-widget": return "Growth Pulse"
        case "onboarding-hero": return "Start Smarter"
        case "checkout-form": return "Fast Checkout"
        case "portfolio-card": return "Featured Build"
        default: return prompt.components(separatedBy: " ").prefix(3).joined(separator: " ")
        }
    }

    private func subheadlineForTemplate(_ template: DesignTemplate, style: VisualStyle) -> String {
        switch template.id {
        case "pricing-card": return "A polished plan card with monthly and yearly pricing ready to paste into your site."
        case "dashboard-widget": return "An interactive metrics block that helps visitors understand momentum at a glance."
        case "onboarding-hero": return "A swipeable product intro that explains value before asking users to act."
        case "checkout-form": return "A beginner-friendly form pattern with helpful inline feedback and a clear submit state."
        case "portfolio-card": return "A compact case-study card with visual depth, proof points, and a confident action."
        default: return "A \(style.rawValue.lowercased()) interface component generated locally on your device."
        }
    }
}
