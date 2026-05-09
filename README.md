# InterfaceForge

InterfaceForge is a native SwiftUI iOS MVP for generating polished, interactive interface components and exporting beginner-friendly code packages. The app is designed around a simple flow: **Describe → Generate → Customize → Preview → Export**.

The MVP runs fully on-device with deterministic local templates. There are no accounts, API keys, backend services, or remote generation calls.

## Key MVP features

- Production-style SwiftUI app shell named **InterfaceForge**.
- Beginner-friendly home screen that explains the one-tap promise in plain English.
- Prompt composer with quick-start examples:
  - SaaS pricing card
  - AI dashboard widget
  - Mobile onboarding hero
  - Checkout form
  - Portfolio project card
- Style controls for color theme, visual style, motion level, and target output format.
- Local generation experience with animated progress messages that make the deterministic template flow feel polished.
- Interactive SwiftUI previews for multiple component types:
  - Pricing card with billing toggle and CTA state.
  - Dashboard widget with tappable metric tabs and animated values.
  - Onboarding hero with swipeable feature cards.
  - Checkout/contact form with validation-like feedback.
  - Portfolio card with save state and proof-point stats.
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
  Services/                      Local design generation and code export services
  ViewModels/                    Generator state and flow coordination
  Views/
    Home/                        Landing and navigation shell
    Generator/                   Prompt composer, style controls, generation progress
    Preview/                     Interactive preview routing
    Components/                  Rendered component previews
    Export/                      Code package export and beginner guide UI
    Shared/                      Reusable cards, buttons, chips, layout, and background views
```

## Open and run in Xcode

1. Open `InterfaceForge.xcodeproj` in Xcode.
2. Select the `InterfaceForge` scheme.
3. Choose an iPhone simulator or a connected iPhone.
4. Press Run.

The project targets iOS 17 and uses SwiftUI only. Xcode generates the app Info.plist and launch screen metadata from build settings.

## How export packages work

When a user exports, `CodeExportService` builds a small package from the generated design and selected output type.

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

- Generation is deterministic and local. It matches prompts to built-in templates instead of calling an AI model.
- Exported code is intentionally compact and beginner-friendly rather than production-framework exhaustive.
- Shared packages are folder-based temporary exports, not zipped archives in this initial MVP.
- No backend sync, accounts, cloud storage, billing, or analytics are included.
