# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-06-20

First public release.

### Added

- **MAAccessibility** — `AXElement` wrapper over `AXUIElement` with safe,
  optional-returning attribute reads and throwing actions; robust manual-recursion
  traversal (`first`/`all`/`firstByIdentifier`/`firstByLabel`) with configurable
  `maxDepth` and a cycle guard; fluent `AXQuery`; async cancellation-aware
  `waitFor` polling; `AXElementObserver`; typed `AXFailure`; `AXRole` constants;
  per-element messaging timeouts.
- **MAPermissions** — `status`/`request`/`ensure`/`openSettings` for Accessibility,
  Automation (Apple Events), Screen Recording, and Input Monitoring; optional
  SwiftUI `PermissionRow`/`PermissionsView`.
- **MASystemControls** — Control Center driving by `AXIdentifier`; `DoNotDisturb`
  via Control Center (best-effort) and via Shortcut (robust).
- **MAShortcuts** — `Shortcuts` run/list/exists and a deadlock-free,
  timeout-enforcing `Subprocess` runner.
- **MAInput** — `CGEvent` keyboard/mouse synthesis, including `Mouse.click(_:)`
  on an `AXElement`.
- **MAApps** — `RunningApp` snapshot with frontmost/all/isRunning/activate/launch.
- **MacAgentKit** — umbrella target re-exporting all modules.
- Examples: `AXInspectorCLI` and `PermissionsDemo`.
- Documentation: README, DocC catalog (landing page, per-module guides, a
  tutorial), and a standalone getting-started guide.
- Tests: unit coverage for pure logic plus real `Subprocess` behaviour.
- CI (build + test + examples + format check) and DocC → GitHub Pages workflows.

[Unreleased]: https://github.com/your-org/MacAgentKit/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-org/MacAgentKit/releases/tag/v0.1.0
