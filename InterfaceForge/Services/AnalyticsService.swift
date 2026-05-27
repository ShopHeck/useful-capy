import Foundation
import MetricKit
import os.log

// MARK: - Analytics Events

/// Lightweight, privacy-first analytics using Apple's MetricKit for crash/performance
/// diagnostics and structured os.log for custom event telemetry.
/// Zero third-party dependencies. No PII collected. No network calls.
///
/// Custom events are emitted as signposts visible in Instruments and the
/// on-device console. MetricKit payloads are delivered by iOS every ~24h and
/// include hang rate, launch time, disk writes, and crash diagnostics — all
/// aggregated and anonymised by the OS before delivery.

@MainActor
final class AnalyticsService: NSObject, ObservableObject {

    static let shared = AnalyticsService()

    // MARK: - MetricKit

    private let metricManager = MXMetricManager.shared
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.capy.interfaceforge",
                                category: "Analytics")

    // MARK: - Signpost subsystem for Instruments

    private static let signpostLog = OSLog(
        subsystem: Bundle.main.bundleIdentifier ?? "com.capy.interfaceforge",
        category: .pointsOfInterest
    )

    // MARK: - Lifecycle

    private override init() {
        super.init()
        metricManager.add(self)
        logger.info("AnalyticsService initialised — MetricKit subscriber registered.")
    }

    deinit {
        metricManager.remove(self)
    }

    // MARK: - Custom Event Tracking

    /// Track a named event with optional metadata.
    /// Events are logged to the unified logging system (Console.app / Instruments)
    /// and counted locally for lightweight in-app analytics.
    func track(_ event: AnalyticsEvent, properties: [String: String] = [:]) {
        let propsString = properties.isEmpty ? "" : " | \(properties.map { "\($0.key)=\($0.value)" }.joined(separator: ", "))"
        logger.info("📊 \(event.rawValue)\(propsString)")

        // Emit a signpost so the event shows up in Instruments traces
        os_signpost(.event, log: Self.signpostLog, name: "AppEvent", "%{public}s", event.rawValue)

        // Increment local counter
        incrementCounter(for: event)
    }

    // MARK: - Local Counters (UserDefaults)

    private let counterPrefix = "interfaceforge.analytics.count."

    func count(for event: AnalyticsEvent) -> Int {
        UserDefaults.standard.integer(forKey: counterPrefix + event.rawValue)
    }

    private func incrementCounter(for event: AnalyticsEvent) {
        let key = counterPrefix + event.rawValue
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
    }

    // MARK: - Diagnostic summary (for settings/debug screen)

    /// Returns a human-readable summary of key metrics for a potential debug screen.
    var diagnosticSummary: String {
        let generations = count(for: .generate)
        let refinements = count(for: .refine)
        let exports = count(for: .export)
        let screenshots = count(for: .screenshotImport)
        return """
        Generations: \(generations)
        Refinements: \(refinements)
        Exports: \(exports)
        Screenshot imports: \(screenshots)
        """
    }
}

// MARK: - MXMetricManagerSubscriber

extension AnalyticsService: MXMetricManagerSubscriber {

    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        // MetricKit delivers aggregated performance metrics every ~24h.
        // Log them so they appear in the console for debugging; in a future
        // release these could be forwarded to a lightweight backend.
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.capy.interfaceforge",
                            category: "MetricKit")
        for payload in payloads {
            if let launchTime = payload.applicationLaunchMetrics?.histogrammedTimeToFirstDraw
                .bucketEnumerator.allObjects.first {
                logger.info("MetricKit: launch payload received — firstDraw bucket: \(String(describing: launchTime))")
            }
            logger.info("MetricKit: metric payload received for \(payload.timeStampBegin) – \(payload.timeStampEnd)")
        }
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        // Crash and hang diagnostics — logged for console debugging.
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.capy.interfaceforge",
                            category: "MetricKit")
        for payload in payloads {
            if let crashDiagnostics = payload.crashDiagnostics {
                logger.error("MetricKit: \(crashDiagnostics.count) crash diagnostic(s) received.")
            }
            if let hangDiagnostics = payload.hangDiagnostics {
                logger.warning("MetricKit: \(hangDiagnostics.count) hang diagnostic(s) received.")
            }
        }
    }
}

// MARK: - Event Catalog

enum AnalyticsEvent: String {
    // Onboarding
    case onboardingComplete     = "onboarding_complete"

    // Generation
    case generate               = "generate"
    case generateFallback       = "generate_fallback"
    case generateAI             = "generate_ai"
    case refine                 = "refine"
    case cancelGeneration       = "cancel_generation"

    // Export
    case export                 = "export"
    case exportReact            = "export_react"
    case exportHTML             = "export_html"
    case exportTailwind         = "export_tailwind"
    case exportSwiftUI          = "export_swiftui"

    // Features
    case screenshotImport       = "screenshot_import"
    case templateSelect         = "template_select"
    case quickStartTap          = "quick_start_tap"
    case galleryView            = "gallery_view"
    case galleryFork            = "gallery_fork"
    case galleryShare           = "gallery_share"
    case webPreviewOpen         = "web_preview_open"

    // Subscription
    case paywallView            = "paywall_view"
    case purchaseStart          = "purchase_start"
    case purchaseComplete       = "purchase_complete"
    case purchaseCancel         = "purchase_cancel"
    case restorePurchases       = "restore_purchases"

    // Settings
    case apiKeySet              = "api_key_set"
    case connectionTest         = "connection_test"
}
