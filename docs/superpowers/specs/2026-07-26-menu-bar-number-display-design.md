# Menu Bar Number Display Modes

## Goal

Let users choose how today's keystroke count is displayed in the macOS menu bar.
The keyboard icon remains visible in every mode. Users can keep the exact count
when they want detail or choose a shorter count that changes less prominently.

## User Experience

Add a "Number display" picker to the General section of Settings with two modes:

- **Full:** show the exact count, such as `8399`.
- **Compact:** show counts below 1,000 exactly and abbreviate counts from 1,000
  upward using a whole-number `K` suffix.

Compact values are truncated rather than rounded:

| Count | Compact display |
| ---: | :--- |
| 0 | `0` |
| 8 | `8` |
| 999 | `999` |
| 1,000 | `1K` |
| 8,399 | `8K` |
| 10,999 | `10K` |

The setting takes effect immediately and does not require an application restart.
Existing and new installations default to Full mode so this release does not
silently change the current menu bar presentation.

## Design

Define a display-mode enum with `full` and `compact` cases. `AppPreferences`
owns the selected mode and persists its raw value in `UserDefaults`. An absent or
unrecognized stored value falls back to `full`.

Keep number formatting separate from the SwiftUI menu bar label. A small,
deterministic formatter accepts the count and mode and returns the display text:

- Full returns the decimal representation of the count.
- Compact returns the decimal representation below 1,000.
- Compact divides counts of 1,000 or more by 1,000 with integer division and
  appends `K`.

`KeymitApp` continues to render the keyboard symbol and uses the formatter for
the adjacent text. `SettingsView` binds its new localized picker directly to the
preference, so changes propagate through the existing `EnvironmentObject`.

## Localization

Add English and Simplified Chinese strings for the picker label and both mode
names. No explanatory text is required because the two labels are self-contained.

## Error Handling and Compatibility

The setting contains no fallible runtime operation. Invalid persisted values use
Full mode rather than leaving the menu bar in an undefined state. The existing
keystroke statistics and persistence keys are unchanged.

## Testing

Add unit coverage for:

- Full mode preserving representative counts.
- Compact mode preserving `0`, small values, and the `999` boundary.
- Compact mode formatting `1,000`, `8,399`, and a five-digit count by truncating
  to whole thousands.
- Preference decoding falling back to Full for a missing or invalid raw value,
  if the preference storage boundary can be tested without introducing
  application-framework coupling.

Run the Swift package tests and the application build to verify both the
formatter and SwiftUI integration.
