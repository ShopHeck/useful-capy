# InterfaceForge App Store Assets

Store generated App Store Connect deliverables here. Keep final screenshot PNGs, source mockups, export notes, and the final app icon asset in this directory so release materials stay separate from app source code.

## Required screenshot dimensions to generate

InterfaceForge is a universal iOS app, so prepare screenshots for iPhone and iPad placements:

- iPhone 6.9-inch portrait: 1320×2868 PNG
- iPhone 6.5-inch portrait: 1242×2688 PNG
- iPad Pro 13-inch portrait: 2048×2732 PNG

App Store Connect may allow using the largest required sizes to scale smaller device classes, but keep these source dimensions available for review and future updates.

## App icon

- App icon: 1024×1024 PNG, no transparency, production artwork only
- Add the final bitmap to `InterfaceForge/Assets.xcassets/AppIcon.appiconset/` and update that appiconset `Contents.json` with the filename when artwork is ready.
- Do not submit placeholder artwork or transparent icons.

## Recommended screenshot sequence

1. Home — show the AI interface generation value proposition and bring-your-provider-key positioning.
2. Create / AI Engine — show prompt entry, provider settings, and clear fallback disclosure.
3. AI Preview — show prompt-specific generated content with AI-powered or template-fallback status visible.
4. Export — show package contents, copy/share actions, and beginner handoff guide.

Use conservative copy: user-provided OpenAI-compatible provider, remote prompt requests, labeled fallback templates, and starter code exports rather than production guarantees.
