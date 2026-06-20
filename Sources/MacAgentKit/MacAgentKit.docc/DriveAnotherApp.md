# Tutorial: Drive another app's UI in 5 minutes

Find a control in another application and act on it, robustly.

## Overview

We'll open System Settings, locate a control by its stable identifier, and press
it — the same pattern you'd use to automate any app.

### Step 1 — Make sure you're trusted

```swift
import MacAgentKit

guard await Permissions.ensure(.accessibility) else {
    Permissions.openSettings(for: .accessibility)
    return
}
```

### Step 2 — Get the application element

```swift
// Launch (or get the running instance) and grab its AX element.
let app = try await Apps.launch(bundleID: "com.apple.systempreferences")
guard let settings = AXElement.application(pid: app.pid) else { return }
```

### Step 3 — Find a control

Match by identifier when you can (stable across versions and locales); fall back
to role + label otherwise.

```swift
// Bound AX calls so an unresponsive app can't hang us.
settings.setMessagingTimeout(2)

let target = settings.query()
    .role(.button)
    .first()      // refine with .identifier(...) / .label(...) as needed
```

Don't know the identifier? Discover it:

```bash
swift run AXInspectorCLI com.apple.systempreferences --identifiers
```

### Step 4 — Act, and wait for results

```swift
if let target {
    try target.press()
}

// Agent-friendly: wait for some element to appear after an action.
let appeared = await AXElement.waitFor(timeout: 3, in: settings) { element in
    element.identifier == "some-panel-that-appears"
}
```

### Step 5 — React to changes (optional)

```swift
let observer = try AXElementObserver(pid: app.pid)
try observer.observe("AXFocusedUIElementChanged", on: settings) { focused in
    print("Focus moved to \(focused)")
}
// Keep `observer` alive while a run loop spins; call observer.stop() when done.
```

That's it — request permission, resolve the app, query, act, and optionally wait
or observe.

## See also

- <doc:AccessibilityGuide>
- <doc:GettingStarted>
