# KeyCadence

**English** | [简体中文](README.zh-CN.md)

KeyCadence is a private, local-first macOS menu bar app that counts typing
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

KeyCadence requires macOS 13 or later. Accessibility permission is needed for
global keyboard event counts. The event tap is listen-only; only aggregate
counts and application names are persisted in `UserDefaults` on this Mac.

## Build and test

Xcode Command Line Tools or Xcode are required.

```bash
swift test --disable-sandbox
./build.sh
open KeyCadence.app
```

`build.sh` creates and verifies an arm64 + x86_64 universal app with an ad-hoc
signature by default. Its module cache and intermediate output stay under
`.build`, making the build reproducible in restricted and CI environments.

After launch, allow KeyCadence in **System Settings → Privacy & Security →
Accessibility**. The app detects the authorization and starts tracking without a
restart.

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

Quit KeyCadence, then run:

```bash
./backup-data.sh
```

The script creates one private `backups/KeyCadence-data-<timestamp>.tar.gz`
file. It includes the current preferences domain and any data found under the
three historical bundle identifiers. Pass a `.tar.gz` path as the first
argument to choose another destination.

To restore a backup, quit KeyCadence and run:

```bash
./restore-data.sh backups/KeyCadence-data-<timestamp>.tar.gz
```

The restore script creates another safety backup before overwriting the current
preferences, verifies the imported data, and rolls back automatically on
failure. To migrate an archived legacy domain, pass its bundle identifier as a
second argument.

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
