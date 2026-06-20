# Permissions

Detect, request, and deep-link the macOS TCC permissions an agent needs.

## Overview

`MAPermissions` covers the four permissions that matter for automation:
Accessibility, Automation (Apple Events), Screen Recording, and Input Monitoring.

```swift
// Check
let status = Permissions.status(.accessibility)   // .granted / .denied / .notDetermined

// Request (async — Accessibility polls for the out-of-process grant)
let result = await Permissions.request(.screenRecording)

// Ensure (request if needed, return whether granted)
if await Permissions.ensure(.inputMonitoring) { /* … */ }

// Deep-link to the right System Settings pane
Permissions.openSettings(for: .automation(bundleID: "com.apple.Mail"))
```

## Host-app requirements

A library can probe status but cannot grant your app capabilities. The host app
must provide:

- **Automation:** `com.apple.security.automation.apple-events` entitlement +
  `NSAppleEventsUsageDescription` in `Info.plist`.
- **Accessibility:** request at runtime; the user enables your app in Settings.

## The signing caveat

macOS ties a grant to your **code signature**. Ad-hoc `swift build` rebuilds
change the signature, so the grant is silently revoked and calls start returning
`nil` again. Sign with a stable identity during development.

## SwiftUI helpers

When SwiftUI is available, `MAPermissions` ships a minimal live dashboard:

```swift
import SwiftUI
import MacAgentKit

struct SettingsView: View {
    var body: some View {
        PermissionsView([.accessibility, .screenRecording, .inputMonitoring])
    }
}
```

## See also

- <doc:GettingStarted>
- <doc:SystemControlsGuide>
