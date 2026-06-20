# Launch checklist & copy-paste kit

Everything needed to publish MacAgentKit as a credible, technical open-source repo.
You'll need to do the GitHub-side steps yourself (a library can't edit repo
settings). Replace `your-org` with your GitHub org/user everywhere.

## 1. Repo basics

- **Repo name:** `MacAgentKit`
- **About / description** (≤350 chars):

  > The missing low-level Swift toolkit for macOS automation & AI agents. Robust Accessibility (AX) traversal, the TCC permission maze handled, Control Center & Do Not Disturb, Shortcuts & input — zero dependencies.

- **Topics:**

  ```
  swift, swift-package, swiftpm, macos, accessibility, ax, automation,
  macos-automation, ai-agents, computer-use, developer-tools, do-not-disturb,
  shortcuts, swiftui
  ```

- **Website (About → Website):** your DocC Pages URL (see §4):
  `https://your-org.github.io/MacAgentKit/documentation/macagentkit/`

## 2. Before you push

- Replace the `your-org` placeholders in `README.md` badges/links.
- Fill the copyright holder in `LICENSE` (`© 2026 <AUTHOR>`).
- Set a contact in `CODE_OF_CONDUCT.md` (`<CONTACT-EMAIL>`).
- Confirm green local checks:

  ```bash
  swift build && swift test
  swift build --product AXInspectorCLI && swift build --product PermissionsDemo
  swift format lint --strict --recursive --configuration .swift-format Sources Tests Examples
  ```

## 3. Social preview image

A 1280×640 banner is committed at `docs/banner.png`, generated from code:

```bash
swift Tools/generate_banner.swift docs/banner.png
```

Upload it under **Settings → General → Social preview**.

## 4. DocC on GitHub Pages

The `.github/workflows/docs.yml` workflow builds DocC and deploys to Pages on every
push to `main`. To enable it:

1. **Settings → Pages → Build and deployment → Source: GitHub Actions.**
2. Push to `main`; the **Docs** workflow publishes to
   `https://your-org.github.io/MacAgentKit/documentation/macagentkit/`.
3. Put that URL in the README docs link and the repo **Website** field.

## 5. First release (v0.1.0)

```bash
git tag -a v0.1.0 -m "MacAgentKit v0.1.0"
git push origin v0.1.0
```

Then create a GitHub Release from the tag with these notes:

> ## v0.1.0 — first public release
>
> MacAgentKit gives macOS automation & agent developers the robust plumbing they
> keep re-implementing: AX traversal that works on modern macOS, the permission
> maze handled, Control Center / Do Not Disturb, Shortcuts & input. Zero
> dependencies. macOS 13+.
>
> **Highlights:**
> - Safe `AXElement` wrapper with robust manual traversal, fluent queries, async
>   `waitFor`, and observers.
> - `Permissions` for Accessibility / Automation / Screen Recording / Input
>   Monitoring, with deep links and an optional SwiftUI dashboard.
> - Do Not Disturb via Control Center (best-effort) or a Shortcut (robust).
> - Deadlock-free, timeout-enforcing `Subprocess` runner.
> - `AXInspectorCLI` and a `PermissionsDemo` menu-bar app.
>
> **Install:**
> ```swift
> .package(url: "https://github.com/your-org/MacAgentKit.git", from: "0.1.0")
> ```
>
> **Docs:** https://your-org.github.io/MacAgentKit/documentation/macagentkit/

## 6. Swift Package Index

Submit the repo at <https://swiftpackageindex.com/add-a-package>. SPI auto-builds
the docs and a compatibility matrix (Swift versions × platforms) — a strong
credibility signal. Once listed, add the SPI badges to the README.

## 7. Profile & announcement

- **Pin** the repo on your GitHub profile.
- Launch blurb for r/swift, r/macosprogramming, Mastodon/X:

  > 🛠️ MacAgentKit — the missing low-level Swift toolkit for macOS automation &
  > AI agents. Robust Accessibility traversal that works on modern macOS, the TCC
  > permission maze handled, Control Center / Do Not Disturb, Shortcuts & input.
  > Zero dependencies, MIT. macOS 13+.
  > github.com/your-org/MacAgentKit
