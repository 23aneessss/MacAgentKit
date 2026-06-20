import ApplicationServices
import CoreGraphics
import CoreServices
import Foundation
import IOKit.hid
import AppKit
import os

private let log = Logger(subsystem: "com.macagentkit", category: "permissions")

/// Detect, request, and deep-link the macOS privacy permissions an
/// automation/agent app needs.
///
/// ## The signing caveat (read this)
/// macOS ties an Accessibility/Automation grant to your app's **code
/// signature**. Ad-hoc rebuilds from `swift build` change the signature, so
/// macOS silently revokes the grant and your AX calls start returning `nil`
/// again. During development, sign with a **stable identity** (a real Developer
/// ID or a self-signed cert reused across builds) so the grant sticks.
///
/// ## Host-app requirements you can't set from a library
/// - **Automation:** the *host app* must declare
///   `com.apple.security.automation.apple-events` in its entitlements and
///   `NSAppleEventsUsageDescription` in its `Info.plist`. This package can probe
///   status but cannot grant these to your app.
/// - **Accessibility:** add a usage string and request at runtime; the user must
///   toggle your app on in System Settings.
public enum Permissions {

    // MARK: - Status

    /// Returns the current status of a permission without prompting.
    public static func status(_ permission: Permission) -> PermissionStatus {
        switch permission {
        case .accessibility:
            // AXIsProcessTrusted can't distinguish denied from not-yet-asked.
            return AXIsProcessTrusted() ? .granted : .denied

        case .screenRecording:
            return CGPreflightScreenCaptureAccess() ? .granted : .denied

        case .inputMonitoring:
            switch IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) {
            case kIOHIDAccessTypeGranted: return .granted
            case kIOHIDAccessTypeDenied: return .denied
            default: return .notDetermined
            }

        case .automation(let bundleID):
            return automationStatus(bundleID: bundleID, askIfNeeded: false)
        }
    }

    // MARK: - Request

    /// Requests a permission, prompting the user if appropriate, and returns the
    /// resulting status.
    ///
    /// For ``Permission/accessibility`` the system prompt only opens System
    /// Settings; the grant happens out-of-process, so this polls (until granted,
    /// the `accessibilityPollTimeout`, or task cancellation).
    @discardableResult
    public static func request(_ permission: Permission) async -> PermissionStatus {
        switch permission {
        case .accessibility:
            // Prompt (no-op if already trusted), then poll for the out-of-process grant.
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            if AXIsProcessTrustedWithOptions(options) { return .granted }
            return await pollAccessibility()

        case .screenRecording:
            return CGRequestScreenCaptureAccess() ? .granted : .denied

        case .inputMonitoring:
            return IOHIDRequestAccess(kIOHIDRequestTypeListenEvent) ? .granted : .denied

        case .automation(let bundleID):
            // AEDeterminePermissionToAutomateTarget blocks while prompting.
            return await withCheckedContinuation { continuation in
                DispatchQueue.global(qos: .userInitiated).async {
                    continuation.resume(returning: automationStatus(bundleID: bundleID, askIfNeeded: true))
                }
            }
        }
    }

    /// Requests the permission if not already granted and reports whether it is
    /// granted afterwards. Never throws.
    @discardableResult
    public static func ensure(_ permission: Permission) async -> Bool {
        if status(permission) == .granted { return true }
        return await request(permission) == .granted
    }

    // MARK: - Deep links

    /// How long ``request(_:)`` polls for an Accessibility grant before giving up.
    public static let accessibilityPollTimeout: TimeInterval = 120

    /// Opens the System Settings pane for a permission.
    public static func openSettings(for permission: Permission) {
        let anchor: String
        switch permission {
        case .accessibility: anchor = "Privacy_Accessibility"
        case .automation: anchor = "Privacy_Automation"
        case .screenRecording: anchor = "Privacy_ScreenCapture"
        case .inputMonitoring: anchor = "Privacy_ListenEvent"
        }
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else {
            log.error("Failed to build settings URL for \(permission.displayName, privacy: .public)")
            return
        }
        DispatchQueue.main.async {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Internals

    private static func pollAccessibility() async -> PermissionStatus {
        let deadline = Date().addingTimeInterval(accessibilityPollTimeout)
        while Date() < deadline {
            if AXIsProcessTrusted() { return .granted }
            if Task.isCancelled { break }
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                break
            }
        }
        return AXIsProcessTrusted() ? .granted : .denied
    }

    private static func automationStatus(bundleID: String, askIfNeeded: Bool) -> PermissionStatus {
        let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
        guard let desc = target.aeDesc else { return .notDetermined }
        let status = AEDeterminePermissionToAutomateTarget(
            desc,
            AEEventClass(typeWildCard),
            AEEventID(typeWildCard),
            askIfNeeded
        )
        switch status {
        case 0: return .granted                 // noErr
        case -1744: return .notDetermined       // errAEEventWouldRequireUserConsent
        case -600: return .notDetermined        // procNotFound — target app isn't running
        default: return .denied                 // -1743 errAEEventNotPermitted, etc.
        }
    }
}
