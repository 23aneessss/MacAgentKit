# Getting started with MacAgentKit

A standalone guide to installing MacAgentKit, granting permissions, running your
first automation, and troubleshooting. (The same content is available as a DocC
article in the API docs.)

## 1. Install

### Swift Package Manager

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/your-org/MacAgentKit.git", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "MacAgentKit", package: "MacAgentKit")
    ])
]
```

### Xcode

File → **Add Package Dependencies…**, paste the repository URL, add the
`MacAgentKit` product.

You can import the umbrella (`import MacAgentKit`) or a single module
(`import MAAccessibility`, `import MAPermissions`, …).

## 2. Grant permissions

Most of the toolkit needs the **Accessibility** permission.

```swift
import MacAgentKit

if await Permissions.ensure(.accessibility) == false {
    Permissions.openSettings(for: .accessibility)
}
```

For Automation you must also configure the **host app** (a library can't):

- Entitlement: `com.apple.security.automation.apple-events`
- `Info.plist`: `NSAppleEventsUsageDescription`

## 3. First automation

```swift
guard let finder = AXElement.application(bundleID: "com.apple.finder") else { return }
finder.setMessagingTimeout(2)   // don't hang on an unresponsive app

if let button = finder.query().role(.button).first() {
    try button.press()
}
```

## 4. Discover identifiers

```bash
swift run AXInspectorCLI com.apple.finder --identifiers
```

Match controls by `AXIdentifier` whenever possible — it's stable across macOS
versions and locales, unlike titles.

## 5. Toggle Do Not Disturb

```swift
try await DoNotDisturb.toggle()                 // best-effort, via Control Center
try await DoNotDisturb.setViaShortcut(true)     // robust, via a Shortcut
```

## Troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Reads return `nil`, searches are empty | Missing Accessibility permission | `Permissions.ensure(.accessibility)` |
| Worked before, now returns `nil` | Code **signature changed** (ad-hoc rebuild) | Sign with a stable identity |
| Automation denied | Missing entitlement / usage string | Add them to the host app |
| An AX read hangs | Unresponsive target app | `element.setMessagingTimeout(_:)` |
| DND toggle fails | Control Center UI changed in this macOS | Use `DoNotDisturb.setViaShortcut` |

## Manual integration-test checklist

AX automation can't be unit-tested in CI (no UI session). Verify manually:

1. Grant your terminal/app Accessibility, then
   `swift run AXInspectorCLI com.apple.finder` prints a tree.
2. `swift run AXInspectorCLI com.apple.controlcenter --identifiers` shows
   `com.apple.menuextra.controlcenter`.
3. `swift run PermissionsDemo` shows live permission statuses; the DND button
   toggles Focus.
4. Revoke Accessibility → reads return `nil` and the inspector warns. Re-grant →
   it works again.
