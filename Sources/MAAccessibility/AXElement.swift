import ApplicationServices
import CoreGraphics
import Foundation
import AppKit

/// A safe, ergonomic Swift wrapper around a single `AXUIElement`.
///
/// `AXElement` hides the painful C `AXUIElement` API behind optional-returning
/// accessors and throwing actions. Reads never crash: a missing attribute, an
/// unsupported role, or a denied permission all surface as `nil` (for reads) or
/// a thrown ``AXFailure`` (for mutations and actions).
///
/// ## Topics
/// ### Creating elements
/// - ``init(_:)-(AXUIElement)``
/// - ``application(pid:)``
/// - ``application(bundleID:)``
/// - ``systemWide``
/// - ``focusedApplication``
///
/// ### Reading attributes
/// - ``role``
/// - ``identifier``
/// - ``title``
/// - ``frame``
///
/// ### Searching
/// - ``first(maxDepth:where:)``
/// - ``all(maxDepth:where:)``
/// - ``firstByIdentifier(_:maxDepth:)``
///
/// > Important: Most accessors return `nil` and most searches return empty if
/// > the host process lacks the Accessibility permission. Check it with
/// > `MAPermissions` first.
public struct AXElement: @unchecked Sendable {

    /// The underlying Accessibility element. `AXUIElement` is a thread-safe
    /// CoreFoundation reference type, which is why ``AXElement`` is `Sendable`.
    public let raw: AXUIElement

    /// Wraps a raw `AXUIElement`.
    public init(_ raw: AXUIElement) {
        self.raw = raw
    }

    /// Wraps an optional raw `AXUIElement`, failing if it is `nil`.
    ///
    /// Convenience for bridging the many C APIs that hand back an optional.
    public init?(_ raw: AXUIElement?) {
        guard let raw else { return nil }
        self.raw = raw
    }

    // MARK: - Roots

    /// The accessibility element for a running application, by process id.
    public static func application(pid: pid_t) -> AXElement {
        AXElement(AXUIElementCreateApplication(pid))
    }

    /// The accessibility element for the first running application matching a
    /// bundle identifier, or `nil` if no such app is running.
    public static func application(bundleID: String) -> AXElement? {
        let matches = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        guard let pid = matches.first?.processIdentifier else { return nil }
        return application(pid: pid)
    }

    /// The system-wide accessibility element (the root of everything on screen).
    public static var systemWide: AXElement {
        AXElement(AXUIElementCreateSystemWide())
    }

    /// The accessibility element of the application that currently has focus.
    public static var focusedApplication: AXElement? {
        systemWide.elementAttribute(kAXFocusedApplicationAttribute)
    }

    // MARK: - Raw attribute access

    /// Reads a raw CoreFoundation attribute value, or `nil` if unsupported/absent.
    public func rawAttribute(_ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        let err = AXUIElementCopyAttributeValue(raw, name as CFString, &value)
        guard err == .success else { return nil }
        return value
    }

    /// Reads an attribute and bridges it to a Swift type, or `nil` on mismatch.
    public func attribute<T>(_ name: String, as type: T.Type) -> T? {
        rawAttribute(name) as? T
    }

    /// Reads an attribute that is itself an `AXUIElement` and wraps it.
    func elementAttribute(_ name: String) -> AXElement? {
        guard let value = rawAttribute(name),
              CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return AXElement(unsafeDowncast(value, to: AXUIElement.self))
    }

    /// Reads an attribute that is an array of `AXUIElement`s and wraps each.
    func elementArrayAttribute(_ name: String) -> [AXElement] {
        guard let array = rawAttribute(name) as? [AXUIElement] else { return [] }
        return array.map(AXElement.init)
    }

    // MARK: - Common attributes

    /// The element's `AXRole` (e.g. `AXButton`). Stable across versions/locales.
    public var role: String? { attribute(kAXRoleAttribute, as: String.self) }

    /// The element's `AXSubrole` (e.g. `AXCloseButton`), if any.
    public var subrole: String? { attribute(kAXSubroleAttribute, as: String.self) }

    /// The element's user-facing title. Locale-dependent — prefer ``identifier``.
    public var title: String? { attribute(kAXTitleAttribute, as: String.self) }

    /// A localized, human-readable description of the element's role.
    public var roleDescription: String? { attribute(kAXRoleDescriptionAttribute, as: String.self) }

    /// The element's `AXDescription` (a label distinct from ``title``), if any.
    public var axDescription: String? { attribute(kAXDescriptionAttribute, as: String.self) }

    /// The element's help/tooltip text, if any.
    public var help: String? { attribute(kAXHelpAttribute, as: String.self) }

    /// The element's `AXIdentifier` — the most stable way to match a control.
    ///
    /// Many system controls have no title but do expose a stable identifier
    /// (e.g. Control Center's Wi-Fi tile is `controlcenter-wifi`). Always match
    /// on this first when available.
    public var identifier: String? { attribute("AXIdentifier", as: String.self) }

    /// The element's raw `AXValue` as a loosely-typed value, if any.
    public var value: Any? { rawAttribute(kAXValueAttribute) }

    /// The element's value coerced to a `String` (handles text and number values).
    public var stringValue: String? {
        if let s = attribute(kAXValueAttribute, as: String.self) { return s }
        if let n = attribute(kAXValueAttribute, as: NSNumber.self) { return n.stringValue }
        return nil
    }

    /// The element's value coerced to a `Bool` (e.g. a checkbox/toggle state).
    public var boolValue: Bool? {
        attribute(kAXValueAttribute, as: NSNumber.self)?.boolValue
    }

    /// The element's screen frame in global coordinates, if it has position+size.
    public var frame: CGRect? {
        guard let posRef = rawAttribute(kAXPositionAttribute),
              CFGetTypeID(posRef) == AXValueGetTypeID(),
              let sizeRef = rawAttribute(kAXSizeAttribute),
              CFGetTypeID(sizeRef) == AXValueGetTypeID() else { return nil }
        let positionValue = unsafeDowncast(posRef, to: AXValue.self)
        let sizeValue = unsafeDowncast(sizeRef, to: AXValue.self)
        var point = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionValue, .cgPoint, &point),
              AXValueGetValue(sizeValue, .cgSize, &size) else { return nil }
        return CGRect(origin: point, size: size)
    }

    /// Whether the element is enabled. Defaults to `false` if not reported.
    public var isEnabled: Bool { attribute(kAXEnabledAttribute, as: NSNumber.self)?.boolValue ?? false }

    /// The element's direct children only (`kAXChildrenAttribute`).
    ///
    /// Deliberately *not* recursive and *not* `kAXVisibleChildrenAttribute` —
    /// see ``first(maxDepth:where:)`` for robust deep search.
    public var children: [AXElement] { elementArrayAttribute(kAXChildrenAttribute) }

    /// The element's parent, if any.
    public var parent: AXElement? { elementAttribute(kAXParentAttribute) }

    /// An application element's windows (`kAXWindowsAttribute`).
    public var windows: [AXElement] { elementArrayAttribute(kAXWindowsAttribute) }

    /// The process id that owns this element, if obtainable.
    public var pid: pid_t? {
        var pid: pid_t = 0
        guard AXUIElementGetPid(raw, &pid) == .success else { return nil }
        return pid
    }

    // MARK: - Mutation

    /// Sets the element's `AXValue` attribute, throwing on failure.
    public func setValue(_ value: Any) throws {
        try setAttribute(kAXValueAttribute, value)
    }

    /// Sets an arbitrary attribute, throwing ``AXFailure/apiError(_:)`` on failure.
    public func setAttribute(_ name: String, _ value: Any) throws {
        let err = AXUIElementSetAttributeValue(raw, name as CFString, value as CFTypeRef)
        guard err == .success else { throw AXFailure.apiError(err) }
    }

    // MARK: - Actions

    /// The action names this element supports (e.g. `AXPress`).
    public var actions: [String] {
        var names: CFArray?
        guard AXUIElementCopyActionNames(raw, &names) == .success,
              let names = names as? [String] else { return [] }
        return names
    }

    /// Performs a named action, throwing ``AXFailure/apiError(_:)`` on failure.
    public func perform(_ action: String) throws {
        let err = AXUIElementPerformAction(raw, action as CFString)
        guard err == .success else { throw AXFailure.apiError(err) }
    }

    /// Performs the standard press action (`kAXPressAction`).
    public func press() throws {
        try perform(kAXPressAction)
    }

    // MARK: - Threading

    /// Sets the per-element messaging timeout (in seconds) for AX calls.
    ///
    /// AX calls block on the target process; an unresponsive app can hang a
    /// read indefinitely. Set a timeout to bound that. Pass `0` to reset to the
    /// system default.
    public func setMessagingTimeout(_ seconds: TimeInterval) {
        AXUIElementSetMessagingTimeout(raw, Float(seconds))
    }
}

extension AXElement: Equatable, Hashable {
    public static func == (lhs: AXElement, rhs: AXElement) -> Bool {
        CFEqual(lhs.raw, rhs.raw)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(raw))
    }
}

extension AXElement: CustomStringConvertible {
    public var description: String {
        var parts: [String] = []
        parts.append("role=\(role ?? "?")")
        if let subrole { parts.append("subrole=\(subrole)") }
        if let identifier { parts.append("id=\(identifier)") }
        if let title, !title.isEmpty { parts.append("title=\(title.debugDescription)") }
        return "AXElement(\(parts.joined(separator: " ")))"
    }
}
