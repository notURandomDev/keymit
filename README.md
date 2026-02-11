# keycount

**[English](README.md)** | [简体中文](README.zh-CN.md)

keycount is a macOS menu bar application that tracks daily keystroke counts and displays distribution by application. The project supports both Chinese and English localization with a native glass-morphism interface style.

## Features

- Menu bar window showing total keystrokes and app distribution
- Ignores modifier keys, function keys, Backspace/Forward Delete, and other non-typing inputs
- Aggregates statistics by application with corresponding app icons
- Settings page supports clearing data and switching languages (follow system/English/Simplified Chinese)
- Provides "restart required" prompt when switching languages with one-click restart
- Native NSVisualEffectView glass-morphism background

## Architecture Overview

- **Event Collection & Data Layer**: Global keyboard event monitoring, filtering, aggregation, and persistence
- **Presentation Layer**: SwiftUI dashboard and settings page
- **System Integration**: Menu bar window, native glass material, accessibility permissions, code signing
- **Localization**: Multi-language strings based on Localizable.strings

## Module Description

### KeyTracker (Core Logic)

- **File**: [KeyTracker.swift](Sources/KeyTracker.swift)
- **Responsibilities**:
  - Creates CGEventTap to capture global keystrokes, processed in main RunLoop
  - Filtering rules:
    - Ignores Backspace(51), Forward Delete(117), Caps Lock(57), F1-F12(122-135)
    - Ignores combinations with Command/Control/Option modifiers, ignores empty character events
  - App identification: Monitors foreground app activation, records localizedName and bundleIdentifier mapping
  - App icons: Prioritize bundleIdentifier → URL retrieval; fallback to running process bundleURL or system path; ultimately default to system app icon
  - Persistence: UserDefaults stores total count and distribution; introduces dirty flag, timer, and counter for throttling (save every 100 keystrokes or every 2 seconds), force save on exit

### DashboardView (Dashboard)

- **File**: [DashboardView.swift](Sources/DashboardView.swift)
- **Responsibilities**:
  - Displays today's total keystrokes and app list (progress bars show distribution)
  - Buttons to open settings window and quit app
  - Uses native glass background: root view uses underWindowBackground, list items use contentBackground

### SettingsView (Settings Page)

- **File**: [SettingsView.swift](Sources/SettingsView.swift)
- **Responsibilities**:
  - Switch language (follow system/English/Simplified Chinese); after selection, shows dialog explaining restart requirement, cancel doesn't apply, confirm writes and restarts
  - Clear data operation with confirmation dialog
  - Uses native glass background

### SettingsWindowManager (Settings Window Management)

- **File**: [SettingsWindowManager.swift](Sources/SettingsWindowManager.swift)
- **Responsibilities**:
  - Implements singleton settings window using NSWindow to prevent multiple instances
  - Injects locale environment and title localization; updates window title after language change

### App Entry & Scene

- **File**: [App.swift](Sources/App.swift)
- **Responsibilities**:
  - Uses MenuBarExtra window style to provide dashboard window
  - Registers Settings scene and injects locale environment
  - Displays total keystrokes in real-time in menu bar label

### Preferences & Restart

- **AppPreferences**: [AppPreferences.swift](Sources/AppPreferences.swift)
  - Stores language selection (\_system/en/zh-Hans), provides SwiftUI locale environment
- **RestartHelper**: [RestartHelper.swift](Sources/RestartHelper.swift)
  - Relaunches app via open and gracefully exits current process

### Native Glass Material Wrapper

- **GlassBackground**: [GlassBackground.swift](Sources/GlassBackground.swift)
  - Wraps NSVisualEffectView as SwiftUI background, configurable material and blendingMode

### Build & Resources

- **Build script**: [build.sh](build.sh)
  - Compiles Swift source code, copies Info.plist, copies localization resources
  - Icon handling: Supports Assets/AppIcon.icns, AppIcon.iconset, or 1024x1024 PNG auto-packaging
  - Performs ad-hoc signing to improve stability of system permission associations
- **Info.plist**: [Info.plist](Info.plist)
  - Declares LSUIElement menu bar app, Bundle icon, and localization regions
- **Localization resources**:
  - English: [en.lproj/Localizable.strings](Localization/en.lproj/Localizable.strings)
  - Chinese (Simplified): [zh-Hans.lproj/Localizable.strings](Localization/zh-Hans.lproj/Localizable.strings)
- **Icon Assets**:
  - Documentation: [Assets/README.md](Assets/README.md)

## Permissions & Signing

- First run requires authorization in System Settings → Privacy & Security → Accessibility
- After rebuilding (path or signature changes), re-authorization may be required; script uses ad-hoc signing to improve recognition consistency

## Development & Build

- **Build**:
  - Run `./build.sh` to generate `keycount.app`
  - Run `open keycount.app` to launch the app
- **Icon configuration**: Provide `AppIcon.icns` or `AppIcon.iconset` or `AppIcon.png(1024x1024)` under `Assets`
- **Localization**: Maintain multi-language strings in the `Localization` directory

## Localization & Language Switching

- App defaults to following system language; manual language selection available in settings
- After selecting a new language, a dialog prompts for restart; cancel doesn't apply changes, confirm immediately restarts and applies changes

## Filtering Rules

- **Counted keystrokes**: Regular input characters (including Shift combinations for uppercase or symbols)
- **Ignored keystrokes**:
  - Backspace(⌫), Forward Delete(⌦)
  - Caps Lock, F1-F12 function keys
  - Combinations with Command/Control/Option modifier keys
  - Events without characters (e.g., some system keys)

## Performance Optimization

- **Write throttling**: Save every 2 seconds or after accumulating 100 keystrokes, force save on exit
- **Icon caching**: Prioritize bundle identifier as key; simple eviction when cache exceeds 128 items

## Contributing

- PRs and Issues are welcome; suggest running build script to verify before submitting
- To add more localizations or configuration options, extend in SettingsView and Localizable.strings

## License

- To be determined (MIT/Apache-2.0, etc.)
