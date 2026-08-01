# Menu Bar Number Display Modes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persistent Full/Compact preference that controls how today's keystroke count appears beside the always-visible keyboard icon.

**Architecture:** Put the display mode and deterministic count formatting in `KeymitCore` so all boundary behavior is unit-testable. Let `AppPreferences` persist the mode, then bind the Settings picker and menu bar label to that shared observable preference.

**Tech Stack:** Swift 5.9, SwiftUI, Foundation `UserDefaults`, XCTest, macOS 13+

## Global Constraints

- Keep the keyboard icon visible in Full and Compact modes.
- Full mode displays the exact decimal count.
- Compact mode displays counts from 0 through 999 exactly.
- Compact mode truncates counts of 1,000 or more to whole thousands and appends uppercase `K`.
- The mode takes effect immediately without restarting the application.
- Missing or invalid stored values default to Full mode.
- Do not change existing keystroke statistics or their persistence keys.
- Do not create a Git commit; leave all changes in the working tree for the user.

---

### Task 1: Testable Count Formatting

**Files:**
- Create: `Sources/Core/MenuBarCountFormatter.swift`
- Create: `Tests/KeymitCoreTests/MenuBarCountFormatterTests.swift`

**Interfaces:**
- Produces: `enum MenuBarNumberDisplayMode: String, CaseIterable` with cases `full` and `compact`.
- Produces: `MenuBarCountFormatter.string(for count: Int, mode: MenuBarNumberDisplayMode) -> String`.

- [ ] **Step 1: Write the failing formatter tests**

```swift
import XCTest
@testable import KeymitCore

final class MenuBarCountFormatterTests: XCTestCase {
    func testFullModePreservesExactCounts() {
        XCTAssertEqual(MenuBarCountFormatter.string(for: 0, mode: .full), "0")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 8_399, mode: .full), "8399")
    }

    func testCompactModePreservesCountsBelowOneThousand() {
        XCTAssertEqual(MenuBarCountFormatter.string(for: 0, mode: .compact), "0")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 8, mode: .compact), "8")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 999, mode: .compact), "999")
    }

    func testCompactModeTruncatesCountsToWholeThousands() {
        XCTAssertEqual(MenuBarCountFormatter.string(for: 1_000, mode: .compact), "1K")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 8_399, mode: .compact), "8K")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 10_999, mode: .compact), "10K")
    }
}
```

- [ ] **Step 2: Run the tests and verify RED**

Run:

```bash
swift test --disable-sandbox --filter MenuBarCountFormatterTests
```

Expected: compilation fails because `MenuBarCountFormatter` and
`MenuBarNumberDisplayMode` do not exist.

- [ ] **Step 3: Add the minimal formatter**

```swift
import Foundation

enum MenuBarNumberDisplayMode: String, CaseIterable {
    case full
    case compact
}

enum MenuBarCountFormatter {
    static func string(for count: Int, mode: MenuBarNumberDisplayMode) -> String {
        switch mode {
        case .full:
            return String(count)
        case .compact where count >= 1_000:
            return "\(count / 1_000)K"
        case .compact:
            return String(count)
        }
    }
}
```

- [ ] **Step 4: Run the focused tests and verify GREEN**

Run:

```bash
swift test --disable-sandbox --filter MenuBarCountFormatterTests
```

Expected: all three tests pass.

- [ ] **Step 5: Run the complete core suite**

Run:

```bash
swift test --disable-sandbox
```

Expected: all `KeymitCoreTests` pass.

### Task 2: Persist and Render the Selected Mode

**Files:**
- Modify: `Sources/AppPreferences.swift`
- Modify: `Sources/App.swift`
- Modify: `Sources/SettingsView.swift`
- Modify: `Localization/en.lproj/Localizable.strings`
- Modify: `Localization/zh-Hans.lproj/Localizable.strings`

**Interfaces:**
- Consumes: `MenuBarNumberDisplayMode` and `MenuBarCountFormatter.string(for:mode:)` from Task 1.
- Produces: `AppPreferences.menuBarNumberDisplayMode: MenuBarNumberDisplayMode`.
- Persists: raw mode value under `menuBarNumberDisplayMode`.

- [ ] **Step 1: Add the persisted preference**

Add this property to `AppPreferences`:

```swift
@Published var menuBarNumberDisplayMode: MenuBarNumberDisplayMode {
    didSet {
        UserDefaults.standard.set(
            menuBarNumberDisplayMode.rawValue,
            forKey: "menuBarNumberDisplayMode"
        )
    }
}
```

Initialize it before `launchAtLogin`:

```swift
let storedDisplayMode = UserDefaults.standard.string(forKey: "menuBarNumberDisplayMode")
menuBarNumberDisplayMode = MenuBarNumberDisplayMode(rawValue: storedDisplayMode ?? "") ?? .full
```

- [ ] **Step 2: Format the menu bar count from the preference**

Replace the direct count interpolation in `KeymitApp` with:

```swift
Text(
    MenuBarCountFormatter.string(
        for: tracker.todayKeystrokes,
        mode: prefs.menuBarNumberDisplayMode
    )
)
.font(.monospacedDigit(.body)())
```

Leave `Image(systemName: "keyboard")` unchanged.

- [ ] **Step 3: Add the Settings picker**

In the General section of `SettingsView`, add:

```swift
Picker(
    LocalizedStringKey("picker_number_display"),
    selection: $prefs.menuBarNumberDisplayMode
) {
    Text(LocalizedStringKey("number_display_full"))
        .tag(MenuBarNumberDisplayMode.full)
    Text(LocalizedStringKey("number_display_compact"))
        .tag(MenuBarNumberDisplayMode.compact)
}
```

Because `prefs` is an `EnvironmentObject`, this binding updates the menu bar
immediately and persists through the property's `didSet`.

- [ ] **Step 4: Add localized labels**

Append to `Localization/en.lproj/Localizable.strings`:

```text
"picker_number_display" = "Number display";
"number_display_full" = "Full";
"number_display_compact" = "Compact";
```

Append to `Localization/zh-Hans.lproj/Localizable.strings`:

```text
"picker_number_display" = "数字显示";
"number_display_full" = "完整";
"number_display_compact" = "精简";
```

- [ ] **Step 5: Validate localization and build integration**

Run:

```bash
plutil -lint Localization/en.lproj/Localizable.strings Localization/zh-Hans.lproj/Localizable.strings
swift test --disable-sandbox
ARCHS="$(uname -m)" ./build.sh
```

Expected: both localization files are valid, all core tests pass, and the
single-architecture application build completes without warnings or errors.

### Task 3: Final Review

**Files:**
- Review all files listed in Tasks 1 and 2.

**Interfaces:**
- Consumes the completed feature.
- Produces no additional production interface.

- [ ] **Step 1: Inspect the working-tree diff**

Run:

```bash
git diff --check
git diff -- Sources Tests Localization docs/superpowers
git status --short
```

Expected: no whitespace errors; the diff contains only the approved feature,
tests, design document, and implementation plan; no commit is created.

- [ ] **Step 2: Confirm each observable behavior**

Verify from tests and source that:

- Full mode renders `8399`.
- Compact mode renders `999`, `1K`, `8K`, and `10K` at the specified boundaries.
- The keyboard symbol is present regardless of mode.
- The picker writes directly to the shared preference and therefore updates
  the label without restart.
- Invalid or absent persisted values initialize to Full mode.
