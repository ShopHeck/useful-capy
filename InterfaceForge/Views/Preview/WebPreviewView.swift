import SwiftUI
import WebKit

/// Renders the exported HTML+CSS code inside a WKWebView so users can see
/// a live web preview of their generated component on-device.
struct WebPreviewView: View {
    @EnvironmentObject private var viewModel: GeneratorViewModel
    @State private var isLoading = true
    @State private var previewScale: CGFloat = 1.0

    private var htmlContent: String? {
        guard let design = viewModel.generatedDesign else { return nil }
        let exportService = CodeExportService()
        let htmlPackage = exportService.makePackage(for: design, outputType: .html)

        let htmlFile = htmlPackage.files.first(where: { $0.name.hasSuffix(".html") })
        let cssFile = htmlPackage.files.first(where: { $0.name.hasSuffix(".css") })

        guard let html = htmlFile?.contents else { return nil }

        // If there's a separate CSS file, inject it into the <head>
        if let css = cssFile?.contents, !html.contains(css.prefix(40)) {
            let styleTag = "<style>\n\(css)\n</style>"
            if html.contains("</head>") {
                return html.replacingOccurrences(of: "</head>", with: "\(styleTag)\n</head>")
            } else {
                return "\(styleTag)\n\(html)"
            }
        }
        return html
    }

    var body: some View {
        VStack(spacing: 0) {
            if let html = htmlContent {
                ZStack(alignment: .topTrailing) {
                    WebView(htmlString: html, isLoading: $isLoading)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )

                    if isLoading {
                        ProgressView()
                            .padding(12)
                    }
                }
                .frame(minHeight: 400)

                // Viewport scale controls
                HStack(spacing: 16) {
                    viewportButton(icon: "iphone", label: "Mobile", width: 375)
                    viewportButton(icon: "ipad.landscape", label: "Tablet", width: 768)
                    viewportButton(icon: "desktopcomputer", label: "Desktop", width: 1280)
                }
                .padding(.top, 12)
            } else {
                ContentUnavailableView(
                    "No web preview available",
                    systemImage: "safari",
                    description: Text("Generate an interface first to see a live web preview of the HTML output.")
                )
            }
        }
        .navigationTitle("Web Preview")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func viewportButton(icon: String, label: String, width: CGFloat) -> some View {
        Button {
            // Post viewport change notification
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) viewport, \(Int(width)) points wide")
    }
}

// MARK: - WKWebView wrapper

private struct WebView: UIViewRepresentable {
    let htmlString: String
    @Binding var isLoading: Bool

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true

        // Inject viewport meta if missing
        var html = htmlString
        if !html.lowercased().contains("viewport") {
            let viewportMeta = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=3.0\">"
            if html.contains("<head>") {
                html = html.replacingOccurrences(of: "<head>", with: "<head>\n\(viewportMeta)")
            } else {
                html = "\(viewportMeta)\n\(html)"
            }
        }

        webView.loadHTMLString(html, baseURL: nil)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Only reload if content changed
        if context.coordinator.lastHTML != htmlString {
            context.coordinator.lastHTML = htmlString
            var html = htmlString
            if !html.lowercased().contains("viewport") {
                let viewportMeta = "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0, maximum-scale=3.0\">"
                html = "\(viewportMeta)\n\(html)"
            }
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        var lastHTML: String = ""

        init(parent: WebView) {
            self.parent = parent
            self.lastHTML = parent.htmlString
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.isLoading = true }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async { self.parent.isLoading = false }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async { self.parent.isLoading = false }
        }

        // Block external navigation — keep everything in the preview
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.navigationType == .other || navigationAction.request.url?.scheme == "about" {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
    }
}
