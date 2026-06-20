# Contributing to MacAgentKit

Thanks for your interest in improving MacAgentKit! This is low-level macOS
plumbing, so correctness and clarity matter more than breadth.

## Getting set up

```bash
git clone https://github.com/your-org/MacAgentKit.git
cd MacAgentKit
swift build
swift test
```

Requirements: macOS 13+ and a Swift 5.9+ toolchain (the package builds in Swift 6
language mode).

## Ground rules

- **Zero third-party runtime dependencies.** `swift-docc-plugin` (dev/docs) is the
  only allowed package dependency.
- **No private APIs**, no swizzling. Stay within the documented
  AX / CG / IOHID / AppleEvents surfaces.
- **No force-unwraps in public code.** Reads return optionals; mutations and
  actions throw typed errors.
- **Logging via `os.Logger`** (subsystem `com.macagentkit`). Never `print` in
  library code (examples may print).
- **Mark public value types `Sendable`** where correct; keep the package
  data-race-safe under complete concurrency checking.

## Tests

- Unit-test all **pure** logic (predicates, parsing, matching, argument handling).
- AX automation needs a UI session and can't run in CI — isolate pure logic
  behind testable functions and extend the manual integration checklist in
  [`docs/GettingStarted.md`](docs/GettingStarted.md).

Run `swift test` before opening a PR.

## Style

- Format with `swift-format` using the repo's [`.swift-format`](.swift-format):
  ```bash
  swift format lint --recursive Sources Tests Examples
  ```
- Every public symbol gets a doc comment with a short example.
- Keep commits small and logical, with clear messages.

## Submitting changes

1. Fork and branch from `main`.
2. Make your change with tests and docs.
3. Ensure `swift build`, `swift test`, and the format lint all pass.
4. Open a pull request describing the *why*, not just the *what*.

By contributing you agree your contributions are licensed under the project's MIT
license.
