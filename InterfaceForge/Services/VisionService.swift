import Foundation
import UIKit

/// Uses GPT-4o vision (or compatible multi-modal API) to analyze a screenshot
/// and produce a UI component description that feeds into DesignGenerator.
struct VisionService {
    struct VisionResult {
        let componentDescription: String
        let suggestedTemplate: String?
        let error: String?
    }

    /// Analyze an image and return a text description suitable for the DesignGenerator prompt.
    func analyze(image: UIImage, apiKey: String, endpoint: String, model: String) async -> VisionResult {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            return VisionResult(componentDescription: "", suggestedTemplate: nil, error: "Add an API key to use screenshot analysis.")
        }

        guard let base64 = encodeImage(image) else {
            return VisionResult(componentDescription: "", suggestedTemplate: nil, error: "Could not encode the image.")
        }

        do {
            let result = try await requestVisionAnalysis(base64Image: base64, apiKey: trimmedKey, endpoint: endpoint, model: model)
            return result
        } catch {
            return VisionResult(componentDescription: "", suggestedTemplate: nil, error: "Vision analysis failed: \(error.localizedDescription)")
        }
    }

    private func encodeImage(_ image: UIImage) -> String? {
        // Resize to max 1024px on longest side to keep payload reasonable
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let data = resized?.jpegData(compressionQuality: 0.8) else { return nil }
        return data.base64EncodedString()
    }

    private func requestVisionAnalysis(base64Image: String, apiKey: String, endpoint: String, model: String) async throws -> VisionResult {
        // Build the vision-compatible endpoint
        let trimmedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmedEndpoint) else {
            throw VisionError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let visionModel = model.contains("4o") || model.contains("vision") ? model : "gpt-4o"

        let body: [String: Any] = [
            "model": visionModel,
            "messages": [
                [
                    "role": "system",
                    "content": """
                    You are an expert UI analyst for InterfaceForge. Given a screenshot or mockup image, describe the UI component in a way that can be used as a prompt for generating a similar component.
                    
                    Return JSON only:
                    {
                      "description": "A detailed prompt describing the UI component, its layout, colors, typography, sections, and interactive elements. Be specific about structure.",
                      "suggestedTemplate": "one of: pricing-card, dashboard-widget, onboarding-hero, checkout-form, portfolio-card, testimonial-carousel, feature-grid, cta-banner, blog-card, login-screen, settings-panel, stats-overview, notification-toast, team-roster, faq-accordion, image-gallery, timeline-feed, email-signup, comparison-table, empty-state, or null if no template matches"
                    }
                    """
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "high"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": "Analyze this UI screenshot and describe it as a component prompt for InterfaceForge."
                        ]
                    ]
                ]
            ],
            "temperature": 0.5,
            "max_tokens": 500
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw VisionError.apiFailed(String(body.prefix(240)))
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw VisionError.invalidResponse
        }

        // Try to parse as JSON first
        if let jsonData = content.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            let description = parsed["description"] as? String ?? content
            let template = parsed["suggestedTemplate"] as? String
            return VisionResult(componentDescription: description, suggestedTemplate: template, error: nil)
        }

        // Fallback: use raw content as description
        return VisionResult(componentDescription: content, suggestedTemplate: nil, error: nil)
    }

    private enum VisionError: LocalizedError {
        case invalidEndpoint
        case apiFailed(String)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .invalidEndpoint: return "The AI endpoint URL is invalid."
            case .apiFailed(let msg): return msg
            case .invalidResponse: return "Could not parse the vision response."
            }
        }
    }
}
