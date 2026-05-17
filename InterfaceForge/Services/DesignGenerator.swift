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
            (["checkout", "form", "contact", "payment", "email", "waitlist", "signup"], "checkout-form"),
            (["portfolio", "project", "case study", "gallery"], "portfolio-card")
        ]

        for match in keywordMatches where match.keywords.contains(where: { lowercasedPrompt.contains($0) }) {
            if let template = DesignTemplate.all.first(where: { $0.id == match.id }) {
                return template
            }
        }

        return DesignTemplate.fallback
    }

    func generate(prompt: String, selectedTemplate: DesignTemplate?, configuration: DesignConfiguration, apiKey: String, endpoint: String, model: String) async -> GeneratedDesign {
        let fallbackTemplate = matchedTemplate(for: prompt, selectedTemplate: selectedTemplate)
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let requestPrompt = cleanPrompt.isEmpty ? fallbackTemplate.defaultPrompt : cleanPrompt
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKey.isEmpty else {
            return fallbackDesign(prompt: requestPrompt, template: fallbackTemplate, configuration: configuration, reason: "Add a valid API key in AI engine settings to use remote AI generation.", error: "AI generation unavailable: missing API key.")
        }

        do {
            let spec = try await requestAISpec(prompt: requestPrompt, selectedTemplate: selectedTemplate, configuration: configuration, apiKey: trimmedKey, endpoint: endpoint, model: model)
            return design(from: spec, prompt: requestPrompt, selectedTemplate: selectedTemplate, fallbackTemplate: fallbackTemplate, configuration: configuration)
        } catch {
            return fallbackDesign(prompt: requestPrompt, template: fallbackTemplate, configuration: configuration, reason: "AI generation failed, so InterfaceForge built a clearly labeled template fallback.", error: "AI generation failed: \(error.localizedDescription)")
        }
    }

    func validateEndpoint(endpoint: String, apiKey: String) async -> String {
        guard let _ = try? parseSecureURL(endpoint) else {
            return "Endpoint must be a valid https:// URL (http:// is only allowed for localhost)."
        }
        if apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "Add an API key first."
        }
        return "Endpoint looks valid. A real request runs when you generate."
    }

    private func parseSecureURL(_ endpoint: String) throws -> URL {
        let trimmed = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), let host = url.host?.lowercased() else {
            throw GenerationError.invalidEndpoint
        }
        if scheme == "https" { return url }
        let localHosts: Set<String> = ["localhost", "127.0.0.1", "::1"]
        if scheme == "http" && localHosts.contains(host) { return url }
        throw GenerationError.insecureEndpoint
    }

    private func requestAISpec(prompt: String, selectedTemplate: DesignTemplate?, configuration: DesignConfiguration, apiKey: String, endpoint: String, model: String) async throws -> AIDesignSpec {
        let url = try parseSecureURL(endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 45

        let body = ChatCompletionRequest(
            model: model.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "gpt-4.1-mini" : model,
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: userPrompt(prompt: prompt, selectedTemplate: selectedTemplate, configuration: configuration))
            ],
            temperature: 0.75,
            responseFormat: ResponseFormat(type: "json_object")
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GenerationError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw GenerationError.apiFailed(String(body.prefix(240)))
        }

        let completion = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = completion.choices.first?.message.content else {
            throw GenerationError.emptyResponse
        }
        let json = extractJSON(from: content)
        guard let jsonData = json.data(using: .utf8) else {
            throw GenerationError.invalidJSON
        }
        let spec = try JSONDecoder().decode(AIDesignSpec.self, from: jsonData)
        guard !spec.headline.trimmed.isEmpty, !spec.subheadline.trimmed.isEmpty else {
            throw GenerationError.missingRequiredFields
        }
        return spec
    }

    private var systemPrompt: String {
        """
        You are InterfaceForge's UI generation engine. Return strict JSON only, with no markdown wrappers or explanatory text. Create a single responsive, accessible, beginner-friendly UI component that accurately follows the user's prompt and selected style. Do not require external dependencies, icons, image assets, web fonts, packages, or third-party UI libraries. Keep code copy-paste friendly. Use semantic HTML, accessible labels, visible focus styles, responsive CSS, and safe placeholder content. If code fields are included, they must be complete enough to paste into beginner projects.
        Required JSON shape:
        {
          "componentType": "short-kebab-case-id",
          "title": "Readable component family",
          "kicker": "short label",
          "headline": "specific headline",
          "subheadline": "supporting copy",
          "primaryAction": "button label",
          "secondaryAction": "optional link label",
          "sections": [{"title":"feature/checklist title","detail":"plain-language detail","iconName":"SF Symbol-like name"}],
          "metrics": [{"value":"stat","label":"stat label","trend":"optional trend"}],
          "formFields": [{"label":"field label","placeholder":"placeholder","kind":"text|email|textarea|number|tel","required":true}],
          "reactCode": "optional React component using className if-card...",
          "htmlCode": "optional standalone HTML body/component markup",
          "cssCode": "optional CSS for the generated component",
          "swiftUICode": "optional SwiftUI View named GeneratedComponent"
        }
        Limit sections to 3-5, metrics to 2-4, and formFields to 0-4. Use only strings, booleans, arrays, and objects.
        """
    }

    private func userPrompt(prompt: String, selectedTemplate: DesignTemplate?, configuration: DesignConfiguration) -> String {
        let templateHint = selectedTemplate.map { "Suggested component family: \($0.title) (hint only; follow the prompt first)." } ?? "No selected template; choose the best component family."
        return """
        User prompt: \(prompt)
        \(templateHint)
        Style: \(configuration.visualStyle.rawValue)
        Theme: \(configuration.theme.rawValue)
        Motion: \(configuration.motionLevel.rawValue)
        Target export format: \(configuration.outputType.rawValue)
        Make the preview content prompt-specific rather than a generic template.
        """
    }

    private func design(from spec: AIDesignSpec, prompt: String, selectedTemplate: DesignTemplate?, fallbackTemplate: DesignTemplate, configuration: DesignConfiguration) -> GeneratedDesign {
        let templateID = normalizedID(spec.componentType, fallback: selectedTemplate?.id ?? "ai-generated")
        let templateTitle = spec.title.trimmed.isEmpty ? selectedTemplate?.title ?? "AI generated component" : spec.title.trimmed
        let template = DesignTemplate(id: templateID, title: templateTitle, shortDescription: "Prompt-specific AI component generated from your instructions.", iconName: selectedTemplate?.iconName ?? iconName(for: spec, fallback: fallbackTemplate.iconName), defaultPrompt: prompt, tags: ["AI", configuration.visualStyle.rawValue])
        var design = GeneratedDesign(
            template: template,
            prompt: prompt,
            configuration: configuration,
            headline: spec.headline.trimmed,
            subheadline: spec.subheadline.trimmed,
            createdAt: Date()
        )
        design.kicker = spec.kicker.nonEmpty ?? "AI generated"
        design.primaryAction = spec.primaryAction.nonEmpty ?? "Get started"
        design.secondaryAction = spec.secondaryAction.nonEmpty ?? "Learn more"
        design.sections = spec.sections.cleaned(max: 5)
        design.metrics = spec.metrics.cleaned(max: 4)
        design.formFields = spec.formFields.cleaned(max: 4)
        design.reactCode = spec.reactCode?.cleanCode.nonEmpty
        design.htmlCode = spec.htmlCode?.cleanCode.nonEmpty
        design.cssCode = spec.cssCode?.cleanCode.nonEmpty
        design.swiftUICode = spec.swiftUICode?.cleanCode.nonEmpty
        design.generationMode = .ai
        design.generationStatus = "AI-powered design generated with the configured provider."
        design.generationError = nil
        return design
    }

    private func fallbackDesign(prompt: String, template: DesignTemplate, configuration: DesignConfiguration, reason: String, error: String) -> GeneratedDesign {
        var design = GeneratedDesign(
            template: template,
            prompt: prompt,
            configuration: configuration,
            headline: headlineForTemplate(template, prompt: prompt),
            subheadline: subheadlineForTemplate(template, style: configuration.visualStyle),
            createdAt: Date()
        )
        design.kicker = "Template fallback"
        design.primaryAction = actionForTemplate(template)
        design.secondaryAction = "View details"
        design.sections = fallbackSections(for: template)
        design.metrics = fallbackMetrics(for: template)
        design.formFields = fallbackFields(for: template)
        design.generationMode = .fallback
        design.generationStatus = reason
        design.generationError = error
        return design
    }

    private func headlineForTemplate(_ template: DesignTemplate, prompt: String) -> String {
        switch template.id {
        case "pricing-card": return "Launch Plan Pro"
        case "dashboard-widget": return "Growth Pulse"
        case "onboarding-hero": return "Start Smarter"
        case "checkout-form": return "Fast Checkout"
        case "portfolio-card": return "Featured Build"
        default: return prompt.components(separatedBy: " ").prefix(5).joined(separator: " ")
        }
    }

    private func subheadlineForTemplate(_ template: DesignTemplate, style: VisualStyle) -> String {
        switch template.id {
        case "pricing-card": return "Template fallback: a polished plan card with monthly and yearly pricing ready to paste into your site."
        case "dashboard-widget": return "Template fallback: an interactive metrics block that helps visitors understand momentum at a glance."
        case "onboarding-hero": return "Template fallback: a swipeable product intro that explains value before asking users to act."
        case "checkout-form": return "Template fallback: a beginner-friendly form pattern with helpful inline feedback and a clear submit state."
        case "portfolio-card": return "Template fallback: a compact case-study card with visual depth, proof points, and a confident action."
        default: return "Template fallback generated with a \(style.rawValue.lowercased()) style because AI was unavailable."
        }
    }

    private func actionForTemplate(_ template: DesignTemplate) -> String {
        switch template.id {
        case "pricing-card": return "Choose plan"
        case "dashboard-widget": return "View report"
        case "onboarding-hero": return "Start tour"
        case "checkout-form": return "Check form"
        case "portfolio-card": return "View project"
        default: return "Get started"
        }
    }

    private func fallbackSections(for template: DesignTemplate) -> [GeneratedSection] {
        switch template.id {
        case "pricing-card": return [GeneratedSection(title: "Responsive component code", detail: "Copy beginner-friendly code into your project."), GeneratedSection(title: "Clear conversion path", detail: "Primary and secondary actions are ready to customize."), GeneratedSection(title: "Fallback mode", detail: "Connect an API key for prompt-specific AI output.")]
        case "onboarding-hero": return [GeneratedSection(title: "Describe it", detail: "Start with a plain sentence."), GeneratedSection(title: "Preview live", detail: "Test the swipe and tap states."), GeneratedSection(title: "Ship the code", detail: "Export a compact starter package.")]
        default: return [GeneratedSection(title: "Prompt matched", detail: "A built-in template was selected from your prompt."), GeneratedSection(title: "Editable style", detail: "Theme, motion, and output can still be customized."), GeneratedSection(title: "AI unavailable", detail: "Add or fix an API key to generate unique AI content.")]
        }
    }

    private func fallbackMetrics(for template: DesignTemplate) -> [GeneratedMetric] {
        switch template.id {
        case "dashboard-widget": return [GeneratedMetric(value: "$48.2k", label: "Revenue", trend: "+18%"), GeneratedMetric(value: "12.8k", label: "Users", trend: "+9%"), GeneratedMetric(value: "8.4%", label: "Conversion", trend: "+2.1%")]
        case "portfolio-card": return [GeneratedMetric(value: "42%", label: "lift"), GeneratedMetric(value: "3 days", label: "built"), GeneratedMetric(value: "A+", label: "grade")]
        default: return []
        }
    }

    private func fallbackFields(for template: DesignTemplate) -> [GeneratedFormField] {
        guard template.id == "checkout-form" else { return [] }
        return [GeneratedFormField(label: "Email", placeholder: "you@example.com", kind: "email"), GeneratedFormField(label: "Project details", placeholder: "Tell us what you want to build", kind: "textarea")]
    }

    private func iconName(for spec: AIDesignSpec, fallback: String) -> String {
        if !spec.formFields.isEmpty { return "text.badge.checkmark" }
        if !spec.metrics.isEmpty { return "chart.xyaxis.line" }
        if spec.componentType.lowercased().contains("hero") { return "sparkles.rectangle.stack" }
        return fallback
    }

    private func normalizedID(_ value: String, fallback: String) -> String {
        let lowercased = value.lowercased()
        let allowed = lowercased.map { character in
            if character.isLetter || character.isNumber { return String(character) }
            return "-"
        }.joined()
        let collapsed = allowed.split(separator: "-").joined(separator: "-")
        return collapsed.isEmpty ? fallback : collapsed
    }

    private func extractJSON(from content: String) -> String {
        var text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text.replacingOccurrences(of: "```json", with: "")
            text = text.replacingOccurrences(of: "```JSON", with: "")
            text = text.replacingOccurrences(of: "```", with: "")
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let start = text.firstIndex(of: "{") else { return text }
        var depth = 0
        var inString = false
        var escape = false
        var index = start
        while index < text.endIndex {
            let character = text[index]
            if escape {
                escape = false
            } else if character == "\\" && inString {
                escape = true
            } else if character == "\"" {
                inString.toggle()
            } else if !inString {
                if character == "{" {
                    depth += 1
                } else if character == "}" {
                    depth -= 1
                    if depth == 0 {
                        return String(text[start...index])
                    }
                }
            }
            index = text.index(after: index)
        }
        return String(text[start...])
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let responseFormat: ResponseFormat

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case responseFormat = "response_format"
    }
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ResponseFormat: Encodable {
    let type: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ChatMessage
    }
}

private struct AIDesignSpec: Decodable {
    var componentType: String = "ai-generated"
    var title: String = "AI generated component"
    var kicker: String = "AI generated"
    var headline: String
    var subheadline: String
    var primaryAction: String = "Get started"
    var secondaryAction: String = "Learn more"
    var sections: [GeneratedSection] = []
    var metrics: [GeneratedMetric] = []
    var formFields: [GeneratedFormField] = []
    var reactCode: String?
    var htmlCode: String?
    var cssCode: String?
    var swiftUICode: String?

    enum CodingKeys: String, CodingKey {
        case componentType
        case title
        case kicker
        case headline
        case subheadline
        case primaryAction
        case secondaryAction
        case sections
        case metrics
        case formFields
        case reactCode
        case htmlCode
        case cssCode
        case swiftUICode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        componentType = try container.decodeIfPresent(String.self, forKey: .componentType) ?? "ai-generated"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "AI generated component"
        kicker = try container.decodeIfPresent(String.self, forKey: .kicker) ?? "AI generated"
        headline = try container.decodeIfPresent(String.self, forKey: .headline) ?? ""
        subheadline = try container.decodeIfPresent(String.self, forKey: .subheadline) ?? ""
        primaryAction = try container.decodeIfPresent(String.self, forKey: .primaryAction) ?? "Get started"
        secondaryAction = try container.decodeIfPresent(String.self, forKey: .secondaryAction) ?? "Learn more"
        sections = try container.decodeIfPresent([GeneratedSection].self, forKey: .sections) ?? []
        metrics = try container.decodeIfPresent([GeneratedMetric].self, forKey: .metrics) ?? []
        formFields = try container.decodeIfPresent([GeneratedFormField].self, forKey: .formFields) ?? []
        reactCode = try container.decodeIfPresent(String.self, forKey: .reactCode)
        htmlCode = try container.decodeIfPresent(String.self, forKey: .htmlCode)
        cssCode = try container.decodeIfPresent(String.self, forKey: .cssCode)
        swiftUICode = try container.decodeIfPresent(String.self, forKey: .swiftUICode)
    }
}

private enum GenerationError: LocalizedError {
    case invalidEndpoint
    case insecureEndpoint
    case invalidResponse
    case apiFailed(String)
    case emptyResponse
    case invalidJSON
    case missingRequiredFields

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint: return "The AI endpoint URL is invalid."
        case .insecureEndpoint: return "The AI endpoint must use https:// to keep your API key safe (http:// is only allowed for localhost)."
        case .invalidResponse: return "The AI provider returned an invalid response."
        case .apiFailed(let message): return message
        case .emptyResponse: return "The AI provider did not return message content."
        case .invalidJSON: return "The AI response could not be converted to JSON."
        case .missingRequiredFields: return "The AI JSON did not include a headline and subheadline."
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nonEmpty: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }

    var cleanCode: String {
        var value = trimmed
        if value.hasPrefix("```") {
            value = value.replacingOccurrences(of: "```jsx", with: "")
            value = value.replacingOccurrences(of: "```javascript", with: "")
            value = value.replacingOccurrences(of: "```html", with: "")
            value = value.replacingOccurrences(of: "```css", with: "")
            value = value.replacingOccurrences(of: "```swift", with: "")
            value = value.replacingOccurrences(of: "```", with: "")
        }
        return value.trimmed
    }
}

private extension Array where Element == GeneratedSection {
    func cleaned(max count: Int) -> [GeneratedSection] {
        prefix(count).compactMap { section in
            guard let title = section.title.nonEmpty, let detail = section.detail.nonEmpty else { return nil }
            return GeneratedSection(title: title, detail: detail, iconName: section.iconName.nonEmpty ?? "sparkles")
        }
    }
}

private extension Array where Element == GeneratedMetric {
    func cleaned(max count: Int) -> [GeneratedMetric] {
        prefix(count).compactMap { metric in
            guard let value = metric.value.nonEmpty, let label = metric.label.nonEmpty else { return nil }
            return GeneratedMetric(value: value, label: label, trend: metric.trend)
        }
    }
}

private extension Array where Element == GeneratedFormField {
    func cleaned(max count: Int) -> [GeneratedFormField] {
        prefix(count).compactMap { field in
            guard let label = field.label.nonEmpty else { return nil }
            return GeneratedFormField(label: label, placeholder: field.placeholder.nonEmpty ?? label, kind: field.kind.nonEmpty ?? "text", required: field.required)
        }
    }
}
