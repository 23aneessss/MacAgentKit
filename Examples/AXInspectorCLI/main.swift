import ApplicationServices
import Foundation
import MacAgentKit

// axinspect — print the Accessibility tree of a running app.
//
// Usage:
//   axinspect <bundleID> [--max-depth N] [--identifiers] [--pid N]
//
// Examples:
//   axinspect com.apple.finder
//   axinspect com.apple.controlcenter --identifiers
//   axinspect com.apple.Safari --max-depth 8

func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

let usage = """
    axinspect — print the Accessibility (AX) tree of a running app

    USAGE:
      axinspect <bundleID> [--max-depth N] [--identifiers] [--pid N]

    OPTIONS:
      --max-depth N    Maximum traversal depth (default 25)
      --identifiers    Only print elements that expose an AXIdentifier
      --pid N          Inspect by process id instead of bundle id
      -h, --help       Show this help

    EXAMPLES:
      axinspect com.apple.finder
      axinspect com.apple.controlcenter --identifiers
    """

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.isEmpty || arguments.contains("-h") || arguments.contains("--help") {
    print(usage)
    exit(arguments.isEmpty ? 2 : 0)
}

var maxDepth = 25
var identifiersOnly = false
var pidOverride: pid_t?
var bundleID: String?

var index = 0
while index < arguments.count {
    let argument = arguments[index]
    switch argument {
    case "--max-depth":
        index += 1
        guard index < arguments.count, let value = Int(arguments[index]) else {
            fail("--max-depth requires an integer", code: 2)
        }
        maxDepth = value
    case "--identifiers":
        identifiersOnly = true
    case "--pid":
        index += 1
        guard index < arguments.count, let value = pid_t(arguments[index]) else {
            fail("--pid requires an integer", code: 2)
        }
        pidOverride = value
    default:
        if argument.hasPrefix("--") {
            fail("Unknown option: \(argument)", code: 2)
        }
        bundleID = argument
    }
    index += 1
}

if !AXIsProcessTrusted() {
    FileHandle.standardError.write(
        Data(
            """
            ⚠️  This process is not trusted for Accessibility — the tree will be empty.
                Grant Accessibility to your terminal in System Settings → Privacy & Security
                → Accessibility, then re-run.

            """.utf8))
}

let appElement: AXElement
if let pidOverride {
    appElement = AXElement.application(pid: pidOverride)
} else if let bundleID {
    guard let resolved = AXElement.application(bundleID: bundleID) else {
        fail("No running application with bundle id \(bundleID)")
    }
    appElement = resolved
} else {
    fail("Provide a bundle id or --pid", code: 2)
}

// Bound each AX call so an unresponsive app can't hang the inspector.
appElement.setMessagingTimeout(2)

func describe(_ element: AXElement) -> String {
    var parts: [String] = []
    parts.append(element.role ?? "?")
    if let subrole = element.subrole { parts.append("[\(subrole)]") }
    if let identifier = element.identifier { parts.append("#\(identifier)") }
    if let title = element.title, !title.isEmpty {
        parts.append("\"\(title)\"")
    } else if let description = element.axDescription, !description.isEmpty {
        parts.append("(\(description))")
    }
    return parts.joined(separator: " ")
}

var printedCount = 0
var visited = Set<AXElement>()

@MainActor
func walk(_ element: AXElement, depth: Int) {
    guard depth <= maxDepth else { return }
    guard visited.insert(element).inserted else { return }

    if !identifiersOnly || element.identifier != nil {
        let indent = String(repeating: "  ", count: depth)
        print("\(indent)\(describe(element))")
        printedCount += 1
    }

    for child in element.children {
        walk(child, depth: depth + 1)
    }
}

walk(appElement, depth: 0)

if printedCount == 0 {
    FileHandle.standardError.write(
        Data("No elements found (missing Accessibility permission, or app has no AX tree).\n".utf8))
}
