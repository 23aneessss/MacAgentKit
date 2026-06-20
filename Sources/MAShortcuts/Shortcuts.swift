import Foundation

/// Errors thrown by ``Shortcuts``.
public enum ShortcutsError: Error, Sendable, CustomStringConvertible {
    /// `shortcuts run` exited with a non-zero status.
    case runFailed(name: String, status: Int32, stderr: String)

    public var description: String {
        switch self {
        case .runFailed(let name, let status, let stderr):
            return
                "ShortcutsError.runFailed(\(name), status: \(status), stderr: \(stderr.trimmingCharacters(in: .whitespacesAndNewlines)))"
        }
    }
}

/// Runs and lists macOS Shortcuts via the `/usr/bin/shortcuts` CLI.
///
/// Running a Shortcut is often the most robust way to perform a system action
/// (e.g. toggling a Focus mode) because it sidesteps fragile UI automation.
/// For example, the popular `macos-focus-mode` shortcut reads `"on"`/`"off"`
/// from stdin:
///
/// ```swift
/// try await Shortcuts.run("macos-focus-mode", input: "on")
/// ```
public enum Shortcuts {

    /// The path to the system Shortcuts CLI.
    public static let executable = "/usr/bin/shortcuts"

    /// Runs a Shortcut by name, optionally piping `input` to its stdin, and
    /// returns whatever the Shortcut writes to stdout.
    ///
    /// - Throws: ``ShortcutsError/runFailed(name:status:stderr:)`` on non-zero
    ///   exit, or ``SubprocessError`` if the CLI can't be run.
    @discardableResult
    public static func run(_ name: String, input: String? = nil) async throws -> String {
        let result = try await Subprocess.run(executable, ["run", name], stdin: input, timeout: 60)
        guard result.status == 0 else {
            throw ShortcutsError.runFailed(name: name, status: result.status, stderr: result.stderr)
        }
        return result.stdout
    }

    /// Lists the names of all available Shortcuts.
    ///
    /// Blocking — runs the CLI synchronously. Returns an empty array on failure.
    public static func list() -> [String] {
        guard let result = try? Subprocess.runSync(executable, ["list"], timeout: 15),
            result.status == 0
        else {
            return []
        }
        return parseList(result.stdout)
    }

    /// Parses the newline-separated output of `shortcuts list` into names.
    /// Pure and testable.
    static func parseList(_ output: String) -> [String] {
        output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Whether a Shortcut with the exact `name` exists.
    public static func exists(_ name: String) -> Bool {
        list().contains(name)
    }
}
