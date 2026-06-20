import Darwin
import Foundation
import os

private let log = Logger(subsystem: "com.macagentkit", category: "subprocess")

/// Errors thrown by ``Subprocess``.
public enum SubprocessError: Error, Sendable, CustomStringConvertible {
    /// The executable path does not exist or is not executable.
    case executableNotFound(String)
    /// The process failed to launch.
    case launchFailed(String, underlying: String)
    /// The process exceeded its timeout and was terminated.
    case timedOut(TimeInterval)

    public var description: String {
        switch self {
        case .executableNotFound(let path):
            return "SubprocessError.executableNotFound(\(path))"
        case .launchFailed(let path, let underlying):
            return "SubprocessError.launchFailed(\(path): \(underlying))"
        case .timedOut(let seconds):
            return "SubprocessError.timedOut(\(seconds)s)"
        }
    }
}

/// A small, safe wrapper around `Foundation.Process`.
///
/// Reads stdout and stderr concurrently (so large output never deadlocks the
/// pipe buffers), supports feeding stdin, and enforces an optional timeout by
/// terminating — then `SIGKILL`-ing — a runaway process.
public enum Subprocess {

    /// The result of running a subprocess.
    public typealias Result = (status: Int32, stdout: String, stderr: String)

    /// Runs an executable asynchronously and returns its exit status and output.
    ///
    /// - Parameters:
    ///   - executable: Absolute path to the executable (e.g. `/usr/bin/shortcuts`).
    ///   - args: Command-line arguments.
    ///   - stdin: Optional text to feed to standard input.
    ///   - timeout: Maximum run time in seconds, or `nil` for no limit. Defaults to 30s.
    /// - Throws: ``SubprocessError``.
    @discardableResult
    public static func run(
        _ executable: String,
        _ args: [String],
        stdin: String? = nil,
        timeout: TimeInterval? = 30
    ) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = try runSync(executable, args, stdin: stdin, timeout: timeout)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Synchronous variant of ``run(_:_:stdin:timeout:)``. Blocks the calling
    /// thread — never call it on the main thread of a UI app.
    @discardableResult
    public static func runSync(
        _ executable: String,
        _ args: [String],
        stdin: String? = nil,
        timeout: TimeInterval? = 30
    ) throws -> Result {
        guard FileManager.default.isExecutableFile(atPath: executable) else {
            throw SubprocessError.executableNotFound(executable)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = args

        let outPipe = Pipe()
        let errPipe = Pipe()
        let inPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        process.standardInput = inPipe

        // Read both streams concurrently so a full pipe buffer can't deadlock us.
        let outBox = DataBox()
        let errBox = DataBox()
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global().async {
            outBox.set((try? outPipe.fileHandleForReading.readToEnd()) ?? Data())
            group.leave()
        }
        group.enter()
        DispatchQueue.global().async {
            errBox.set((try? errPipe.fileHandleForReading.readToEnd()) ?? Data())
            group.leave()
        }

        do {
            try process.run()
        } catch {
            throw SubprocessError.launchFailed(executable, underlying: String(describing: error))
        }

        // Feed stdin, then close so the child sees EOF.
        if let stdin, let data = stdin.data(using: .utf8) {
            inPipe.fileHandleForWriting.write(data)
        }
        try? inPipe.fileHandleForWriting.close()

        if let timeout {
            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.02)
            }
            if process.isRunning {
                log.error("Process timed out after \(timeout, privacy: .public)s: \(executable, privacy: .public)")
                process.terminate()
                let killDeadline = Date().addingTimeInterval(2)
                while process.isRunning && Date() < killDeadline {
                    Thread.sleep(forTimeInterval: 0.02)
                }
                if process.isRunning {
                    kill(process.processIdentifier, SIGKILL)
                }
                group.wait()
                throw SubprocessError.timedOut(timeout)
            }
        }

        process.waitUntilExit()
        group.wait()

        let stdout = String(decoding: outBox.get(), as: UTF8.self)
        let stderr = String(decoding: errBox.get(), as: UTF8.self)
        return (process.terminationStatus, stdout, stderr)
    }
}

/// A tiny lock-guarded `Data` container so reader threads can hand back output
/// without a data race.
private final class DataBox: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    func set(_ newValue: Data) {
        lock.lock(); defer { lock.unlock() }
        data = newValue
    }
    func get() -> Data {
        lock.lock(); defer { lock.unlock() }
        return data
    }
}
