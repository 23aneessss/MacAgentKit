# ``MacAgentKit``

The missing low-level toolkit for macOS automation & agents.

## Overview

Every macOS automation tool, menu-bar utility, and AI desktop agent re-implements
the same fragile plumbing: the TCC permission maze, the painful C Accessibility
API, poorly-exposed Control Center toggles, running Shortcuts and subprocesses,
and synthesizing input. MacAgentKit nails that plumbing once — cleanly, with zero
third-party dependencies — so your app can just import it.

`import MacAgentKit` re-exports every module. To slim your dependency graph,
import a single submodule instead (for example `import MAAccessibility`).

```swift
import MacAgentKit

// 1. Make sure we're trusted for Accessibility.
guard await Permissions.ensure(.accessibility) else { return }

// 2. Drive another app by stable identifier.
if let safari = AXElement.application(bundleID: "com.apple.Safari"),
   let reload = safari.firstByIdentifier("ReloadButton") {
    try reload.press()
}
```

## Topics

### Getting started

- <doc:GettingStarted>
- <doc:DriveAnotherApp>

### Guides

- <doc:PermissionsGuide>
- <doc:AccessibilityGuide>
- <doc:SystemControlsGuide>
- <doc:ShortcutsGuide>

### Package

- ``MacAgentKit/MacAgentKit``
