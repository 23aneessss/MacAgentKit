import Testing
import Foundation
@testable import MAShortcuts

@Suite("Subprocess")
struct SubprocessTests {
    @Test("Captures stdout and a zero exit status")
    func capturesStdout() async throws {
        let result = try await Subprocess.run("/bin/echo", ["hello world"])
        #expect(result.status == 0)
        #expect(result.stdout == "hello world\n")
        #expect(result.stderr.isEmpty)
    }

    @Test("Passes arguments verbatim, including spaces")
    func argumentHandling() async throws {
        let result = try await Subprocess.run("/bin/echo", ["-n", "a b", "c"])
        #expect(result.stdout == "a b c")
    }

    @Test("Feeds stdin to the child process")
    func stdin() async throws {
        let result = try await Subprocess.run("/bin/cat", [], stdin: "piped input")
        #expect(result.status == 0)
        #expect(result.stdout == "piped input")
    }

    @Test("Reports a non-zero exit status")
    func nonZeroExit() async throws {
        let result = try await Subprocess.run("/bin/sh", ["-c", "exit 7"])
        #expect(result.status == 7)
    }

    @Test("Throws executableNotFound for a missing binary")
    func executableNotFound() async {
        await #expect(throws: SubprocessError.self) {
            try await Subprocess.run("/definitely/not/here", [])
        }
    }

    @Test("Times out and terminates a long-running process")
    func timeout() async {
        await #expect(throws: SubprocessError.self) {
            try await Subprocess.run("/bin/sleep", ["5"], timeout: 0.3)
        }
    }
}
