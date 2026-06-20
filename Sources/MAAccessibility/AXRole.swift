import ApplicationServices

/// A strongly-typed wrapper around Accessibility role strings (e.g. `AXButton`).
///
/// Use the static constants for common roles, or construct your own from any
/// raw `AXRole` string. Roles are stable across macOS versions and locales,
/// unlike user-facing titles.
public struct AXRole: RawRepresentable, Sendable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }

    public static let application = AXRole(kAXApplicationRole)
    public static let window = AXRole(kAXWindowRole)
    public static let button = AXRole(kAXButtonRole)
    public static let menuButton = AXRole(kAXMenuButtonRole)
    public static let popUpButton = AXRole(kAXPopUpButtonRole)
    public static let checkBox = AXRole(kAXCheckBoxRole)
    public static let radioButton = AXRole(kAXRadioButtonRole)
    public static let slider = AXRole(kAXSliderRole)
    public static let textField = AXRole(kAXTextFieldRole)
    public static let textArea = AXRole(kAXTextAreaRole)
    public static let staticText = AXRole(kAXStaticTextRole)
    public static let group = AXRole(kAXGroupRole)
    public static let toolbar = AXRole(kAXToolbarRole)
    public static let menuBar = AXRole(kAXMenuBarRole)
    public static let menu = AXRole(kAXMenuRole)
    public static let menuItem = AXRole(kAXMenuItemRole)
    public static let cell = AXRole(kAXCellRole)
    public static let row = AXRole(kAXRowRole)
    public static let table = AXRole(kAXTableRole)
    public static let outline = AXRole(kAXOutlineRole)
    public static let list = AXRole(kAXListRole)
    public static let image = AXRole(kAXImageRole)
    public static let scrollArea = AXRole(kAXScrollAreaRole)
    public static let webArea = AXRole("AXWebArea")
}
