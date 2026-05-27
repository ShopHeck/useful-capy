import Foundation

/// Routes AI generation through a hosted proxy for Pro subscribers,
/// removing the need for them to manage their own API key.
///
/// The proxy is a thin relay (e.g. Cloudflare Worker / Vercel Edge Function)
/// that validates the App Store receipt or a device token and forwards the
/// request to the upstream OpenAI-compatible endpoint with a server-side key.
///
/// Set `ProxyService.baseURL` to your deployed proxy URL before enabling.
struct ProxyService {

    // MARK: - Configuration

    /// Change this to your deployed proxy endpoint.
    /// Leave `nil` to disable proxy mode entirely (BYOK only).
    static var baseURL: URL? = nil // e.g. URL(string: "https://if-proxy.yoursite.workers.dev/v1/chat/completions")

    /// Model to use via the proxy. The proxy can also override this server-side.
    static var defaultModel: String = "gpt-4.1-mini"

    // MARK: - Check availability

    static var isConfigured: Bool { baseURL != nil }

    // MARK: - Build request

    /// Creates a URLRequest aimed at the hosted proxy.
    /// The proxy authenticates using the device token (from StoreKit receipt).
    static func makeRequest(
        prompt: String,
        systemPrompt: String,
        temperature: Double = 0.75,
        deviceToken: String? = nil
    ) throws -> URLRequest {
        guard let url = baseURL else {
            throw ProxyError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        // Auth: the proxy validates this token against App Store Server API
        if let token = deviceToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let body: [String: Any] = [
            "model": Self.defaultModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "temperature": temperature,
            "response_format": ["type": "json_object"]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}

enum ProxyError: LocalizedError {
    case notConfigured
    case unauthorized
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "The hosted AI proxy is not configured. Use your own API key or contact the developer."
        case .unauthorized:
            return "Your Pro subscription could not be verified. Restore purchases or use your own API key."
        case .serverError(let message):
            return "Proxy error: \(message)"
        }
    }
}
