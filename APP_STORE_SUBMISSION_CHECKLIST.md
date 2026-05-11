# InterfaceForge App Store Submission Checklist

Use this checklist to prepare, test, submit, and release the current AI-enabled SwiftUI app.

## 1. Apple account and app record

- [ ] Enroll in the Apple Developer Program at <https://developer.apple.com/programs/>.
- [ ] In Certificates, Identifiers & Profiles, create an explicit Bundle ID for InterfaceForge, such as `com.yourcompany.InterfaceForge`.
- [ ] In App Store Connect, create a new iOS app record.
- [ ] Set the app name to **InterfaceForge** or another available final name.
- [ ] Create a SKU, such as `interfaceforge-ios-001`.
- [ ] Choose a primary category that fits the app, likely **Developer Tools**, **Productivity**, or **Graphics & Design**.
- [ ] Complete the age rating questionnaire. The app sends user prompts to a user-configured AI provider but has no public sharing network, accounts, payments, or mature-content feed.
- [ ] Set pricing and availability. Use free unless monetization is actually implemented.

## 2. App assets and metadata

- [ ] Create a production app icon in all required iOS sizes through an Xcode app icon asset catalog.
- [ ] Keep the launch screen simple and consistent with the app name/brand. The project may use generated launch screen settings, so do not add an Info.plist unless the build requires it.
- [ ] Capture App Store screenshots for required device sizes. Show the flow: Home, Describe/Generate, AI engine settings, Customize, Preview, and Export.
- [ ] Use accurate screenshot copy, such as “bring your own API key,” “OpenAI-compatible provider,” “prompt-specific previews,” “fallback templates,” and “beginner-ready exports.”
- [ ] Do not imply InterfaceForge supplies free AI credits, stores keys in a hosted backend, or guarantees production-complete code.
- [ ] Optional: create an app preview video showing Describe → Configure AI → Generate → Customize → Preview → Export.
- [ ] Write subtitle, promotional text, description, and keywords that match the implemented AI/provider/fallback feature set.
- [ ] Add review-safe support copy explaining that generated code is starter code intended for learning and handoff.

## 3. Privacy, legal, and support

- [ ] Provide a public support URL.
- [ ] Provide a public privacy policy URL.
- [ ] Complete the Privacy Nutrition Label in App Store Connect based on the final release behavior.
- [ ] Disclose that user prompts, style settings, selected template hints, endpoint/model settings, and generated content may be sent to the user-configured AI provider during generation.
- [ ] Disclose that the user-provided API key is stored on-device with app storage for the MVP and is used to authorize remote AI calls.
- [ ] Review whether App Store privacy labels need data categories such as User Content or Other Data depending on the privacy policy and provider behavior.
- [ ] Do not claim **Data Not Collected** unless the final privacy analysis supports the remote AI flow and any provider processing is accurately represented.
- [ ] Update the privacy label and privacy policy before submission if analytics, crash reporting tied to identifiers, accounts, payments, cloud sync, telemetry, or a hosted AI proxy are added.
- [ ] Terms of service are recommended if you introduce subscriptions, purchases, user accounts, hosted services, or licensing restrictions.

## 4. Xcode project readiness

- [ ] Open `InterfaceForge.xcodeproj` in Xcode.
- [ ] Confirm the deployment target remains iOS 17 or the intended target.
- [ ] Set the Bundle Identifier to the App Store Connect Bundle ID.
- [ ] Configure Signing & Capabilities with the correct Apple Developer team.
- [ ] Add only capabilities the app actually uses. The app uses outbound network access through `URLSession`; it does not require iCloud, Sign in with Apple, Push Notifications, In-App Purchase, or Associated Domains unless those features are added.
- [ ] Set a marketing version, such as `1.0.0`.
- [ ] Increment the build number for every upload.
- [ ] Confirm the app name shown under the icon is final and not misleading.
- [ ] Run on at least one simulator and one physical device if available.

## 5. Functional QA before upload

- [ ] Verify Home explains the AI workflow, user-provided provider, and fallback templates accurately.
- [ ] Verify empty prompt generation is disabled unless a template is selected.
- [ ] Verify AI engine settings can store API key, endpoint, and model.
- [ ] Verify a valid API key/model/endpoint can generate a prompt-specific design for an arbitrary prompt such as “a landing-page hero for a space tourism startup with waitlist signup and safety stats.”
- [ ] Verify missing or invalid API key shows fallback/unavailable status and does not label the output as AI-powered.
- [ ] Verify every quick-start prompt still generates a preview and export package.
- [ ] Verify customization controls update the preview and rebuild the export package.
- [ ] Verify React + CSS, HTML + CSS, and SwiftUI export formats generate the correct file set.
- [ ] Verify AI-provided code fields are preferred when present and derived exports are usable when code fields are absent.
- [ ] Verify Copy uses the clipboard and includes all generated file contents.
- [ ] Verify Share opens the share sheet when the temporary export folder exists.
- [ ] Verify Dynamic Type, Dark Mode, and VoiceOver labels for core actions.
- [ ] Verify there are no broken links, placeholder metadata, debug menus, or test-only strings.

## 6. Archive and upload

- [ ] Select a generic iOS device or “Any iOS Device” destination in Xcode.
- [ ] Choose Product → Archive.
- [ ] In Xcode Organizer, validate the archive.
- [ ] Upload the archive to App Store Connect.
- [ ] Wait for processing to finish and resolve any warnings or errors.

## 7. TestFlight

- [ ] Add the processed build to internal TestFlight testing.
- [ ] Test the full Describe → Configure AI → Generate → Customize → Preview → Export flow on device.
- [ ] Test fallback generation with no API key and with an intentionally invalid key.
- [ ] Add external testers if useful, then complete Beta App Review if required.
- [ ] Provide tester notes that users need their own OpenAI-compatible API key for AI generation and can still see labeled fallback templates without one.

## 8. App Review notes and risk checks

- [ ] In Review Notes, state that InterfaceForge is a SwiftUI app that sends prompts to a user-configured OpenAI-compatible chat completions endpoint when an API key is entered.
- [ ] Explain where the API key is entered, that the default endpoint is `https://api.openai.com/v1/chat/completions`, and that the default model string is `gpt-4.1-mini`.
- [ ] State that if no key is entered or the provider request fails, the app produces a clearly labeled template fallback.
- [ ] Include concise demo instructions: launch app, tap Create an interface, enter provider settings or skip to see fallback, choose a quick start or template, generate, preview, then export.
- [ ] Ensure exported-code claims are accurate: beginner-friendly starter packages, not guaranteed production-complete apps.
- [ ] Do not mention subscriptions, trials, payments, cloud storage, collaboration, hosted AI credits, or accounts unless those features are implemented and reviewable.
- [ ] Avoid third-party trademarks in templates, screenshots, prompts, or sample exports unless you have permission or the usage is clearly nominative and compliant.
- [ ] Ensure any sample “AI dashboard” wording is either a prompt/example or backed by the implemented AI generation engine.

## 9. Submit and release

- [ ] Complete all App Store Connect metadata, screenshots, privacy, pricing, and build selection.
- [ ] Submit for review.
- [ ] If Apple asks questions, answer directly and explain the user-configured remote AI generation path plus labeled fallback behavior.
- [ ] If rejected, fix the issue, increment the build number, archive, upload, and resubmit.
- [ ] Choose automatic release or manual release after approval.
- [ ] After release, monitor App Store Connect for crashes, reviews, ratings, and user feedback.
- [ ] Update the checklist, privacy policy, and review notes whenever app capabilities change.
