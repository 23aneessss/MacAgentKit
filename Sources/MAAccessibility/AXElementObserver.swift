import ApplicationServices
import CoreFoundation

/// Boxes a Swift handler so it can be carried through the C `refcon` pointer.
final class AXObserverHandlerBox {
    let handler: (AXElement) -> Void
    init(_ handler: @escaping (AXElement) -> Void) {
        self.handler = handler
    }
}

/// The C trampoline AX calls back. It captures nothing (so it bridges to a C
/// function pointer) and forwards to the boxed Swift handler via `refcon`.
private func axObserverTrampoline(
    _ observer: AXObserver,
    _ element: AXUIElement,
    _ notification: CFString,
    _ refcon: UnsafeMutableRawPointer?
) {
    guard let refcon else { return }
    let box = Unmanaged<AXObserverHandlerBox>.fromOpaque(refcon).takeUnretainedValue()
    box.handler(AXElement(element))
}

/// Observes Accessibility notifications (e.g. `AXValueChanged`, `AXFocusedUIElementChanged`)
/// for a single application.
///
/// AX observers require a live run loop. By default this attaches its run-loop
/// source to the **main** run loop, so create and use the observer from the main
/// thread and keep a run loop spinning (any AppKit/SwiftUI app does). Handlers
/// are delivered on whatever thread runs that run loop (the main thread by
/// default).
///
/// Always call ``stop()`` (or release the observer) to unregister.
///
/// > Warning: This type is not `Sendable`. Use it from a single thread/run loop.
public final class AXElementObserver {

    private let observer: AXObserver
    private let runLoop: CFRunLoop

    /// Tracks each registration so it can be torn down and its box released.
    private struct Registration {
        let element: AXElement
        let notification: String
        let refcon: UnsafeMutableRawPointer
        let box: AXObserverHandlerBox
    }
    private var registrations: [Registration] = []
    private var stopped = false

    /// Creates an observer for the application with the given process id.
    ///
    /// - Parameters:
    ///   - pid: The target application's process id.
    ///   - runLoop: The run loop to attach to. Defaults to the main run loop.
    /// - Throws: ``AXFailure/apiError(_:)`` if the observer can't be created.
    public init(pid: pid_t, runLoop: CFRunLoop = CFRunLoopGetMain()) throws {
        var created: AXObserver?
        let err = AXObserverCreate(pid, axObserverTrampoline, &created)
        guard err == .success, let created else {
            AXLog.observer.error("AXObserverCreate failed: \(AXFailure.name(for: err), privacy: .public)")
            throw AXFailure.apiError(err)
        }
        self.observer = created
        self.runLoop = runLoop
        CFRunLoopAddSource(runLoop, AXObserverGetRunLoopSource(created), .defaultMode)
    }

    /// Registers a `handler` for a `notification` on a specific `element`.
    ///
    /// - Throws: ``AXFailure/apiError(_:)`` if registration fails.
    public func observe(
        _ notification: String,
        on element: AXElement,
        handler: @escaping (AXElement) -> Void
    ) throws {
        let box = AXObserverHandlerBox(handler)
        let refcon = Unmanaged.passRetained(box).toOpaque()
        let err = AXObserverAddNotification(observer, element.raw, notification as CFString, refcon)
        guard err == .success else {
            Unmanaged<AXObserverHandlerBox>.fromOpaque(refcon).release()
            AXLog.observer.error("AXObserverAddNotification failed: \(AXFailure.name(for: err), privacy: .public)")
            throw AXFailure.apiError(err)
        }
        registrations.append(Registration(element: element, notification: notification, refcon: refcon, box: box))
    }

    /// Unregisters every notification and detaches from the run loop.
    public func stop() {
        guard !stopped else { return }
        stopped = true
        for registration in registrations {
            AXObserverRemoveNotification(observer, registration.element.raw, registration.notification as CFString)
            Unmanaged<AXObserverHandlerBox>.fromOpaque(registration.refcon).release()
        }
        registrations.removeAll()
        CFRunLoopRemoveSource(runLoop, AXObserverGetRunLoopSource(observer), .defaultMode)
    }

    deinit {
        stop()
    }
}
