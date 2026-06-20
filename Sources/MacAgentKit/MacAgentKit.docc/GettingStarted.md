# Getting started

Install MacAgentKit, grant permissions, and run your first automation.

## Overview

This walkthrough takes you from zero to driving another app's UI.

### 1. Add the package

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/MacAgentKit.git", from: "0.1.0")
]
```

Add the `MacAgentKit` product to your target, then `import MacAgentKit`.

### 2. Grant Accessibility

Almost everything in the Accessibility layer requires the Accessibility
permission. Request it and deep-link the user to System Settings if needed:

```swift
if await Permissions.ensure(.accessibility) == false {
    Permissions.openSettings(for: .accessibility)
}
```

### 3. Your first automation

```swift
guard let finder = AXElement.application(bundleID: "com.apple.finder") else { return }

// Find the first button anywhere in Finder's UI and press it.
if let button = finder.query().role(.button).first() {
    try button.press()
}
```

### 4. Discover identifiers

The most robust way to match a control is by its `AXIdentifier`. Discover them
with the bundled inspector:

```bash
swift run AXInspectorCLI com.apple.finder --identifiers
```

## Troubleshooting

- **Everything returns `nil` / empty.** You almost certainly lack the
  Accessibility permission — or your **code signature changed**. macOS ties the
  grant to your signature, so ad-hoc `swift build` rebuilds revoke it. Sign with
  a stable identity during development.
- **Automation calls are denied.** The host app must declare
  `com.apple.security.automation.apple-events` and `NSAppleEventsUsageDescription`.
- **An AX read hangs.** The target app is unresponsive. Bound calls with
  `element.setMessagingTimeout(_:)`.

## See also

- <doc:DriveAnotherApp>
- <doc:PermissionsGuide>
