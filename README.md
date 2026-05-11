# InterfaceForge

InterfaceForge is a native SwiftUI iOS MVP for generating polished, interactive interface components and exporting beginner-friendly code packages. The app is designed around a simple flow: **Describe → Generate → Customize → Preview → Export**.

The MVP now includes an AI-powered generation path. Users provide their own OpenAI-compatible chat completions API key, endpoint, and model in the composer; prompts and style settings are sent to that configured provider to produce structured JSON, preview content, and export code. If the key is missing or the provider request fails, InterfaceForge clearly labels the result as a template fallback instead of presenting it as AI output.

## Key MVP features

- Production-style SwiftUI app shell named **InterfaceForge**.
- Beginner-friendly home screen that explains the AI engine, user-provided API key, and fallback behavior in plain English.
- Prompt composer with quick-start examples:
  - SaaS pricing card
  - AI dashboard widget
  - Mobile onboarding hero
  - Checkout form
  - Portfolio project card
- AI engine settings for API key, OpenAI-compatible chat completions endpoint, and model string.
- Style controls for color theme, visual style, motion level, and target output format.
- AI generation experience with progress messages for provider analysis, JSON validation, preview assembly, and export packaging.
- Template fallback path when AI is unavailable, with visible fallback status/error messaging.
- Interactive SwiftUI previews for multiple built-in component types plus a generic adaptive AI preview for prompt-specific designs:
  - Pricing card with billing toggle and CTA state.
  - Dashboard widget with tappable metric tabs and animated values.
  - Onboarding hero with swipeable feature cards.
  - Checkout/contact form with validation-like feedback.
  - Portfolio card with save state and proof-point stats.
  - AI-generated adaptive preview using structured kicker, headline, actions, sections, metrics, and form fields.
- Export packages for:
  - React + CSS
  - HTML + CSS
  - SwiftUI bonus output
- Export screen with `Copy code`, `Share package`, visible file previews, and a plain-English beginner install guide.

## Project structure

```text
InterfaceForge.xcodeproj/        Xcode project metadata
InterfaceForge/
  App/                           SwiftUI app entry point
  Models/                        Template, style, generated design, and export package models
  Services/                      AI/fallback design generation and code export services
  ViewModels/                    Generator state, AI settings, and flow coordination
  Views/
    Home/                        Landing and navigation shell
    Generator/                   Prompt composer, AI settings, style controls, generation progress
    Preview/                     Interactive preview routing and adaptive AI preview
    Components/                  Rendered component previews
    Export/                      Code package export and beginner guide UI
    Shared/                      Reusable cards, buttons, chips, layout, and background views
```

## Open and run in Xcode

1. Open `InterfaceForge.xcodeproj` in Xcode.
2. Select the `InterfaceForge` scheme.
3. Choose an iPhone simulator or a connected iPhone.
4. Press Run.

The project targets iOS 17 and uses SwiftUI/Foundation only. Xcode generates the app Info.plist and launch screen metadata from build settings.

For App Store release prep, follow the tailored checklist in [`APP_STORE_SUBMISSION_CHECKLIST.md`](APP_STORE_SUBMISSION_CHECKLIST.md).

## AI generation settings

The composer includes an **AI engine** card with:

- API key, stored on-device with `@AppStorage` for the MVP.
- Endpoint, defaulting to `https://api.openai.com/v1/chat/completions`.
- Model, defaulting to `gpt-4.1-mini`.

Generation uses an OpenAI-compatible chat completions request through `URLSession`. The model is instructed to return strict JSON for a responsive, accessible, no-dependency UI component. The app validates the JSON, renders a preview from the structured fields, and prefers AI-provided React, HTML, CSS, and SwiftUI code when available. Users should understand that their prompts and style settings are sent to the configured provider and governed by that provider's privacy and billing terms.

## How export packages work

When a user exports, `CodeExportService` builds a small package from the generated design and selected output type. It prefers AI-provided `reactCode`, `htmlCode`, `cssCode`, and `swiftUICode` fields when present; otherwise it derives prompt-specific starter files from the structured design fields.

For **React + CSS**, the package contains:

- `Component.jsx`
- `styles.css`
- `README.md`

For **HTML + CSS**, the package contains:

- `index.html`
- `styles.css`
- `README.md`

For **SwiftUI**, the package contains:

- `GeneratedComponent.swift`
- `README.md`

The export UI also writes these files to a temporary package folder for sharing and shows the same files in-app so a beginner can inspect or copy them. The included README explains where to place the files, how to import or paste the component, and how to upload or deploy in simple language.

## Current limitations

- Users must bring their own API key/provider credentials; no backend proxy, account system, billing, or hosted key management is included.
- API keys are stored with `@AppStorage` for the MVP, not Keychain.
- Remote AI calls may fail because of invalid keys, endpoint/model incompatibility, quota, provider downtime, or malformed JSON; these cases return a visible template fallback.
- Exported code is intentionally compact and beginner-friendly rather than production-framework exhaustive.
- Shared packages are folder-based temporary exports, not zipped archives in this initial MVP.
- No backend sync, accounts, cloud storage, billing, or analytics are included.
