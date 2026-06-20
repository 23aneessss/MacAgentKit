# System controls

Drive Control Center and Do Not Disturb — with a robust fallback.

## Overview

Apple exposes Control Center toggles poorly. `MASystemControls` drives them via
Accessibility, matching tiles by their stable `AXIdentifier`. Because Apple
changes this UI between releases, the AX path is **best-effort** — a Shortcut is
the robust alternative.

## Do Not Disturb

```swift
// Best-effort via Control Center automation (needs Accessibility):
try await DoNotDisturb.toggle()
try await DoNotDisturb.set(true)

// Robust via a user-installed Shortcut (e.g. "macos-focus-mode"):
try await DoNotDisturb.setViaShortcut(true)
```

## Control Center tiles

You can drive other tiles by identifier — discover them with
`swift run AXInspectorCLI com.apple.controlcenter --identifiers`:

```swift
let panel = try await ControlCenter.open()
if let wifi = ControlCenter.tile(ControlCenter.Tile.wifi, in: panel) {
    try wifi.press()
}
```

Known tile identifiers live in `ControlCenter.Tile` (focus modes, Wi-Fi,
Bluetooth, AirDrop, display, sound, now playing).

## Choosing a strategy

- **Control Center automation:** no setup, but can break on macOS updates.
- **Shortcut:** install once, survives UI changes — recommended for reliability.

## See also

- <doc:ShortcutsGuide>
- <doc:PermissionsGuide>
