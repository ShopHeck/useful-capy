# InterfaceForge App Store Submission Checklist

Use this checklist to prepare, test, submit, and release the current local-only SwiftUI app.

## 1. Apple account and app record

- [ ] Enroll in the Apple Developer Program at <https://developer.apple.com/programs/>.
- [ ] In Certificates, Identifiers & Profiles, create an explicit Bundle ID for InterfaceForge, such as `com.yourcompany.InterfaceForge`.
- [ ] In App Store Connect, create a new iOS app record.
- [ ] Set the app name to **InterfaceForge** or another available final name.
- [ ] Create a SKU, such as `interfaceforge-ios-001`.
- [ ] Choose a primary category that fits the app, likely **Developer Tools**, **Productivity**, or **Graphics & Design**.
- [ ] Complete the age rating questionnaire. The current app should likely qualify for a low age rating because it has no user-generated sharing network, accounts, web access, or mature content.
- [ ] Set pricing and availability. Use free unless monetization is actually implemented.

## 2. App assets and metadata

- [ ] Create a production app icon in all required iOS sizes through an Xcode app icon asset catalog.
- [ ] Keep the launch screen simple and consistent with the app name/brand. The project may use generated launch screen settings, so do not add an Info.plist unless the build requires it.
- [ ] Capture App Store screenshots for required device sizes. Show the flow: Home, Describe/Generate, Customize, Preview, and Export.
- [ ] Use accurate screenshot copy, such as “local templates,” “no API keys,” and “beginner-ready exports.” Do not imply remote AI generation, accounts, cloud sync, or subscriptions unless those features exist.
- [ ] Optional: create an app preview video showing Describe → Generate → Customize → Preview → Export.
- [ ] Write subtitle, promotional text, description, and keywords that match the current feature set.
- [ ] Add review-safe support copy explaining that generated code is starter code intended for learning and handoff.

## 3. Privacy, legal, and support

- [ ] Provide a public support URL.
- [ ] Provide a public privacy policy URL. Even local-only apps should have a short policy.
- [ ] Complete the Privacy Nutrition Label in App Store Connect.
- [ ] For the current implementation, the likely posture is **Data Not Collected**: no accounts, backend, analytics, tracking, payments, or remote generation calls.
- [ ] Update the privacy label and privacy policy before submission if analytics, crash reporting tied to identifiers, accounts, payments, cloud sync, network AI generation, or telemetry are added.
- [ ] Terms of service are optional for this MVP, but add terms if you introduce subscriptions, purchases, user accounts, hosted services, or licensing restrictions.

## 4. Xcode project readiness

- [ ] Open `InterfaceForge.xcodeproj` in Xcode.
- [ ] Confirm the deployment target remains iOS 17 or the intended target.
- [ ] Set the Bundle Identifier to the App Store Connect Bundle ID.
- [ ] Configure Signing & Capabilities with the correct Apple Developer team.
- [ ] Add only capabilities the app actually uses. The current app should not need network, iCloud, Sign in with Apple, Push Notifications, In-App Purchase, or Associated Domains.
- [ ] Set a marketing version, such as `1.0.0`.
- [ ] Increment the build number for every upload.
- [ ] Confirm the app name shown under the icon is final and not misleading.
- [ ] Run on at least one simulator and one physical device if available.

## 5. Functional QA before upload

- [ ] Verify Home explains the local-only workflow clearly.
- [ ] Verify empty prompt generation is disabled unless a template is selected.
- [ ] Verify every quick-start prompt generates the expected template.
- [ ] Verify customization controls update the preview.
- [ ] Verify React + CSS, HTML + CSS, and SwiftUI export formats generate the correct file set.
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
- [ ] Test the full Describe → Generate → Customize → Preview → Export flow on device.
- [ ] Add external testers if useful, then complete Beta App Review if required.
- [ ] Provide tester notes that the app runs locally and does not require login, API keys, or demo credentials.

## 8. App Review notes and risk checks

- [ ] In Review Notes, state that InterfaceForge is a local SwiftUI app with deterministic built-in templates and no login required.
- [ ] Include concise demo instructions: launch app, tap Create an interface, choose a quick start or template, generate, preview, then export.
- [ ] Do not claim remote AI, autonomous design intelligence, or backend-powered generation unless implemented.
- [ ] Ensure exported-code claims are accurate: beginner-friendly starter packages, not guaranteed production-complete apps.
- [ ] Do not mention subscriptions, trials, payments, cloud storage, collaboration, or accounts unless those features are implemented and reviewable.
- [ ] Avoid third-party trademarks in templates, screenshots, prompts, or sample exports unless you have permission or the usage is clearly nominative and compliant.
- [ ] Ensure any sample “AI dashboard” wording is presented as a template/example, not a claim that the app calls an AI service.

## 9. Submit and release

- [ ] Complete all App Store Connect metadata, screenshots, privacy, pricing, and build selection.
- [ ] Submit for review.
- [ ] If Apple asks questions, answer directly and explain the local-only deterministic generation model.
- [ ] If rejected, fix the issue, increment the build number, archive, upload, and resubmit.
- [ ] Choose automatic release or manual release after approval.
- [ ] After release, monitor App Store Connect for crashes, reviews, ratings, and user feedback.
- [ ] Update the checklist, privacy policy, and review notes whenever app capabilities change.
