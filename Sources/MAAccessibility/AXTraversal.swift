import ApplicationServices
import Foundation

extension AXElement {

    // MARK: - Robust search

    /// Finds the first descendant (or self) matching `predicate`, searching by
    /// manual recursion over direct children.
    ///
    /// This deliberately does **not** use AppleScript `entire contents` or
    /// `kAXVisibleChildrenAttribute`, both of which silently return nothing for
    /// certain windows (e.g. Control Center) on modern macOS. Instead it walks
    /// `kAXChildrenAttribute` depth-first up to `maxDepth`, guarding against
    /// cycles with a visited set.
    ///
    /// - Parameters:
    ///   - maxDepth: Maximum depth to descend (the root is depth 0).
    ///   - predicate: Returns `true` for the element you want.
    /// - Returns: The first matching element, or `nil`.
    public func first(maxDepth: Int = 25, where predicate: (AXElement) -> Bool) -> AXElement? {
        var visited = Set<AXElement>()
        return firstMatch(remainingDepth: maxDepth, visited: &visited, predicate: predicate)
    }

    /// Collects every descendant (and self) matching `predicate`.
    ///
    /// Same robust traversal as ``first(maxDepth:where:)``.
    public func all(maxDepth: Int = 25, where predicate: (AXElement) -> Bool) -> [AXElement] {
        var visited = Set<AXElement>()
        var results: [AXElement] = []
        collectMatches(remainingDepth: maxDepth, visited: &visited, results: &results, predicate: predicate)
        return results
    }

    /// Finds the first element with the given `AXIdentifier` — the most reliable
    /// match for unlabelled system controls.
    public func firstByIdentifier(_ id: String, maxDepth: Int = 25) -> AXElement? {
        first(maxDepth: maxDepth) { $0.identifier == id }
    }

    /// Finds the first element whose title, description, or help matches `label`.
    ///
    /// Prefer ``firstByIdentifier(_:maxDepth:)`` when an identifier exists, since
    /// labels are locale-dependent.
    public func firstByLabel(_ label: String, maxDepth: Int = 25) -> AXElement? {
        first(maxDepth: maxDepth) {
            $0.title == label || $0.axDescription == label || $0.help == label
        }
    }

    /// Finds the first element with the given role (and optional identifier/title).
    public func firstByRole(_ role: AXRole, maxDepth: Int = 25) -> AXElement? {
        first(maxDepth: maxDepth) { $0.role == role.rawValue }
    }

    // MARK: - Private depth-first walkers

    private func firstMatch(
        remainingDepth: Int,
        visited: inout Set<AXElement>,
        predicate: (AXElement) -> Bool
    ) -> AXElement? {
        guard visited.insert(self).inserted else { return nil }
        if predicate(self) { return self }
        guard remainingDepth > 0 else { return nil }
        for child in children {
            if let found = child.firstMatch(remainingDepth: remainingDepth - 1, visited: &visited, predicate: predicate)
            {
                return found
            }
        }
        return nil
    }

    private func collectMatches(
        remainingDepth: Int,
        visited: inout Set<AXElement>,
        results: inout [AXElement],
        predicate: (AXElement) -> Bool
    ) {
        guard visited.insert(self).inserted else { return }
        if predicate(self) { results.append(self) }
        guard remainingDepth > 0 else { return }
        for child in children {
            child.collectMatches(
                remainingDepth: remainingDepth - 1, visited: &visited, results: &results, predicate: predicate)
        }
    }

    // MARK: - Async polling wait

    /// Polls until an element matching `predicate` appears under `root`, or the
    /// timeout elapses. Ideal for agent flows where UI appears asynchronously.
    ///
    /// - Parameters:
    ///   - timeout: Maximum time to wait, in seconds.
    ///   - poll: Interval between attempts, in seconds.
    ///   - root: The element whose subtree is searched each attempt.
    ///   - predicate: Returns `true` for the element you want.
    /// - Returns: The matching element, or `nil` if the timeout elapsed (or the
    ///   surrounding task was cancelled).
    public static func waitFor(
        timeout: TimeInterval,
        poll: TimeInterval = 0.1,
        in root: AXElement,
        where predicate: @escaping @Sendable (AXElement) -> Bool
    ) async -> AXElement? {
        let deadline = Date().addingTimeInterval(timeout)
        let pollNanos = UInt64((poll > 0 ? poll : 0.1) * 1_000_000_000)
        repeat {
            if Task.isCancelled { return nil }
            if let found = root.first(where: predicate) { return found }
            do {
                try await Task.sleep(nanoseconds: pollNanos)
            } catch {
                return nil
            }
        } while Date() < deadline
        return root.first(where: predicate)
    }
}
