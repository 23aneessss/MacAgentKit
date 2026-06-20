import ApplicationServices

/// A small fluent builder for composing element searches.
///
/// ```swift
/// let toggle = app.query()
///     .role(.button)
///     .identifier("controlcenter-wifi")
///     .first()
/// ```
///
/// Each refinement adds an `AND` predicate; `first()`/`all()` run the combined
/// search using the robust traversal in ``AXElement/first(maxDepth:where:)``.
public struct AXQuery {
    private let root: AXElement
    private var depth: Int = 25
    private var predicates: [(AXElement) -> Bool] = []

    init(root: AXElement) {
        self.root = root
    }

    /// Limits how deep the search descends.
    public func maxDepth(_ depth: Int) -> AXQuery {
        var copy = self
        copy.depth = depth
        return copy
    }

    /// Requires the element's role to equal `role`.
    public func role(_ role: AXRole) -> AXQuery {
        adding { $0.role == role.rawValue }
    }

    /// Requires the element's role to equal the raw role string.
    public func role(_ rawRole: String) -> AXQuery {
        adding { $0.role == rawRole }
    }

    /// Requires the element's subrole to equal `subrole`.
    public func subrole(_ subrole: String) -> AXQuery {
        adding { $0.subrole == subrole }
    }

    /// Requires the element's `AXIdentifier` to equal `id`.
    public func identifier(_ id: String) -> AXQuery {
        adding { $0.identifier == id }
    }

    /// Requires the element's title to equal `title`.
    public func title(_ title: String) -> AXQuery {
        adding { $0.title == title }
    }

    /// Requires the element's title, description, or help to equal `label`.
    public func label(_ label: String) -> AXQuery {
        adding { $0.title == label || $0.axDescription == label || $0.help == label }
    }

    /// Adds an arbitrary predicate to the search.
    public func matching(_ predicate: @escaping (AXElement) -> Bool) -> AXQuery {
        adding(predicate)
    }

    /// Runs the search and returns the first match.
    public func first() -> AXElement? {
        let predicates = self.predicates
        return root.first(maxDepth: depth) { element in
            predicates.allSatisfy { $0(element) }
        }
    }

    /// Runs the search and returns all matches.
    public func all() -> [AXElement] {
        let predicates = self.predicates
        return root.all(maxDepth: depth) { element in
            predicates.allSatisfy { $0(element) }
        }
    }

    private func adding(_ predicate: @escaping (AXElement) -> Bool) -> AXQuery {
        var copy = self
        copy.predicates.append(predicate)
        return copy
    }
}

extension AXElement {
    /// Begins a fluent ``AXQuery`` rooted at this element.
    public func query() -> AXQuery {
        AXQuery(root: self)
    }
}
