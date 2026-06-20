import Foundation
import MAAccessibility
import MAShortcuts

/// Toggle macOS Do Not Disturb / Focus.
///
/// Two strategies are offered because neither is perfect:
///
/// - **Control Center automation** (``toggle()`` / ``set(_:)``): no extra setup,
///   but best-effort — Apple changes the Control Center UI between releases, so
///   this can break and requires the Accessibility permission.
/// - **Shortcut** (``setViaShortcut(_:shortcutName:)``): the robust path. Install
///   a Shortcut (e.g. the popular `macos-focus-mode`, which reads `on`/`off` from
///   stdin) and this drives it via the `shortcuts` CLI. Survives UI changes.
///
/// Choose per your reliability needs.
public enum DoNotDisturb {

    /// The label/identifier candidates for the Do Not Disturb row inside the
    /// Focus panel. Labels are locale-dependent, so several are tried.
    private static let dndLabels = ["Do Not Disturb", "Ne pas déranger", "No molestar"]

    /// Toggles Do Not Disturb via Control Center automation.
    ///
    /// - Throws: ``SystemControlsError`` if the UI can't be driven.
    public static func toggle() async throws {
        try await pressDoNotDisturbRow()
    }

    /// Best-effort: ensures Do Not Disturb is `on`/`off` via Control Center.
    ///
    /// If the current state can be read it only acts when needed; otherwise it
    /// performs a single toggle and logs that it couldn't confirm state. For
    /// guaranteed idempotent behaviour, use ``setViaShortcut(_:shortcutName:)``.
    public static func set(_ on: Bool) async throws {
        try await pressDoNotDisturbRow(desiredState: on)
    }

    /// Robust path: drive Do Not Disturb through a user-installed Shortcut.
    ///
    /// - Parameters:
    ///   - on: Whether to turn DND on.
    ///   - shortcutName: The Shortcut to run. Defaults to `macos-focus-mode`,
    ///     which reads `on`/`off` from stdin.
    /// - Throws: ``ShortcutsError`` / ``SubprocessError`` if the Shortcut fails.
    public static func setViaShortcut(_ on: Bool, shortcutName: String = "macos-focus-mode") async throws {
        try await Shortcuts.run(shortcutName, input: on ? "on" : "off")
    }

    // MARK: - Control Center driving

    private static func pressDoNotDisturbRow(desiredState: Bool? = nil) async throws {
        let panel = try await ControlCenter.open()

        guard let focusTile = ControlCenter.tile(ControlCenter.Tile.focusModes, in: panel) else {
            throw SystemControlsError.controlNotFound(ControlCenter.Tile.focusModes)
        }

        // Expand the Focus tile to reveal the list of Focus modes.
        try focusTile.press()

        guard let ccApp = ControlCenter.app() else {
            throw SystemControlsError.controlCenterUnavailable
        }

        // Wait for the Do Not Disturb row to appear in the expanded list.
        let dndRow = await AXElement.waitFor(timeout: 3, in: ccApp) { element in
            guard let title = element.title ?? element.axDescription else { return false }
            return dndLabels.contains(title)
        }
        guard let dndRow else {
            ControlCenter.dismiss()
            throw SystemControlsError.controlNotFound("Do Not Disturb row")
        }

        // If we can read the current state and it already matches, do nothing.
        if let desiredState, let current = currentState(of: dndRow), current == desiredState {
            systemControlsLog.debug("Do Not Disturb already \(desiredState ? "on" : "off", privacy: .public)")
            ControlCenter.dismiss()
            return
        }
        if desiredState != nil, currentState(of: dndRow) == nil {
            systemControlsLog.notice("Could not read Do Not Disturb state; toggling best-effort")
        }

        try dndRow.press()
        ControlCenter.dismiss()
    }

    /// Attempts to read whether the Do Not Disturb row is currently selected/on.
    private static func currentState(of row: AXElement) -> Bool? {
        if let selected = row.attribute("AXSelected", as: NSNumber.self)?.boolValue {
            return selected
        }
        if let value = row.boolValue {
            return value
        }
        return nil
    }
}
