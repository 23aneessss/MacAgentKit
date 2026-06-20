import ApplicationServices
import Foundation
import MAAccessibility
import os

let systemControlsLog = Logger(subsystem: "com.macagentkit", category: "system-controls")

/// Errors thrown by the system-controls layer.
public enum SystemControlsError: Error, Sendable, CustomStringConvertible {
    /// The host process lacks the Accessibility permission.
    case accessibilityNotGranted
    /// Control Center (`com.apple.controlcenter`) could not be located.
    case controlCenterUnavailable
    /// A required control could not be found in the UI (identifier or label).
    case controlNotFound(String)
    /// The Control Center panel did not open in time.
    case panelDidNotOpen

    public var description: String {
        switch self {
        case .accessibilityNotGranted: return "SystemControlsError.accessibilityNotGranted"
        case .controlCenterUnavailable: return "SystemControlsError.controlCenterUnavailable"
        case .controlNotFound(let what): return "SystemControlsError.controlNotFound(\(what))"
        case .panelDidNotOpen: return "SystemControlsError.panelDidNotOpen"
        }
    }
}

/// Drive the macOS Control Center via Accessibility.
///
/// Apple exposes Control Center toggles poorly, so this works by opening the
/// Control Center panel and matching tiles by their stable `AXIdentifier`
/// (e.g. `controlcenter-wifi`, `controlcenter-focus-modes`). It is **best-effort
/// across macOS versions** — Apple changes this UI freely. For mission-critical
/// toggles prefer a Shortcut (see ``DoNotDisturb/setViaShortcut(_:shortcutName:)``).
///
/// Requires the Accessibility permission.
public enum ControlCenter {

    /// Control Center's bundle identifier.
    public static let bundleID = "com.apple.controlcenter"

    /// Common, stable tile identifiers (verify with the `axinspect` example).
    public enum Tile {
        public static let focusModes = "controlcenter-focus-modes"
        public static let wifi = "controlcenter-wifi"
        public static let bluetooth = "controlcenter-bluetooth"
        public static let airdrop = "controlcenter-airdrop"
        public static let display = "controlcenter-display"
        public static let sound = "controlcenter-sound"
        public static let nowPlaying = "controlcenter-now-playing"
    }

    /// The Control Center application element, or `nil` if not running.
    public static func app() -> AXElement? {
        AXElement.application(bundleID: bundleID)
    }

    /// Opens the Control Center panel and returns its window element.
    ///
    /// Presses the Control Center menu-bar item, then waits for the panel window
    /// to appear.
    ///
    /// - Throws: ``SystemControlsError`` if Control Center is unavailable, the
    ///   menu-bar item can't be found, or the panel doesn't open.
    @discardableResult
    public static func open(timeout: TimeInterval = 3) async throws -> AXElement {
        try requireAccessibility()
        guard let ccApp = app() else { throw SystemControlsError.controlCenterUnavailable }

        // Find the menu-bar item that opens the full Control Center panel.
        let menuBarItems = ccApp.all(maxDepth: 6) { $0.role == "AXMenuBarItem" }
        guard let item = bestControlCenterMenuBarItem(menuBarItems) else {
            throw SystemControlsError.controlNotFound("Control Center menu-bar item")
        }
        try item.press()

        // The panel is a window owned by the Control Center app.
        let panel = await AXElement.waitFor(timeout: timeout, in: ccApp) { element in
            element.role == "AXWindow"
        }
        guard let panel else { throw SystemControlsError.panelDidNotOpen }
        return panel
    }

    /// Finds a tile/control by `AXIdentifier` within an open panel (or anywhere
    /// in Control Center if `panel` is `nil`).
    public static func tile(_ identifier: String, in panel: AXElement? = nil) -> AXElement? {
        let root = panel ?? app()
        return root?.firstByIdentifier(identifier)
    }

    /// Dismisses the panel by sending Escape to Control Center.
    static func dismiss() {
        guard let ccApp = app() else { return }
        // Pressing Escape closes the transient panel; best-effort.
        try? ccApp.perform("AXCancel")
    }

    /// Picks the menu-bar item most likely to open the main Control Center panel.
    private static func bestControlCenterMenuBarItem(_ items: [AXElement]) -> AXElement? {
        // Prefer an explicit identifier/label match; otherwise fall back to the
        // first pressable item (single-item menu bars are the common case).
        if let byID = items.first(where: { ($0.identifier ?? "").localizedCaseInsensitiveContains("controlcenter") }) {
            return byID
        }
        if let byLabel = items.first(where: {
            ($0.title ?? $0.axDescription ?? "").localizedCaseInsensitiveContains("control center")
        }) {
            return byLabel
        }
        return items.first { $0.actions.contains(kAXPressAction) } ?? items.first
    }
}

/// Throws if the host process is not trusted for Accessibility.
func requireAccessibility() throws {
    guard AXIsProcessTrusted() else {
        throw SystemControlsError.accessibilityNotGranted
    }
}
