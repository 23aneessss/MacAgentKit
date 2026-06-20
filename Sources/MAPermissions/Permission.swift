import Foundation

/// A macOS privacy permission (TCC) that an automation/agent app may need.
public enum Permission: Sendable, Hashable {
    /// Accessibility — required to read/drive other apps' UI via the AX API.
    case accessibility
    /// Automation (Apple Events) targeting a specific app by bundle identifier.
    case automation(bundleID: String)
    /// Screen Recording — required to capture screen contents.
    case screenRecording
    /// Input Monitoring — required to observe keyboard/mouse input globally.
    case inputMonitoring

    /// A short, human-readable name suitable for UI.
    public var displayName: String {
        switch self {
        case .accessibility: return "Accessibility"
        case .automation(let bundleID): return "Automation (\(bundleID))"
        case .screenRecording: return "Screen Recording"
        case .inputMonitoring: return "Input Monitoring"
        }
    }
}

/// The grant state of a ``Permission``.
public enum PermissionStatus: Sendable, Hashable {
    /// The permission is granted.
    case granted
    /// The permission was explicitly denied (or restricted).
    case denied
    /// The user has not yet been asked, or the state can't be determined.
    case notDetermined
}
