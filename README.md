# Keymit

**English** | [简体中文](README.zh-CN.md)

Keymit is a private, local-first macOS menu bar app that counts typing
activity by day and application. It displays a yearly heatmap and per-app daily
breakdown without recording the keys or text you type.

## Product scope

- Daily keystroke total, yearly activity heatmap, and per-app distribution
- Optional Backspace subtraction that keeps lifetime and daily data consistent
- English and Simplified Chinese UI
- Optional launch at login
- Local data reset with confirmation
- Automatic recovery after Accessibility permission is granted or an event tap
  is disabled by macOS

Keymit requires macOS 13 or later. Accessibility permission is needed for
global keyboard event counts. The event tap is listen-only; only aggregate
counts and application names are persisted in `UserDefaults` on this Mac.

## Build and test

Xcode Command Line Tools or Xcode are required.

```bash
swift test --disable-sandbox
./build.sh
open Keymit.app
```

`build.sh` creates and verifies an arm64 + x86_64 universal app with an ad-hoc
signature by default. Its module cache and intermediate output stay under
`.build`, making the build reproducible in restricted and CI environments.

For day-to-day development, use the isolated debug app instead:

```bash
./build.sh --profile debug
open "Keymit Debug.app"
```

The debug app uses the separate bundle identifier `com.notURandomDev.Keymit.debug`
and the display name **Keymit Debug**. It can stay installed alongside the release
app and has its own Accessibility permission entry and preferences domain. The
debug build is single-architecture, unoptimized, and ad-hoc signed for faster
iteration; use `./build.sh` for release validation. `build-dev.sh` remains as a
convenience wrapper for the same debug profile.

### VS Code shortcut builds

The repository includes the version-controlled `.vscode/tasks.json` task
configuration. Open the repository in VS Code, then use:

- `⌘⇧B` to run the default **Keymit: Build Debug** task.
- `⌘⇧P` opens the Command Palette; choose **Tasks: Run Task** → **Keymit: Build Release** for a release build.

The default shortcut intentionally builds the isolated Debug app. Release builds
must be selected explicitly.

After launching the release app, allow **Keymit** in **System Settings → Privacy &
Security → Accessibility**. For the development app, allow **Keymit Debug** instead.
The app detects the authorization and starts tracking without a restart.

Because releases are ad-hoc signed and not notarized, the first launch is
blocked by Gatekeeper. Follow [INSTALL.md](INSTALL.md) to approve the app in
System Settings and verify the published SHA-256 checksum first.

## Package

For a local, non-distributable test package:

```bash
./create-dmg.sh
```

The ad-hoc signed, verified DMG and SHA-256 checksum are written to `dist/`.
GitHub release steps and the required disclosure are in
[RELEASING.md](RELEASING.md).

## Back up local data

Quit Keymit, then run:

```bash
./backup-data.sh
```

The script creates one private `backups/Keymit-data-<timestamp>.tar.gz` file
containing the current preferences domain. Pass a `.tar.gz` path as the first
argument to choose another destination.

To restore a backup, quit Keymit and run:

```bash
./restore-data.sh backups/Keymit-data-<timestamp>.tar.gz
```

The restore script creates another safety backup before overwriting the current
preferences, verifies the imported data, and rolls back automatically on
failure.

## Architecture

- `Sources/Core/StatisticsStore.swift`: deterministic statistics state and
  invariants; covered by unit tests
- `Sources/KeyTracker.swift`: Accessibility lifecycle, listen-only event tap,
  app attribution, throttled persistence, and legacy history migration
- `Sources/*View.swift`: SwiftUI menu dashboard, heatmap, and settings
- `Sources/AppPreferences.swift` / `LaunchManager.swift`: language and
  `SMAppService` integration
- `build.sh`, `create-dmg.sh`, `release.sh`: verified ad-hoc build and GitHub
  package release gates
- `.github/workflows/ci.yml`: PR-only core tests and universal app build
- `.github/workflows/release.yml`: `v*` tag validation, DMG packaging, checksum,
  and automatic GitHub Release creation

This separation keeps macOS integration at the boundary while the state
transitions most likely to corrupt user data remain independently testable.

## Data compatibility

Existing `totalKey`, `appStats`, and `dailyHistory` preferences are retained.
Legacy daily totals are migrated when loaded. Invalid negative values are
sanitized, and clearing statistics does not remove language or login-item
preferences.
