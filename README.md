<div align="center">

# 🛠️ MacAgentKit

**The missing low-level toolkit for macOS automation & agents.**

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue.svg)](https://www.apple.com/macos/)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://www.swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![CI](https://github.com/your-org/MacAgentKit/actions/workflows/ci.yml/badge.svg)](https://github.com/your-org/MacAgentKit/actions/workflows/ci.yml)
[![Docs](https://github.com/your-org/MacAgentKit/actions/workflows/docs.yml/badge.svg)](https://your-org.github.io/MacAgentKit/documentation/macagentkit/)

</div>

> Replace `your-org` in the badges and links above with your GitHub org/user — see [`Docs/launch.md`](Docs/launch.md).

## Why this exists

The macOS automation / AI-desktop-agent / menu-bar-utility ecosystem is booming —
and **every project re-implements the same fragile low-level plumbing badly**: the
TCC permission maze, driving the painful C Accessibility API, poking at Control
Center toggles Apple barely exposes, running Shortcuts and subprocesses, and
synthesizing input. MacAgentKit is the **picks and shovels**: a clean,
dependency-free, well-tested Swift package that nails this plumbing once so your
app can just `import` it.

It is **infrastructure, not an app** — the reusable library *beneath* menu-bar
tools, automation utilities, accessibility tools, and the I/O layer of AI desktop
agents.

## Features

- 🔐 **MAPermissions** — detect, request, and deep-link the four permissions that
  matter: Accessibility, Automation (Apple Events), Screen Recording, Input
  Monitoring. Plus an optional SwiftUI dashboard.
- 🌳 **MAAccessibility** — a safe `AXElement` wrapper over `AXUIElement` with
  **robust manual traversal** (no `entire contents`, no `kAXVisibleChildrenAttribute`
  — both silently break on modern macOS), a fluent query API, async polling
  waits, and notification observers.
- 🎛️ **MASystemControls** — Do Not Disturb / Control Center via Accessibility,
  matched by stable `AXIdentifier`, with a robust Shortcut-based fallback.
- ⚡ **MAShortcuts** — run Shortcuts (stdin-aware) and a deadlock-free, timeout-
  enforcing `Subprocess` runner.
- ⌨️ **MAInput** — `CGEvent` keyboard/mouse synthesis (secondary).
- 🪟 **MAApps** — `NSWorkspace` app/window helpers.

Zero third-party runtime dependencies. No private APIs. No swizzling.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/your-org/MacAgentKit.git", from: "0.1.0")
]
```

Then add the product(s) you need to your target — the umbrella `MacAgentKit`, or a
single module like `MAAccessibility`:

```swift
.target(name: "MyApp", dependencies: [
    .product(name: "MacAgentKit", package: "MacAgentKit")
])
```

### Xcode

File → **Add Package Dependencies…**, paste the repository URL, and add the
`MacAgentKit` library to your target.

## Quick start

### 1. Ensure the Accessibility permission

```swift
import MacAgentKit

if await Permissions.ensure(.accessibility) {
    // We're trusted — AX calls will work.
} else {
    Permissions.openSettings(for: .accessibility)
}
```

### 2. Find and press a button in another app, by identifier

```swift
import MacAgentKit

guard let safari = AXElement.application(bundleID: "com.apple.Safari") else { return }

if let reload = safari.query()
    .role(.button)
    .identifier("ReloadButton")
    .first() {
    try reload.press()
}

// Don't know the identifier? Discover it:
//   swift run AXInspectorCLI com.apple.Safari --identifiers
```

### 3. Toggle Do Not Disturb

```swift
import MacAgentKit

// Best-effort, via Control Center automation (needs Accessibility):
try await DoNotDisturb.toggle()

// Rock-solid, via a user-installed Shortcut (e.g. "macos-focus-mode"):
try await DoNotDisturb.setViaShortcut(true)
```

## Permissions & entitlements

macOS gates these capabilities behind TCC. A few things the **host app** (not this
library) must handle:

- **Accessibility:** request at runtime (`Permissions.request(.accessibility)`);
  the user toggles your app on in System Settings.
- **Automation (Apple Events):** add `com.apple.security.automation.apple-events`
  to your entitlements and `NSAppleEventsUsageDescription` to your `Info.plist`.
  A library can't set these for you.
- **Screen Recording / Input Monitoring:** request at runtime; the system prompts.

> ⚠️ **The signing caveat.** macOS ties a grant to your app's **code signature**.
> Ad-hoc `swift build` rebuilds change the signature, so macOS silently revokes
> the grant and your AX calls start returning `nil` again. During development,
> **sign with a stable identity** so the grant sticks. "It suddenly returns nil"
> almost always means *missing Accessibility permission* or *signature changed*.

## Threading & error handling

- **AX calls can block** on an unresponsive target. Bound them with
  `element.setMessagingTimeout(_:)`.
- **Reads never crash** — a missing attribute or denied permission returns `nil`.
  **Mutations and actions throw** typed `AXFailure` errors.
- **Observers need a live run loop.** `AXElementObserver` attaches to the main run
  loop by default; create and use it on the main thread.
- **`waitFor` and async APIs** are cooperative and cancellation-aware.

## Documentation & examples

- 📚 **API docs (DocC):** https://your-org.github.io/MacAgentKit/documentation/macagentkit/
- 🚀 **Getting started:** [`Docs/GettingStarted.md`](Docs/GettingStarted.md)
- 🔎 **AXInspectorCLI** — `swift run AXInspectorCLI <bundleID> --identifiers`
- 🖥️ **PermissionsDemo** — `swift run PermissionsDemo` (menu-bar dashboard + DND toggle)

## What it is vs. what it is not

**It is** the reusable plumbing beneath macOS automation tools and agents.

**It is not** an LLM or agent, not a GUI app, not screenshot/vision based, not an
MCP server, and not a clone of existing agent projects. It's the layer those
things should be built *on*.

## Roadmap

- [ ] Richer Control Center coverage (Wi-Fi, Bluetooth, brightness, sound) by identifier
- [ ] More `MAInput` ergonomics (key-combo parsing, scroll, drag)
- [ ] AX value transformers for `AXValue` ranges/booleans
- [ ] Swift Package Index listing + compatibility matrix

## Contributing

Contributions welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md) and our
[`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## License

MIT — see [`LICENSE`](LICENSE).
