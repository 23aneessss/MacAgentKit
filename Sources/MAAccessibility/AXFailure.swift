import ApplicationServices

/// Errors thrown by the MacAgentKit Accessibility layer.
///
/// All public Accessibility operations are throwing or optional-returning — they
/// never force-unwrap and never crash on a missing element or denied permission.
public enum AXFailure: Error, Sendable, Equatable, CustomStringConvertible {
    /// The underlying Accessibility C API returned a non-success ``AXError``.
    case apiError(AXError)
    /// A requested element could not be located within the traversal budget.
    case notFound
    /// An asynchronous wait exceeded its timeout before the predicate matched.
    case timeout
    /// An attribute or action existed but yielded no usable value.
    case noValue

    public var description: String {
        switch self {
        case .apiError(let err):
            return "AXFailure.apiError(\(err.rawValue): \(Self.name(for: err)))"
        case .notFound:
            return "AXFailure.notFound"
        case .timeout:
            return "AXFailure.timeout"
        case .noValue:
            return "AXFailure.noValue"
        }
    }

    /// Human-readable name for a raw ``AXError`` value.
    static func name(for error: AXError) -> String {
        switch error {
        case .success: return "success"
        case .failure: return "failure"
        case .illegalArgument: return "illegalArgument"
        case .invalidUIElement: return "invalidUIElement"
        case .invalidUIElementObserver: return "invalidUIElementObserver"
        case .cannotComplete: return "cannotComplete"
        case .attributeUnsupported: return "attributeUnsupported"
        case .actionUnsupported: return "actionUnsupported"
        case .notificationUnsupported: return "notificationUnsupported"
        case .notImplemented: return "notImplemented"
        case .notificationAlreadyRegistered: return "notificationAlreadyRegistered"
        case .notificationNotRegistered: return "notificationNotRegistered"
        case .apiDisabled: return "apiDisabled"
        case .noValue: return "noValue"
        case .parameterizedAttributeUnsupported: return "parameterizedAttributeUnsupported"
        case .notEnoughPrecision: return "notEnoughPrecision"
        @unknown default: return "unknown(\(error.rawValue))"
        }
    }
}
