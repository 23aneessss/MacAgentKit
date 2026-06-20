# Shortcuts & subprocesses

Run Shortcuts and external commands safely.

## Overview

`MAShortcuts` wraps the `/usr/bin/shortcuts` CLI and provides a safe, deadlock-
free `Subprocess` runner.

## Running Shortcuts

```swift
// Run a Shortcut, optionally piping text to its stdin.
let output = try await Shortcuts.run("My Shortcut", input: "hello")

// Enumerate and check.
let names = Shortcuts.list()          // blocking
let hasIt = Shortcuts.exists("My Shortcut")
```

The popular `macos-focus-mode` Shortcut reads `on`/`off` from stdin:

```swift
try await Shortcuts.run("macos-focus-mode", input: "on")
```

## Subprocess runner

`Subprocess` reads stdout and stderr concurrently (so a full pipe buffer never
deadlocks) and enforces a timeout by sending `SIGTERM`, then `SIGKILL`:

```swift
let result = try await Subprocess.run(
    "/usr/bin/env",
    ["echo", "hi"],
    stdin: nil,
    timeout: 5
)
print(result.status, result.stdout, result.stderr)
```

A synchronous variant, `Subprocess.runSync`, is available for non-UI threads.

## See also

- <doc:SystemControlsGuide>
