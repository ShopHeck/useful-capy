import Foundation

struct CodeExportService {
    func makePackage(for design: GeneratedDesign, outputType: OutputType) -> ExportPackage {
        switch outputType {
        case .react:
            return reactPackage(for: design)
        case .html:
            return htmlPackage(for: design)
        case .swiftUI:
            return swiftUIPackage(for: design)
        }
    }

    func writePackageToTemporaryFolder(_ package: ExportPackage) throws -> URL {
        let folderName = package.packageName.replacingOccurrences(of: " ", with: "-")
        let folderURL = FileManager.default.temporaryDirectory.appendingPathComponent(folderName, isDirectory: true)
        if FileManager.default.fileExists(atPath: folderURL.path) {
            try FileManager.default.removeItem(at: folderURL)
        }
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        for file in package.files {
            let fileURL = folderURL.appendingPathComponent(file.name)
            try file.contents.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        return folderURL
    }

    private func reactPackage(for design: GeneratedDesign) -> ExportPackage {
        let className = cssClassName(for: design)
        let files = [
            ExportFile(name: "Component.jsx", contents: reactComponent(for: design, className: className)),
            ExportFile(name: "styles.css", contents: css(for: design, className: className)),
            ExportFile(name: "README.md", contents: readme(for: design, outputType: .react))
        ]
        return ExportPackage(packageName: "InterfaceForge-React-Package", outputType: .react, files: files, beginnerGuide: guide(for: .react))
    }

    private func htmlPackage(for design: GeneratedDesign) -> ExportPackage {
        let className = cssClassName(for: design)
        let files = [
            ExportFile(name: "index.html", contents: html(for: design, className: className)),
            ExportFile(name: "styles.css", contents: css(for: design, className: className)),
            ExportFile(name: "README.md", contents: readme(for: design, outputType: .html))
        ]
        return ExportPackage(packageName: "InterfaceForge-HTML-Package", outputType: .html, files: files, beginnerGuide: guide(for: .html))
    }

    private func swiftUIPackage(for design: GeneratedDesign) -> ExportPackage {
        let files = [
            ExportFile(name: "GeneratedComponent.swift", contents: swiftUI(for: design)),
            ExportFile(name: "README.md", contents: readme(for: design, outputType: .swiftUI))
        ]
        return ExportPackage(packageName: "InterfaceForge-SwiftUI-Package", outputType: .swiftUI, files: files, beginnerGuide: guide(for: .swiftUI))
    }

    private func cssClassName(for design: GeneratedDesign) -> String {
        design.template.id
    }

    private func reactComponent(for design: GeneratedDesign, className: String) -> String {
        switch design.template.id {
        case "dashboard-widget":
            return """
            import './styles.css';

            export default function Component() {
              const metrics = ['Revenue', 'Users', 'Conversion'];
              return (
                <section className=\"if-card \(className)\">
                  <p className=\"if-kicker\">Generated with InterfaceForge</p>
                  <h2>\(design.headline)</h2>
                  <p>\(design.subheadline)</p>
                  <div className=\"if-tabs\">{metrics.map(item => <button key={item}>{item}</button>)}</div>
                  <div className=\"if-chart\"><span></span><span></span><span></span><span></span></div>
                </section>
              );
            }
            """
        case "checkout-form":
            return """
            import './styles.css';

            export default function Component() {
              return (
                <form className=\"if-card \(className)\">
                  <p className=\"if-kicker\">Secure component</p>
                  <h2>\(design.headline)</h2>
                  <label>Email<input placeholder=\"you@example.com\" /></label>
                  <label>Project need<textarea placeholder=\"Tell us what you want to build\" /></label>
                  <button type=\"button\">Send request</button>
                </form>
              );
            }
            """
        default:
            return """
            import './styles.css';

            export default function Component() {
              return (
                <section className=\"if-card \(className)\">
                  <p className=\"if-kicker\">Generated with InterfaceForge</p>
                  <h2>\(design.headline)</h2>
                  <p>\(design.subheadline)</p>
                  <div className=\"if-actions\">
                    <button>Get started</button>
                    <a href=\"#learn\">See details</a>
                  </div>
                </section>
              );
            }
            """
        }
    }

    private func html(for design: GeneratedDesign, className: String) -> String {
        """
        <!doctype html>
        <html lang=\"en\">
        <head>
          <meta charset=\"utf-8\" />
          <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
          <title>\(design.headline)</title>
          <link rel=\"stylesheet\" href=\"styles.css\" />
        </head>
        <body>
          <main class=\"if-page\">
            <section class=\"if-card \(className)\">
              <p class=\"if-kicker\">Generated with InterfaceForge</p>
              <h1>\(design.headline)</h1>
              <p>\(design.subheadline)</p>
              <div class=\"if-actions\">
                <button>Get started</button>
                <a href=\"#\">Learn more</a>
              </div>
            </section>
          </main>
        </body>
        </html>
        """
    }

    private func css(for design: GeneratedDesign, className: String) -> String {
        let colors = exportColors(for: design.configuration.theme)
        return """
        :root {
          --if-accent: \(colors.accent);
          --if-secondary: \(colors.secondary);
          --if-ink: #111827;
          --if-muted: #64748b;
          --if-card: rgba(255,255,255,.86);
        }

        * { box-sizing: border-box; }
        body { margin: 0; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #f7f9ff; color: var(--if-ink); }
        .if-page { min-height: 100vh; display: grid; place-items: center; padding: 32px; background: radial-gradient(circle at top left, \(colors.accent)33, transparent 34%), radial-gradient(circle at bottom right, \(colors.secondary)2e, transparent 30%); }
        .if-card { width: min(420px, 100%); padding: 28px; border-radius: \(Int(design.configuration.visualStyle.cornerRadius))px; background: var(--if-card); border: 1px solid rgba(255,255,255,.7); box-shadow: 0 24px 80px rgba(15, 23, 42, .16); backdrop-filter: blur(18px); }
        .if-kicker { margin: 0 0 10px; color: var(--if-accent); font-weight: 800; letter-spacing: .08em; text-transform: uppercase; font-size: 12px; }
        h1, h2 { margin: 0; font-size: clamp(32px, 7vw, 46px); line-height: .95; letter-spacing: -.05em; }
        p { color: var(--if-muted); line-height: 1.6; }
        button, .if-actions a { min-height: 44px; border: 0; border-radius: 999px; padding: 0 18px; font-weight: 800; text-decoration: none; display: inline-flex; align-items: center; justify-content: center; }
        button { color: white; background: linear-gradient(135deg, var(--if-accent), var(--if-secondary)); box-shadow: 0 14px 30px \(colors.accent)44; }
        .if-actions { display: flex; align-items: center; gap: 12px; margin-top: 22px; }
        .if-actions a { color: var(--if-ink); background: rgba(15, 23, 42, .06); }
        .if-tabs { display: flex; gap: 8px; margin: 20px 0; flex-wrap: wrap; }
        .if-tabs button { min-height: 38px; font-size: 13px; }
        .if-chart { display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; align-items: end; height: 120px; }
        .if-chart span { display: block; border-radius: 16px 16px 6px 6px; background: linear-gradient(180deg, var(--if-accent), var(--if-secondary)); min-height: 36px; }
        .if-chart span:nth-child(2) { min-height: 74px; opacity: .75; }
        .if-chart span:nth-child(3) { min-height: 106px; }
        .if-chart span:nth-child(4) { min-height: 58px; opacity: .86; }
        label { display: grid; gap: 8px; margin: 14px 0; font-weight: 700; }
        input, textarea { width: 100%; border: 1px solid #dbe3ef; border-radius: 18px; padding: 14px 16px; font: inherit; background: white; }
        textarea { min-height: 94px; resize: vertical; }
        """
    }

    private func swiftUI(for design: GeneratedDesign) -> String {
        """
        import SwiftUI

        struct GeneratedComponent: View {
            var body: some View {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Generated with InterfaceForge")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                    Text("\(design.headline)")
                        .font(.largeTitle.weight(.black))
                    Text("\(design.subheadline)")
                        .foregroundStyle(.secondary)
                    Button("Get started") { }
                        .buttonStyle(.borderedProminent)
                }
                .padding(28)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding()
            }
        }
        """
    }

    private func readme(for design: GeneratedDesign, outputType: OutputType) -> String {
        switch outputType {
        case .react:
            return """
            # InterfaceForge React package

            This package contains one generated component for: \(design.prompt)

            ## How to use it
            1. Copy `Component.jsx` and `styles.css` into your React app.
            2. Put both files in the same folder, for example `src/components/GeneratedComponent/`.
            3. Import it with `import Component from './components/GeneratedComponent/Component';`.
            4. Add `<Component />` anywhere in your page.
            5. Upload or deploy your website the same way you normally do.
            """
        case .html:
            return """
            # InterfaceForge HTML package

            This package contains a simple web component for: \(design.prompt)

            ## How to use it
            1. Keep `index.html` and `styles.css` in the same folder.
            2. Open `index.html` in a browser to preview it.
            3. Upload both files to your website host.
            4. To place it inside an existing page, copy the `<section>` from `index.html` and the CSS from `styles.css`.
            """
        case .swiftUI:
            return """
            # InterfaceForge SwiftUI package

            This package contains a SwiftUI view for: \(design.prompt)

            ## How to use it
            1. Drag `GeneratedComponent.swift` into your Xcode project.
            2. Add `GeneratedComponent()` inside any SwiftUI screen.
            3. Run your app to preview it.
            """
        }
    }

    private func guide(for outputType: OutputType) -> String {
        switch outputType {
        case .react:
            return """
            1. Save the shared package to your computer.
            2. Open your React project folder.
            3. Create a new folder named GeneratedComponent inside src/components.
            4. Put Component.jsx and styles.css in that folder.
            5. Import the component on the page where you want it.
            6. Deploy your site normally. The design is just code, so no extra service is required.
            """
        case .html:
            return """
            1. Save the shared package.
            2. Open index.html to check the design.
            3. Upload index.html and styles.css to your website host.
            4. If you already have a page, copy the section code into that page and copy the CSS into your stylesheet.
            """
        case .swiftUI:
            return """
            1. Save GeneratedComponent.swift.
            2. Drag it into your Xcode project.
            3. Type GeneratedComponent() where you want the design to appear.
            4. Run your app.
            """
        }
    }

    private func exportColors(for theme: ColorTheme) -> (accent: String, secondary: String) {
        switch theme {
        case .aurora: return ("#4dd6ad", "#387af5")
        case .ocean: return ("#3380f5", "#19c7db")
        case .sunset: return ("#ff634d", "#ffb847")
        case .graphite: return ("#9eaabd", "#2e3345")
        case .candy: return ("#f55cd4", "#8761ff")
        }
    }
}
