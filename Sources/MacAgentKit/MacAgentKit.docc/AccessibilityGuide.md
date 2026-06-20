# Accessibility

A safe Swift wrapper over the C Accessibility API, with traversal that works on
modern macOS.

## Overview

`MAAccessibility` wraps `AXUIElement` in the value type `AXElement`. Reads return
`nil` instead of crashing; mutations and actions throw typed `AXFailure` errors.

```swift
let app = AXElement.application(bundleID: "com.apple.finder")
let title = app?.title           // optional, never crashes
```

## Robust traversal

Do **not** use AppleScript `entire contents` or `kAXVisibleChildrenAttribute` —
both silently return nothing for certain windows (e.g. Control Center) on recent
macOS. `MAAccessibility` instead walks `kAXChildrenAttribute` by manual recursion
with a configurable depth and a cycle guard:

```swift
let button = app?.first(maxDepth: 20) { $0.role == "AXButton" }
let allCells = app?.all { $0.role == "AXCell" } ?? []
```

## Match by identifier first

`AXIdentifier` is stable across versions and locales; titles are not. Prefer it:

```swift
let wifi = app?.firstByIdentifier("controlcenter-wifi")
let byLabel = app?.firstByLabel("Reload")   // title / description / help
```

## Fluent queries

```swift
let toggle = app?.query()
    .role(.button)
    .identifier("controlcenter-focus-modes")
    .maxDepth(15)
    .first()
```

## Waiting and observing

```swift
// Poll until something appears (agent-friendly, cancellation-aware).
let panel = await AXElement.waitFor(timeout: 3, in: root) { $0.identifier == "panel" }

// Subscribe to notifications (needs a live run loop on the main thread).
let observer = try AXElementObserver(pid: pid)
try observer.observe("AXValueChanged", on: element) { changed in /* … */ }
```

## Threading

AX calls block on the target process. Bound them with
`element.setMessagingTimeout(_:)`. Observers require a run loop and deliver
handlers on the run-loop thread (main by default).

## See also

- <doc:DriveAnotherApp>
- <doc:SystemControlsGuide>
