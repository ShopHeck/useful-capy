import Foundation

struct CodeExportService {
    func makePackage(for design: GeneratedDesign, outputType: OutputType) -> ExportPackage {
        switch outputType {
        case .react:
            return reactPackage(for: design)
        case .html:
            return htmlPackage(for: design)
        case .tailwind:
            return tailwindPackage(for: design)
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
        let aiReact = design.reactCode.cleanedCode
        let aiCSS = design.cssCode.cleanedCode
        let files = [
            ExportFile(name: "Component.jsx", contents: provenanceComment(forAI: aiReact != nil, style: .js) + (aiReact ?? reactComponent(for: design, className: className))),
            ExportFile(name: "styles.css", contents: provenanceComment(forAI: aiCSS != nil, style: .css) + (aiCSS ?? css(for: design, className: className))),
            ExportFile(name: "tokens.css", contents: tokensCSS(for: design)),
            ExportFile(name: "package.json", contents: packageJSON(for: design)),
            ExportFile(name: "LICENSE", contents: licenseText()),
            ExportFile(name: "README.md", contents: readme(for: design, outputType: .react, aiCount: [aiReact, aiCSS].compactMap { $0 }.count))
        ]
        return ExportPackage(packageName: packageName(for: design, suffix: "React"), outputType: .react, files: files, beginnerGuide: guide(for: .react))
    }

    private func htmlPackage(for design: GeneratedDesign) -> ExportPackage {
        let className = cssClassName(for: design)
        let aiHTML = design.htmlCode.cleanedCode
        let aiCSS = design.cssCode.cleanedCode
        let files = [
            ExportFile(name: "index.html", contents: provenanceComment(forAI: aiHTML != nil, style: .html) + (aiHTML ?? html(for: design, className: className))),
            ExportFile(name: "styles.css", contents: provenanceComment(forAI: aiCSS != nil, style: .css) + (aiCSS ?? css(for: design, className: className))),
            ExportFile(name: "tokens.css", contents: tokensCSS(for: design)),
            ExportFile(name: "LICENSE", contents: licenseText()),
            ExportFile(name: "README.md", contents: readme(for: design, outputType: .html, aiCount: [aiHTML, aiCSS].compactMap { $0 }.count))
        ]
        return ExportPackage(packageName: packageName(for: design, suffix: "HTML"), outputType: .html, files: files, beginnerGuide: guide(for: .html))
    }

    private func tailwindPackage(for design: GeneratedDesign) -> ExportPackage {
        let files = [
            ExportFile(name: "index.html", contents: tailwindHTML(for: design)),
            ExportFile(name: "tailwind.config.js", contents: tailwindConfig(for: design)),
            ExportFile(name: "LICENSE", contents: licenseText()),
            ExportFile(name: "README.md", contents: readme(for: design, outputType: .tailwind, aiCount: 0))
        ]
        return ExportPackage(packageName: packageName(for: design, suffix: "Tailwind"), outputType: .tailwind, files: files, beginnerGuide: guide(for: .tailwind))
    }

    private func tailwindHTML(for design: GeneratedDesign) -> String {
        let sections = normalizedSections(for: design)
        let metrics = design.metrics
        let fields = normalizedFields(for: design)
        let metricHTML = metrics.isEmpty ? "" : """
              <div class="grid grid-cols-2 md:grid-cols-\(min(metrics.count, 4)) gap-3 mb-6" aria-label="Key stats">
        \(metrics.map { "        <div class=\"bg-white/70 rounded-2xl p-4 border border-slate-200/60\"><strong class=\"block text-2xl tracking-tight\">\($0.value.htmlEscaped)</strong><span class=\"block text-slate-500 text-sm\">\($0.label.htmlEscaped)</span>\($0.trend.isEmpty ? "" : "<small class=\"block text-emerald-600 font-bold text-xs mt-1\">\($0.trend.htmlEscaped)</small>")</div>" }.joined(separator: "\n"))
              </div>
        """
        let fieldHTML = fields.isEmpty ? "" : """
              <form class="grid gap-3 mb-6">
        \(fields.map { field in
            let required = field.required ? " required" : ""
            if field.kind == "textarea" {
                return "        <label class=\"font-semibold text-sm\">\(field.label.htmlEscaped)<textarea placeholder=\"\(field.placeholder.attributeEscaped)\" class=\"w-full border border-slate-300 rounded-xl p-3 mt-1 focus:outline-none focus:ring-2 focus:ring-blue-500/40\" rows=\"3\"\(required)></textarea></label>"
            }
            return "        <label class=\"font-semibold text-sm\">\(field.label.htmlEscaped)<input type=\"\(field.kind.attributeEscaped)\" placeholder=\"\(field.placeholder.attributeEscaped)\" class=\"w-full border border-slate-300 rounded-xl p-3 mt-1 focus:outline-none focus:ring-2 focus:ring-blue-500/40\"\(required) /></label>"
        }.joined(separator: "\n"))
              </form>
        """
        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>\(design.headline.htmlEscaped)</title>
          <script src="https://cdn.tailwindcss.com"></script>
        </head>
        <body class="bg-gradient-to-br from-slate-50 to-blue-50 min-h-screen grid place-items-center p-6">
          <main class="w-full max-w-2xl bg-white/80 backdrop-blur-xl rounded-3xl shadow-2xl shadow-slate-200/60 border border-white/70 p-8 md:p-10">
            <p class="text-xs font-extrabold uppercase tracking-widest text-blue-600 mb-3">\(design.kicker.htmlEscaped)</p>
            <h1 class="text-4xl md:text-5xl font-black tracking-tight text-slate-900 mb-3">\(design.headline.htmlEscaped)</h1>
            <p class="text-lg text-slate-500 mb-6 max-w-prose">\(design.subheadline.htmlEscaped)</p>
        \(metricHTML)
        \(fieldHTML)
            <div class="grid gap-3 mb-6">
        \(sections.map { "      <article class=\"flex gap-3 p-4 bg-slate-50/80 rounded-2xl\"><span class=\"flex-shrink-0 w-8 h-8 grid place-items-center bg-gradient-to-br from-blue-500 to-indigo-600 text-white rounded-full text-sm font-bold\">✦</span><div><h2 class=\"font-bold text-slate-800\">\($0.title.htmlEscaped)</h2><p class=\"text-slate-500 text-sm\">\($0.detail.htmlEscaped)</p></div></article>" }.joined(separator: "\n"))
            </div>
            <div class="flex flex-wrap gap-3">
              <button type="button" class="bg-gradient-to-r from-blue-500 to-indigo-600 text-white font-bold px-6 py-3 rounded-full shadow-lg shadow-blue-500/30 hover:shadow-xl transition">\(design.primaryAction.htmlEscaped)</button>
              <a href="#details" class="bg-slate-100 text-slate-700 font-semibold px-6 py-3 rounded-full hover:bg-slate-200 transition">\(design.secondaryAction.htmlEscaped)</a>
            </div>
          </main>
        </body>
        </html>
        """
    }

    private func swiftUIPackage(for design: GeneratedDesign) -> ExportPackage {
        let aiSwift = design.swiftUICode.cleanedCode
        let files = [
            ExportFile(name: "GeneratedComponent.swift", contents: provenanceComment(forAI: aiSwift != nil, style: .swift) + (aiSwift ?? swiftUI(for: design))),
            ExportFile(name: "Theme.swift", contents: themeSwift(for: design)),
            ExportFile(name: "LICENSE", contents: licenseText()),
            ExportFile(name: "README.md", contents: readme(for: design, outputType: .swiftUI, aiCount: aiSwift == nil ? 0 : 1))
        ]
        return ExportPackage(packageName: packageName(for: design, suffix: "SwiftUI"), outputType: .swiftUI, files: files, beginnerGuide: guide(for: .swiftUI))
    }

    private enum CommentStyle { case js, css, html, swift }

    private func provenanceComment(forAI: Bool, style: CommentStyle) -> String {
        let source = forAI ? "AI provider output" : "InterfaceForge template fallback (AI output unavailable for this field)"
        let line = "InterfaceForge — source: \(source). Free to copy, modify, and ship."
        switch style {
        case .js, .swift: return "// \(line)\n\n"
        case .css: return "/* \(line) */\n\n"
        case .html: return "<!-- \(line) -->\n"
        }
    }

    private func tokensCSS(for design: GeneratedDesign) -> String {
        let colors = exportColors(for: design.configuration.theme)
        let radius = Int(design.configuration.visualStyle.cornerRadius)
        return """
        /* InterfaceForge design tokens — share these across components for visual continuity. */
        :root {
          --if-color-accent: \(colors.accent);
          --if-color-secondary: \(colors.secondary);
          --if-color-ink: #111827;
          --if-color-muted: #64748b;
          --if-color-surface: rgba(255, 255, 255, 0.88);
          --if-radius-card: \(radius)px;
          --if-radius-control: \(max(radius - 12, 12))px;
          --if-radius-pill: 999px;
          --if-space-1: 4px;
          --if-space-2: 8px;
          --if-space-3: 12px;
          --if-space-4: 18px;
          --if-space-5: 28px;
          --if-font-stack: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        """
    }

    private func themeSwift(for design: GeneratedDesign) -> String {
        let colors = exportColors(for: design.configuration.theme)
        let radius = Int(design.configuration.visualStyle.cornerRadius)
        return """
        import SwiftUI

        enum InterfaceForgeTheme {
            static let accent = Color(hex: "\(colors.accent)")
            static let secondary = Color(hex: "\(colors.secondary)")
            static let cardRadius: CGFloat = \(radius)
            static let controlRadius: CGFloat = \(max(radius - 12, 12))
        }

        extension Color {
            init(hex: String) {
                let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
                var int: UInt64 = 0
                Scanner(string: trimmed).scanHexInt64(&int)
                let r = Double((int >> 16) & 0xff) / 255
                let g = Double((int >> 8) & 0xff) / 255
                let b = Double(int & 0xff) / 255
                self.init(red: r, green: g, blue: b)
            }
        }
        """
    }

    private func packageJSON(for design: GeneratedDesign) -> String {
        let name = cssClassName(for: design)
        let safePrompt = design.prompt
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "'")
            .replacingOccurrences(of: "\n", with: " ")
        return """
        {
          "name": "interfaceforge-\(name)",
          "version": "0.1.0",
          "private": true,
          "description": "Component generated by InterfaceForge from: \(safePrompt)",
          "main": "Component.jsx",
          "peerDependencies": {
            "react": ">=18",
            "react-dom": ">=18"
          },
          "license": "MIT"
        }
        """
    }

    private func tailwindConfig(for design: GeneratedDesign) -> String {
        let colors = exportColors(for: design.configuration.theme)
        return """
        /** @type {import('tailwindcss').Config} */
        module.exports = {
          content: ['./*.html'],
          theme: {
            extend: {
              colors: {
                'if-accent': '\(colors.accent)',
                'if-secondary': '\(colors.secondary)'
              }
            }
          },
          plugins: []
        };
        """
    }

    private func licenseText() -> String {
        """
        MIT License

        Copyright (c) \(Calendar.current.component(.year, from: Date())) Generated by InterfaceForge

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
        """
    }

    private func cssClassName(for design: GeneratedDesign) -> String {
        let raw = design.template.id.isEmpty ? "generated-component" : design.template.id
        let safe = raw.lowercased().map { character in
            if character.isLetter || character.isNumber || character == "-" { return String(character) }
            return "-"
        }.joined()
        return safe.split(separator: "-").joined(separator: "-")
    }

    private func packageName(for design: GeneratedDesign, suffix: String) -> String {
        "InterfaceForge-\(cssClassName(for: design))-\(suffix)-Package"
    }

    private func reactComponent(for design: GeneratedDesign, className: String) -> String {
        let sections = normalizedSections(for: design)
        let metrics = design.metrics
        let fields = normalizedFields(for: design)
        return """
        import './styles.css';

        const sections = [
        \(sections.map { "  { title: \"\($0.title.jsEscaped)\", detail: \"\($0.detail.jsEscaped)\" }" }.joined(separator: ",\n"))
        ];

        const metrics = [
        \(metrics.map { "  { value: \"\($0.value.jsEscaped)\", label: \"\($0.label.jsEscaped)\", trend: \"\($0.trend.jsEscaped)\" }" }.joined(separator: ",\n"))
        ];

        const fields = [
        \(fields.map { "  { label: \"\($0.label.jsEscaped)\", placeholder: \"\($0.placeholder.jsEscaped)\", kind: \"\($0.kind.jsEscaped)\", required: \($0.required ? "true" : "false") }" }.joined(separator: ",\n"))
        ];

        export default function Component() {
          return (
            <section className="if-card \(className)" aria-labelledby="if-title">
              <p className="if-kicker">{"\(design.kicker.jsEscaped)"}</p>
              <h2 id="if-title">{"\(design.headline.jsEscaped)"}</h2>
              <p className="if-subheadline">{"\(design.subheadline.jsEscaped)"}</p>
              {metrics.length > 0 && (
                <div className="if-metrics" aria-label="Key stats">
                  {metrics.map((metric) => (
                    <div className="if-metric" key={metric.label}>
                      <strong>{metric.value}</strong>
                      <span>{metric.label}</span>
                      {metric.trend && <small>{metric.trend}</small>}
                    </div>
                  ))}
                </div>
              )}
              {fields.length > 0 && (
                <form className="if-form">
                  {fields.map((field) => (
                    <label key={field.label}>
                      {field.label}
                      {field.kind === 'textarea' ? <textarea placeholder={field.placeholder} required={field.required} /> : <input type={field.kind} placeholder={field.placeholder} required={field.required} />}
                    </label>
                  ))}
                </form>
              )}
              <div className="if-sections">
                {sections.map((section) => (
                  <article key={section.title}>
                    <span aria-hidden="true">✦</span>
                    <div>
                      <h3>{section.title}</h3>
                      <p>{section.detail}</p>
                    </div>
                  </article>
                ))}
              </div>
              <div className="if-actions">
                <button type="button">{"\(design.primaryAction.jsEscaped)"}</button>
                <a href="#details">{"\(design.secondaryAction.jsEscaped)"}</a>
              </div>
            </section>
          );
        }
        """
    }

    private func html(for design: GeneratedDesign, className: String) -> String {
        let sections = normalizedSections(for: design)
        let metrics = design.metrics
        let fields = normalizedFields(for: design)
        let metricHTML = metrics.isEmpty ? "" : """
              <div class="if-metrics" aria-label="Key stats">
        \(metrics.map { "        <div class=\"if-metric\"><strong>\($0.value.htmlEscaped)</strong><span>\($0.label.htmlEscaped)</span>\($0.trend.isEmpty ? "" : "<small>\($0.trend.htmlEscaped)</small>")</div>" }.joined(separator: "\n"))
              </div>
        """
        let fieldHTML = fields.isEmpty ? "" : """
              <form class="if-form">
        \(fields.map { field in
            let required = field.required ? " required" : ""
            if field.kind == "textarea" {
                return "        <label>\(field.label.htmlEscaped)<textarea placeholder=\"\(field.placeholder.attributeEscaped)\"\(required)></textarea></label>"
            }
            return "        <label>\(field.label.htmlEscaped)<input type=\"\(field.kind.attributeEscaped)\" placeholder=\"\(field.placeholder.attributeEscaped)\"\(required) /></label>"
        }.joined(separator: "\n"))
              </form>
        """
        return """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <title>\(design.headline.htmlEscaped)</title>
          <link rel="stylesheet" href="styles.css" />
        </head>
        <body>
          <main class="if-page">
            <section class="if-card \(className)" aria-labelledby="if-title">
              <p class="if-kicker">\(design.kicker.htmlEscaped)</p>
              <h1 id="if-title">\(design.headline.htmlEscaped)</h1>
              <p class="if-subheadline">\(design.subheadline.htmlEscaped)</p>
        \(metricHTML)
        \(fieldHTML)
              <div class="if-sections">
        \(sections.map { "        <article><span aria-hidden=\"true\">✦</span><div><h2>\($0.title.htmlEscaped)</h2><p>\($0.detail.htmlEscaped)</p></div></article>" }.joined(separator: "\n"))
              </div>
              <div class="if-actions">
                <button type="button">\(design.primaryAction.htmlEscaped)</button>
                <a href="#details">\(design.secondaryAction.htmlEscaped)</a>
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
          --if-card: rgba(255,255,255,.88);
        }

        * { box-sizing: border-box; }
        body { margin: 0; font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; background: #f7f9ff; color: var(--if-ink); }
        .if-page { min-height: 100vh; display: grid; place-items: center; padding: clamp(20px, 5vw, 48px); background: radial-gradient(circle at top left, \(colors.accent)33, transparent 34%), radial-gradient(circle at bottom right, \(colors.secondary)2e, transparent 30%); }
        .if-card { width: min(760px, 100%); padding: clamp(24px, 5vw, 40px); border-radius: \(Int(design.configuration.visualStyle.cornerRadius))px; background: var(--if-card); border: 1px solid rgba(255,255,255,.72); box-shadow: 0 24px 80px rgba(15, 23, 42, .16); backdrop-filter: blur(18px); }
        .if-kicker { margin: 0 0 10px; color: var(--if-accent); font-weight: 800; letter-spacing: .08em; text-transform: uppercase; font-size: 12px; }
        h1, h2 { margin: 0; font-size: clamp(32px, 7vw, 56px); line-height: .95; letter-spacing: -.05em; }
        h3 { margin: 0 0 4px; font-size: 16px; }
        p { color: var(--if-muted); line-height: 1.6; }
        .if-subheadline { font-size: 18px; max-width: 62ch; }
        .if-metrics { display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 12px; margin: 24px 0; }
        .if-metric { padding: 16px; border-radius: 20px; background: rgba(255,255,255,.7); border: 1px solid rgba(15,23,42,.08); }
        .if-metric strong { display: block; font-size: 28px; letter-spacing: -.04em; }
        .if-metric span, .if-metric small { display: block; color: var(--if-muted); }
        .if-metric small { color: #16a34a; font-weight: 800; margin-top: 4px; }
        .if-form { display: grid; gap: 12px; margin: 24px 0; }
        label { display: grid; gap: 8px; font-weight: 700; }
        input, textarea { width: 100%; border: 1px solid #dbe3ef; border-radius: 18px; padding: 14px 16px; font: inherit; background: white; }
        textarea { min-height: 94px; resize: vertical; }
        input:focus-visible, textarea:focus-visible, button:focus-visible, a:focus-visible { outline: 3px solid color-mix(in srgb, var(--if-accent) 45%, transparent); outline-offset: 3px; }
        .if-sections { display: grid; gap: 12px; margin: 24px 0; }
        .if-sections article { display: flex; gap: 12px; padding: 14px; border-radius: 18px; background: rgba(15, 23, 42, .045); }
        .if-sections article > span { width: 32px; height: 32px; flex: 0 0 auto; display: grid; place-items: center; color: white; border-radius: 999px; background: linear-gradient(135deg, var(--if-accent), var(--if-secondary)); }
        button, .if-actions a { min-height: 44px; border: 0; border-radius: 999px; padding: 0 18px; font-weight: 800; text-decoration: none; display: inline-flex; align-items: center; justify-content: center; }
        button { color: white; background: linear-gradient(135deg, var(--if-accent), var(--if-secondary)); box-shadow: 0 14px 30px \(colors.accent)44; }
        .if-actions { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; margin-top: 22px; }
        .if-actions a { color: var(--if-ink); background: rgba(15, 23, 42, .06); }
        @media (max-width: 560px) { .if-actions > * { width: 100%; } .if-sections article { align-items: flex-start; } }
        """
    }

    private func swiftUI(for design: GeneratedDesign) -> String {
        let sections = normalizedSections(for: design)
        let metrics = design.metrics
        let fields = normalizedFields(for: design)
        let sectionRows = sections.map { section in
            """
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(section.title.swiftEscaped)")
                                .font(.headline)
                            Text("\(section.detail.swiftEscaped)")
                                .foregroundStyle(.secondary)
                        }
                    }
            """
        }.joined(separator: "\n")
        let metricRows = metrics.map { metric in
            """
                        VStack(alignment: .leading) {
                            Text("\(metric.value.swiftEscaped)")
                                .font(.title2.weight(.black))
                            Text("\(metric.label.swiftEscaped)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            """
        }.joined(separator: "\n")
        let metricBlock = metricRows.isEmpty ? "" : """
                    HStack(spacing: 10) {
        \(metricRows)
                    }
        """
        let fieldRows = fields.map { field in
            """
                    TextField("\(field.placeholder.swiftEscaped)", text: .constant(""), axis: \(field.kind == "textarea" ? ".vertical" : ".horizontal"))
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel("\(field.label.swiftEscaped)")
            """
        }.joined(separator: "\n")
        return """
        import SwiftUI

        struct GeneratedComponent: View {
            var body: some View {
                VStack(alignment: .leading, spacing: 18) {
                    Text("\(design.kicker.swiftEscaped)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.blue)
                    Text("\(design.headline.swiftEscaped)")
                        .font(.largeTitle.weight(.black))
                    Text("\(design.subheadline.swiftEscaped)")
                        .foregroundStyle(.secondary)
        \(metricBlock)
        \(fieldRows)
        \(sectionRows)
                    HStack {
                        Button("\(design.primaryAction.swiftEscaped)") { }
                            .buttonStyle(.borderedProminent)
                        Button("\(design.secondaryAction.swiftEscaped)") { }
                            .buttonStyle(.bordered)
                    }
                }
                .padding(28)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: \(Int(design.configuration.visualStyle.cornerRadius)), style: .continuous))
                .padding()
            }
        }
        """
    }

    private func normalizedSections(for design: GeneratedDesign) -> [GeneratedSection] {
        if !design.sections.isEmpty { return design.sections }
        return [
            GeneratedSection(title: "Prompt-specific content", detail: "This area is derived from the generated design spec."),
            GeneratedSection(title: "Accessible structure", detail: "Labels, readable copy, and responsive layout are included."),
            GeneratedSection(title: "Beginner-ready export", detail: "Copy the files into your project and customize the text.")
        ]
    }

    private func normalizedFields(for design: GeneratedDesign) -> [GeneratedFormField] {
        design.formFields.map { field in
            let allowed = ["text", "email", "number", "tel", "url", "textarea"]
            let kind = allowed.contains(field.kind.lowercased()) ? field.kind.lowercased() : "text"
            return GeneratedFormField(label: field.label, placeholder: field.placeholder, kind: kind, required: field.required)
        }
    }

    private func readme(for design: GeneratedDesign, outputType: OutputType, aiCount: Int) -> String {
        let mode = design.generationMode == .ai ? "AI-powered" : "template fallback"
        let provenance: String
        switch design.generationMode {
        case .ai where aiCount > 0:
            provenance = "Source mix: \(aiCount) file(s) returned by the AI provider, the rest scaffolded from the structured spec."
        case .ai:
            provenance = "Source mix: the AI provider returned the spec but no inline code, so files were scaffolded from the structured fields."
        case .fallback:
            provenance = "Source mix: template fallback — no AI output was used. Add or fix your API key in the AI engine card to generate unique code."
        }
        switch outputType {
        case .react:
            return """
            # InterfaceForge React package

            This package contains one \(mode) component for: \(design.prompt)

            \(provenance)

            ## Files
            - `Component.jsx` — the React component.
            - `styles.css` — component styles.
            - `tokens.css` — shared design tokens (colors, radii, spacing) so multiple components stay visually consistent.
            - `package.json` — minimal manifest so you can drop the folder into a workspace or publish it.
            - `LICENSE` — MIT, free to use.

            ## How to use it
            1. Copy this folder into your React app, for example `src/components/GeneratedComponent/`.
            2. Import the tokens once in your app entry: `import './components/GeneratedComponent/tokens.css';`.
            3. Import the component with `import Component from './components/GeneratedComponent/Component';`.
            4. Add `<Component />` anywhere in your page.
            5. Deploy your site the way you normally do.
            """
        case .html:
            return """
            # InterfaceForge HTML package

            This package contains one \(mode) web component for: \(design.prompt)

            \(provenance)

            ## Files
            - `index.html` — open in a browser to preview.
            - `styles.css` — component styles (consumes `tokens.css`).
            - `tokens.css` — shared design tokens for visual continuity across pages.
            - `LICENSE` — MIT, free to use.

            ## How to use it
            1. Keep all three files in the same folder.
            2. Open `index.html` in a browser to preview it.
            3. Upload the folder to your website host.
            4. To embed in an existing page, copy the `<section>` from `index.html`, link both stylesheets, and you're done.
            """
        case .tailwind:
            return """
            # InterfaceForge Tailwind CSS package

            This package contains one \(mode) web component for: \(design.prompt)

            \(provenance)

            ## Files
            - `index.html` — uses the Tailwind CDN, so no build step is required.
            - `tailwind.config.js` — drop into a real Tailwind project to keep the same accent colors when you compile your own CSS.
            - `LICENSE` — MIT, free to use.

            ## How to use it
            1. Open `index.html` in a browser to preview it.
            2. Upload `index.html` to your website host.
            3. For a build-step Tailwind project, copy the colors from `tailwind.config.js` into your config to keep the brand consistent.
            """
        case .swiftUI:
            return """
            # InterfaceForge SwiftUI package

            This package contains one \(mode) SwiftUI view for: \(design.prompt)

            \(provenance)

            ## Files
            - `GeneratedComponent.swift` — the SwiftUI view.
            - `Theme.swift` — shared accent colors and radii so multiple generated components stay visually consistent.
            - `LICENSE` — MIT, free to use.

            ## How to use it
            1. Drag both Swift files into your Xcode project.
            2. Add `GeneratedComponent()` inside any SwiftUI screen.
            3. Use `InterfaceForgeTheme.accent` in your own views to match the look.
            4. Run your app.
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
            6. Deploy your site normally. The exported code does not need InterfaceForge to run.
            """
        case .html:
            return """
            1. Save the shared package.
            2. Open index.html to check the design.
            3. Upload index.html and styles.css to your website host.
            4. If you already have a page, copy the section code into that page and copy the CSS into your stylesheet.
            """
        case .tailwind:
            return """
            1. Save the package.
            2. Open index.html to check the design.
            3. Upload index.html to your website host.
            4. Tailwind loads from CDN, so no build tools or CSS files are needed.
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

private extension Optional where Wrapped == String {
    var cleanedCode: String? {
        guard var value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        if value.hasPrefix("```") {
            ["```jsx", "```javascript", "```html", "```css", "```swift", "```"].forEach { marker in
                value = value.replacingOccurrences(of: marker, with: "")
            }
        }
        let cleaned = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}

private extension String {
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    var attributeEscaped: String {
        htmlEscaped.replacingOccurrences(of: "\"", with: "&quot;")
    }

    var jsEscaped: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    var swiftEscaped: String {
        replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
