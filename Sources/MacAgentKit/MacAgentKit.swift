/// # MacAgentKit
///
/// The missing low-level toolkit for macOS automation & agents.
///
/// `import MacAgentKit` re-exports every module, so you get the whole toolkit
/// with one import. To slim your dependency graph, import a single submodule
/// instead (e.g. `import MAAccessibility`).
///
/// ## Modules
/// - ``MAPermissions``: detect/request/deep-link the TCC permission maze.
/// - ``MAAccessibility``: robust AX traversal, queries, observers, waits.
/// - ``MASystemControls``: Do Not Disturb / Control Center helpers.
/// - ``MAShortcuts``: run Shortcuts and subprocesses safely.
/// - ``MAInput``: keyboard/mouse synthesis (secondary).
/// - ``MAApps``: app/window helpers over `NSWorkspace`.

@_exported import MAAccessibility
@_exported import MAApps
@_exported import MAInput
@_exported import MAPermissions
@_exported import MAShortcuts
@_exported import MASystemControls

/// Metadata about the MacAgentKit package.
public enum MacAgentKit {
    /// The semantic version of this package.
    public static let version = "0.1.0"
}
