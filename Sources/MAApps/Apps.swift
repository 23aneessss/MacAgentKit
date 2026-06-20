import AppKit
import Foundation
import os

private let log = Logger(subsystem: "com.macagentkit", category: "apps")

/// A lightweight, `Sendable` snapshot of a running application.
public struct RunningApp: Sendable, Hashable {
    /// The process identifier.
    public let pid: pid_t
    /// The bundle identifier, if any.
    public let bundleID: String?
    /// The localized application name, if any.
    public let name: String?

    public init(pid: pid_t, bundleID: String?, name: String?) {
        self.pid = pid
        self.bundleID = bundleID
        self.name = name
    }

    init(_ app: NSRunningApplication) {
        self.pid = app.processIdentifier
        self.bundleID = app.bundleIdentifier
        self.name = app.localizedName
    }
}

/// Errors thrown by ``Apps``.
public enum AppsError: Error, Sendable, CustomStringConvertible {
    /// No installed application matched the bundle identifier.
    case notFound(bundleID: String)

    public var description: String {
        switch self {
        case .notFound(let bundleID): return "AppsError.notFound(\(bundleID))"
        }
    }
}

/// Query and control running applications via `NSWorkspace`.
public enum Apps {

    /// The frontmost (active) application, if any.
    public static var frontmost: RunningApp? {
        NSWorkspace.shared.frontmostApplication.map(RunningApp.init)
    }

    /// A snapshot of every running application.
    public static func all() -> [RunningApp] {
        NSWorkspace.shared.runningApplications.map(RunningApp.init)
    }

    /// Whether any running application has the given bundle identifier.
    public static func isRunning(bundleID: String) -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    /// Brings the first running app with the given bundle identifier to the front.
    ///
    /// - Returns: `true` if such an app was found and asked to activate.
    @discardableResult
    public static func activate(bundleID: String) -> Bool {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first else {
            return false
        }
        if #available(macOS 14.0, *) {
            return app.activate()
        } else {
            return app.activate(options: [.activateIgnoringOtherApps])
        }
    }

    /// Launches (or returns the already-running instance of) an application by
    /// bundle identifier.
    ///
    /// - Throws: ``AppsError/notFound(bundleID:)`` if no such app is installed,
    ///   or the underlying launch error.
    @discardableResult
    public static func launch(bundleID: String) async throws -> RunningApp {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            throw AppsError.notFound(bundleID: bundleID)
        }
        let configuration = NSWorkspace.OpenConfiguration()
        let app = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
        return RunningApp(app)
    }
}
