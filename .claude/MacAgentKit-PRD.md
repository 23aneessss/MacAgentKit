# MacAgentKit — Build Brief / PRD (prompt for Claude Code)

**How to use this file**
1. Create an empty folder and open Claude Code inside it:
   ```bash
   mkdir MacAgentKit && cd MacAgentKit && claude
   ```
2. Either **paste the entire "PROMPT" section below** into Claude Code, **or** drop this
   file into the folder and tell Claude Code: *"Read MacAgentKit-PRD.md and build the whole
   project exactly as specified."*
3. Let it work phase by phase. It will scaffold, implement, document, test, and verify the
   build.

> The prompt is intentionally in English (standard for an open-source dev tool and for
> coding agents). Ask me if you want a French translation.

---

# PROMPT (give this to Claude Code)

You are an expert macOS / Swift systems engineer. Build, FROM SCRATCH in this empty
directory, a production-quality, open-source Swift package called **MacAgentKit**.
This is a fresh session with no prior context — everything you need is below. Work
autonomously: scaffold, implement, document, test, and verify it compiles. Commit in
logical chunks. Do not fabricate results — run `swift build` / `swift test` and report
real output.

## 1. What MacAgentKit is (and why it must exist)

The macOS automation / AI-desktop-agent / menu-bar-utility ecosystem is exploding, but
every project re-implements the SAME fragile low-level "plumbing" badly:

- The TCC permission maze (Accessibility, Automation/Apple Events, Screen Recording,
  Input Monitoring) — detecting status, prompting, deep-linking to the right Settings pane.
- Driving the macOS Accessibility (AX) API from Swift — the C `AXUIElement` API is painful,
  and naïve approaches break on modern macOS.
- Control Center / system toggles (Do Not Disturb, Wi-Fi…) which Apple exposes poorly.
- Running Shortcuts and subprocesses safely.
- Synthesizing keyboard/mouse input correctly.

**MacAgentKit is the "picks and shovels"**: a clean, dependency-free, well-documented,
well-tested Swift package that nails this plumbing so other apps/agents just `import` it.
It is infrastructure, NOT an app and NOT an agent.

NON-GOALS (be strict): it is NOT an LLM/agent, NOT a GUI app, NOT screenshot/vision based,
NOT an MCP server, NOT a clone of existing agent projects (mediar-ai, macos26/Agent, etc.).
It is the reusable library *beneath* such tools.

Target users: developers building menu-bar apps, automation tools, AX/accessibility tools,
and the I/O layer of AI desktop agents.

## 2. Hard-won technical requirements (bake these in — they are the whole point)

These are real lessons; the library's value is getting them right:

1. **AX traversal must be robust.** Do NOT rely on AppleScript `entire contents` or
   `kAXVisibleChildrenAttribute` — both silently return nothing on recent macOS
   (15.4 / Tahoe / 26) for windows like Control Center. Implement traversal as MANUAL
   recursion over `kAXChildrenAttribute`, with a configurable `maxDepth` and a visited-set
   cycle guard.
2. **Match elements by `AXIdentifier` first** (stable across versions/locales), then by
   role + title/description. Many system controls have NO label but DO have a stable
   identifier (e.g. Control Center's Focus tile is a toggle button with
   `AXIdentifier == "controlcenter-focus-modes"`; Wi-Fi is `controlcenter-wifi`, etc.).
3. **Accessibility permission**: use `AXIsProcessTrusted()` and
   `AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true])`; deep-link with
   `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`.
   Document that ad-hoc rebuilds change the code signature → macOS revokes the grant, so
   advise consumers to sign with a stable identity during development.
4. **Automation / Apple Events** under Hardened Runtime requires the
   `com.apple.security.automation.apple-events` entitlement + `NSAppleEventsUsageDescription`
   in the *host app*. Status can be probed with `AEDeterminePermissionToAutomateTarget`.
   Document these host-app requirements clearly (the package can't set them itself).
5. **Screen Recording**: `CGPreflightScreenCaptureAccess()` / `CGRequestScreenCaptureAccess()`.
6. **Input Monitoring**: `IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)` / `IOHIDRequestAccess`.
7. **Shortcuts**: run via `/usr/bin/shortcuts run <name>`, piping input to stdin (compatible
   with the popular `macos-focus-mode` shortcut which reads "on"/"off"). List via
   `shortcuts list`.
8. **Threading**: AX calls can block; provide timeouts. AX observers (`AXObserver`) need a
   live run loop — document the threading model and offer an async-friendly API.
9. **No private APIs** beyond the documented AX/CG/IOHID/AppleEvents surfaces. No swizzling.

## 3. Package shape

- Swift Package Manager. No Xcode project required (it's a library).
- Platforms: **macOS 13+**. Swift tools 5.9+. Adopt Swift 6 language mode if it compiles
  cleanly; otherwise 5.9 with `-strict-concurrency=complete` warnings addressed. Mark public
  value types `Sendable` where correct.
- **Zero third-party dependencies** (except `swift-docc-plugin` as a dev/docs plugin).
- License: **MIT** (fill copyright "© 2026 <AUTHOR>"; leave a clear placeholder).
- Logging via `os.Logger` (subsystem "com.macagentkit"), never `print` in library code.
- Public API: no force-unwraps, throwing or optional-returning instead; typed errors.

Suggested modular layout (multiple targets, one umbrella that re-exports them so consumers
can import either `MacAgentKit` or a single submodule):

```
MacAgentKit/
├── Package.swift
├── README.md  LICENSE  CHANGELOG.md  CONTRIBUTING.md  CODE_OF_CONDUCT.md
├── .github/workflows/ci.yml
├── .github/workflows/docs.yml        # publishes DocC to GitHub Pages
├── Sources/
│   ├── MAPermissions/        # TCC + AX permission status/request/deep-links
│   ├── MAAccessibility/      # AXElement wrapper, robust traversal, queries, observers, wait
│   ├── MASystemControls/     # Do Not Disturb / Control Center helpers built on MAAccessibility
│   ├── MAShortcuts/          # Shortcuts CLI + safe Subprocess runner
│   ├── MAInput/              # CGEvent keyboard/mouse synthesis (secondary)
│   ├── MAApps/               # NSWorkspace app/window helpers
│   └── MacAgentKit/          # umbrella: @_exported import of the above + DocC catalog
├── Examples/
│   ├── AXInspectorCLI/       # `axinspect <bundleID>` prints the AX tree + identifiers
│   └── PermissionsDemo/      # tiny SwiftUI menu-bar app: live permission dashboard + DND toggle
└── Tests/
    └── MacAgentKitTests/     # unit tests for pure logic (queries, predicates, parsing)
```

## 4. Public API to implement (precise targets — refine names sensibly, keep them ergonomic)

### MAPermissions
```swift
public enum Permission: Sendable, Hashable {
    case accessibility
    case automation(bundleID: String)
    case screenRecording
    case inputMonitoring
}
public enum PermissionStatus: Sendable { case granted, denied, notDetermined }

public enum Permissions {
    public static func status(_ p: Permission) -> PermissionStatus
    @discardableResult public static func request(_ p: Permission) async -> PermissionStatus
    public static func openSettings(for p: Permission)
    /// Requests if needed and returns whether granted; never throws spuriously.
    @discardableResult public static func ensure(_ p: Permission) async -> Bool
}
```
Plus a SwiftUI helper in MAPermissions (gated by `#if canImport(SwiftUI)`):
a `PermissionRow`/`PermissionsView` that shows live status + a button. Keep optional/minimal.

### MAAccessibility (the core)
```swift
public struct AXElement: @unchecked Sendable {
    public init?(_ raw: AXUIElement)
    public static func application(pid: pid_t) -> AXElement
    public static func application(bundleID: String) -> AXElement?
    public static var systemWide: AXElement
    public static var focusedApplication: AXElement? { get }

    // Attributes (all optional/safe)
    public var role: String? { get }
    public var subrole: String? { get }
    public var title: String? { get }
    public var roleDescription: String? { get }
    public var help: String? { get }
    public var identifier: String? { get }      // AXIdentifier
    public var value: Any? { get }
    public var stringValue: String? { get }
    public var frame: CGRect? { get }
    public var isEnabled: Bool { get }
    public var children: [AXElement] { get }     // kAXChildrenAttribute, direct only
    public func attribute<T>(_ name: String, as type: T.Type) -> T?
    public func setValue(_ value: Any) throws

    // Actions
    public var actions: [String] { get }
    public func perform(_ action: String) throws
    public func press() throws                   // kAXPressAction

    // Robust search — manual recursion, NOT entire contents
    public func first(maxDepth: Int = 25, where predicate: (AXElement) -> Bool) -> AXElement?
    public func all(maxDepth: Int = 25, where predicate: (AXElement) -> Bool) -> [AXElement]
    public func firstByIdentifier(_ id: String, maxDepth: Int = 25) -> AXElement?
    public func firstByLabel(_ label: String, maxDepth: Int = 25) -> AXElement?  // title or description

    // Polling wait (great for agents)
    public static func waitFor(timeout: TimeInterval, poll: TimeInterval = 0.1,
                               in root: AXElement,
                               where predicate: @escaping (AXElement) -> Bool) async -> AXElement?
}

// Observers
public final class AXElementObserver {
    public init(pid: pid_t) throws
    public func observe(_ notification: String, on element: AXElement,
                        handler: @escaping (AXElement) -> Void) throws
    public func stop()
}

public enum AXFailure: Error { case apiError(AXError), notFound, timeout, noValue }
```
Provide a fluent query type too if it stays clean, e.g. `element.query().role(.button).identifier("x").first()`.

### MASystemControls
```swift
public enum DoNotDisturb {
    /// Toggles macOS DND via Control Center automation (open CC → expand Focus tile by
    /// AXIdentifier "controlcenter-focus-modes" → press the labelled "Do Not Disturb" row).
    /// Requires Accessibility permission. Documented as best-effort across macOS versions.
    public static func toggle() async throws
    public static func set(_ on: Bool) async throws
}
```
Document the alternative/robust path (run a Shortcut via MAShortcuts) and let the consumer choose.

### MAShortcuts
```swift
public enum Shortcuts {
    @discardableResult public static func run(_ name: String, input: String? = nil) async throws -> String
    public static func list() -> [String]
    public static func exists(_ name: String) -> Bool
}
public enum Subprocess {
    public static func run(_ executable: String, _ args: [String],
                           stdin: String? = nil, timeout: TimeInterval? = 30) async throws
        -> (status: Int32, stdout: String, stderr: String)
}
```

### MAInput (secondary)
```swift
public enum Keyboard { public static func type(_ text: String); public static func key(_ code: CGKeyCode, modifiers: CGEventFlags = []) }
public enum Mouse { public static func move(to p: CGPoint); public static func click(at p: CGPoint); public static func click(_ element: AXElement) throws }
```

### MAApps
```swift
public struct RunningApp: Sendable { public let pid: pid_t; public let bundleID: String?; public let name: String? }
public enum Apps {
    public static var frontmost: RunningApp? { get }
    public static func all() -> [RunningApp]
    public static func isRunning(bundleID: String) -> Bool
    @discardableResult public static func activate(bundleID: String) -> Bool
    @discardableResult public static func launch(bundleID: String) async throws -> RunningApp
}
```

## 5. Documentation deliverables (portfolio-critical — make it excellent)

1. **README.md** — a great one, with:
   - Centered header: project name, one-line tagline ("The missing low-level toolkit for
     macOS automation & agents"), badges (Swift, macOS 13+, SPM, License MIT, CI, DocC).
   - 30-second "Why" paragraph (the plumbing-everyone-reinvents pitch).
   - Feature bullets per module.
   - Installation (SPM `.package(url:…)` snippet + Xcode "Add Packages" steps).
   - Quick-start code samples for the 3 headline use cases:
       (a) ensure Accessibility permission, (b) find & press a button by identifier in
       another app, (c) toggle Do Not Disturb.
   - "Permissions & entitlements" section (host-app requirements, the signing/TCC caveat).
   - Threading & error-handling notes.
   - Link to full DocC docs and the example apps.
   - Positioning note (what it is vs. is not).
   - Roadmap, Contributing, License. Tasteful emoji headers; sentence case; no broken images.
2. **DocC catalog** in the umbrella target: a landing page, an article per module, and at
   least one tutorial ("Drive another app's UI in 5 minutes"). Every public symbol gets a
   doc comment with a short example.
3. **Usage manual / Getting Started** (a DocC article + `Docs/GettingStarted.md`):
   install → grant permissions → first automation → troubleshooting (the classic "it
   returns nil" = missing Accessibility permission or signature changed).
4. CHANGELOG.md (Keep a Changelog format, v0.1.0), CONTRIBUTING.md, CODE_OF_CONDUCT.md, LICENSE.

## 6. Examples (must build & run)

- **AXInspectorCLI** (`Examples/AXInspectorCLI`): a SwiftPM executable
  `axinspect <bundleID> [--max-depth N] [--identifiers]` that prints the target app's AX
  tree with role / identifier / title — demos the kit AND is genuinely useful for any dev
  discovering AXIdentifiers. Keep it clean.
- **PermissionsDemo** (`Examples/PermissionsDemo`): a tiny SwiftUI menu-bar (agent) app
  showing a live permission dashboard and a working "Toggle Do Not Disturb" button, using
  only MacAgentKit. Include a short note on the entitlements it sets.

## 7. Testing & CI

- Unit tests (Swift Testing or XCTest) for everything pure: query predicates, label/identifier
  matching logic, Subprocess argument handling, version/string parsing. AX itself is hard to
  unit-test in CI (no UI session) — isolate pure logic behind testable functions and document
  a manual integration-test checklist.
- **.github/workflows/ci.yml**: on macos-latest — `swift build`, `swift test`, build the
  example executables. Add a swift-format or SwiftLint check (config included).
- **.github/workflows/docs.yml**: build DocC and deploy to GitHub Pages.
- README shows green CI + DocC badges.

## 8. Quality bar / Definition of Done

- `swift build` and `swift test` pass; both example targets build.
- Public API fully doc-commented; DocC builds without warnings.
- No third-party runtime deps; no private APIs; no force-unwraps in public code; `os.Logger` only.
- README, DocC, usage manual, CHANGELOG, CONTRIBUTING, CODE_OF_CONDUCT, LICENSE all present.
- A consumer can add the package and accomplish the 3 quick-start tasks by copy-paste.
- `git` history is a sequence of clean, logical commits with clear messages.

## 9. How to proceed (phased — verify compilation at each step)

1. `git init`; create `Package.swift` with the targets above; stub each module so
   `swift build` succeeds. Commit.
2. Implement **MAAccessibility** (AXElement + robust recursive traversal + queries + wait).
   Add unit tests for the pure matching logic. Commit.
3. Implement **MAPermissions** (status/request/openSettings/ensure for all four permissions).
   Commit.
4. Implement **MAShortcuts** + **MAApps**, then **MASystemControls** (DND via Control Center,
   using MAAccessibility). Then **MAInput**. Commit each.
5. Build the umbrella target with `@_exported import` re-exports + DocC catalog. Commit.
6. Build **AXInspectorCLI** and **PermissionsDemo**; verify they compile. Commit.
7. Write README, DocC articles + one tutorial, usage manual, CHANGELOG, CONTRIBUTING,
   CODE_OF_CONDUCT, LICENSE. Commit.
8. Add CI + docs workflows + lint config. Run `swift build` & `swift test` and paste real
   output. Final commit. Summarize what was built, how to use it, and any caveats.

Ask me only if you hit a genuinely blocking decision; otherwise pick sensible defaults,
state them, and proceed. Prioritize a clean, compiling, well-documented v0.1.0 over breadth —
if something must be cut, cut MAInput first and note it in the roadmap.

## 10. GitHub launch strategy & repo polish (do these too)

Prepare everything needed to publish a credible, "technical" open-source repo. Put the
copy-paste-ready text in `Docs/launch.md` (you can't edit GitHub settings yourself).

- **Repo name:** `MacAgentKit`
- **About / description (≤350 chars):**
  > The missing low-level Swift toolkit for macOS automation & AI agents. Robust Accessibility (AX) traversal, the TCC permission maze handled, Control Center & Do Not Disturb, Shortcuts & input — zero dependencies.
- **Topics:** `swift`, `swift-package`, `swiftpm`, `macos`, `accessibility`, `ax`,
  `automation`, `macos-automation`, `ai-agents`, `computer-use`, `developer-tools`,
  `do-not-disturb`, `shortcuts`, `swiftui`.
- **README badges:** Swift version, macOS 13+, SPM compatible, MIT license, CI status,
  DocC/Documentation, and (once submitted) Swift Package Index.
- **Social preview image (1280×640):** generate a simple on-brand banner from code (a
  `Tools/generate_banner.swift` using CoreGraphics) — dark background, the name, the tagline,
  and a tiny "AX tree → action" motif. Commit it to `docs/banner.png` and reference it.
- **First release:** tag `v0.1.0`; create a GitHub Release using this notes template in
  `Docs/launch.md`:
  > ## v0.1.0 — first public release
  > MacAgentKit gives macOS automation & agent developers the robust plumbing they keep
  > re-implementing: AX traversal that works on modern macOS, the permission maze handled,
  > Control Center / Do Not Disturb, Shortcuts & input. Zero dependencies. macOS 13+.
  > **Highlights:** … **Install:** … **Docs:** …
- **DocC on GitHub Pages:** wire up `swift-docc-plugin` + the `docs.yml` workflow so the
  documentation has a public URL (a strong "technical maturity" signal). Put the URL in the
  README and the About → Website field instructions in `Docs/launch.md`.
- **Swift Package Index:** add a short note in `Docs/launch.md` on submitting the repo to
  swiftpackageindex.com (auto-builds docs + compatibility matrix — great credibility).
- **Profile:** instruct the user (in `Docs/launch.md`) to pin the repo, and include a 2-line
  launch blurb suitable for r/swift, r/macosprogramming, and Mastodon/X.

---

*End of brief.*
