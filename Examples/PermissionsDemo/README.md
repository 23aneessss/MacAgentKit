# PermissionsDemo

A tiny SwiftUI menu-bar app that shows a live permission dashboard and a working
**Toggle Do Not Disturb** button — built entirely on MacAgentKit.

```bash
swift run PermissionsDemo
```

A menu-bar item (a gear icon) appears; click it for the dashboard.

## Running it as a real menu-bar agent

This target is a plain SwiftPM executable so it's easy to build and verify. To
ship it as a proper background **agent** (no Dock icon), bundle it as a `.app`
and add:

- **`Info.plist`**
  - `LSUIElement = true` — runs as a menu-bar agent with no Dock icon.
  - `NSAppleEventsUsageDescription` — required *only* if you use the Automation
    permission (this demo doesn't, but your app likely will).

- **Entitlements** (if you enable the App Sandbox / Hardened Runtime)
  - `com.apple.security.automation.apple-events` — to send Apple Events
    (Automation permission).

## The permissions used

- **Accessibility** — needed to drive Control Center for the Do Not Disturb toggle.
- **Screen Recording** / **Input Monitoring** — shown in the dashboard for
  demonstration; not strictly required by the toggle.

> Tip: Control Center automation is best-effort across macOS versions. For a
> rock-solid toggle, install a Shortcut and use
> `DoNotDisturb.setViaShortcut(_:shortcutName:)`.
