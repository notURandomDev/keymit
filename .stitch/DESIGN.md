# Design System: Keymit

**Project ID:** Not available — extracted from the local SwiftUI application rather than a Stitch project.

## 1. Visual Theme & Atmosphere

Keymit is a compact, native macOS utility with a quiet, data-first character. The interface should feel precise, trustworthy, private, and unobtrusive: a lightweight menu-bar companion rather than a full desktop dashboard. Favor familiar macOS controls, restrained decoration, and immediate legibility over branded chrome.

The visual hierarchy is flat and functional. Content is divided by fine inset separators instead of elevated cards. Large numeric statistics provide the strongest focal point, followed by compact section labels, the activity heatmap, and dense application rows. Generous outer padding prevents the narrow dashboard from feeling cramped, while small internal gaps keep related data visually tight.

The live interface follows the current macOS light or dark appearance. Use adaptive system surfaces and text colors rather than forcing a theme. Depth comes from the settings window's translucent regular material and standard system controls; the dashboard itself uses no custom shadows. SF Symbols provide consistent, lightweight iconography.

The app icon adds a stronger brand expression: luminous mint green geometry over deep charcoal, with a keyboard-and-branch motif. Use this vivid brand treatment for identity assets or special moments, not as a large background treatment inside the utility UI.

## 2. Color Palette & Roles

- **Adaptive Primary Ink (light anchor `#000000` at 85% opacity; dark anchor `#FFFFFF` at 85% opacity):** Main labels, application names, selected-date outlines, and high-priority values. Always use the platform's adaptive primary text color so contrast follows macOS appearance and accessibility settings.
- **Adaptive Secondary Ink (light anchor `#000000` at 50% opacity; dark anchor `#FFFFFF` at 50% opacity):** Supporting labels, percentages, month and weekday labels, empty states, footer actions, and explanatory copy. This keeps secondary information visible without competing with totals.
- **Native Control Surface (light anchor `#FFFFFF`):** Footer and control backgrounds. Preserve the macOS semantic control background in dark mode rather than assigning a fixed dark substitute.
- **Hairline Separator (light anchor `#000000` at 10% opacity; dark anchor `#FFFFFF` at 10% opacity):** Fine section and row dividers. Separators should organize the narrow layout without looking boxed in.
- **System Action Blue (`#007AFF`):** Keyboard hero icon, active progress bars, and small navigation or recovery affordances. The hero icon uses 80% opacity (`#007AFFCC`) for a softer presence; primary progress fills use the solid color.
- **Activity Green (`#28CD41`):** Heatmap intensity. Empty days use secondary ink at 10% opacity. Active days progress through 30% (`#28CD414D`), 50% (`#28CD4180`), 70% (`#28CD41B3`), and 100% (`#28CD41`) according to activity volume. Keep this stepped scale discrete and instantly scannable.
- **Permission Warning Orange (`#FF9500`):** Accessibility or tracking warnings. Pair the solid icon with a pale 10% tint (`#FF95001A`) so the warning is noticeable but not alarming.
- **Brand Mint (`#54E36C`):** Representative green sampled from the app logo. Reserve for the icon, marketing identity, or carefully chosen brand moments; do not replace native action blue or activity green throughout the product.
- **Brand Near-Black (`#0C0C0C`) and Graphite (`#2C2C30`):** Logo background and inner keyboard structure. Their low-contrast layering gives the icon depth while keeping the mint linework dominant.

## 3. Typography Rules

Use the native macOS system family throughout, preserving the platform's familiar proportions and localization behavior. Do not introduce a custom typeface or decorative letter spacing.

The primary statistic is a 42-point, bold, rounded system face. It should feel friendly and prominent while remaining highly legible. Section titles use the native headline style with semibold emphasis. Application names and counts use the standard body size; application names use medium weight to distinguish them from supporting data.

Dates, years, live hover values, menu-bar totals, and application counts use monospaced numerals so values remain stable as they update. Supporting text, percentages, descriptions, and calendar annotations use caption or subheadline sizing with adaptive secondary color. Month labels are approximately 10 points and weekday labels approximately 9 points; they should remain quiet but readable.

Keep line lengths short and labels concise. Favor one-line application names with truncation over wrapping. Maintain the standard system line height and default tracking to preserve native macOS rhythm in both English and Simplified Chinese.

## 4. Component Stylings

- **Buttons:** Prefer native macOS buttons and plain icon buttons. Small navigation controls have no custom fill. Use action blue only for directional or recovery affordances; settings and quit actions remain secondary. Destructive actions use the native destructive role and always appear inside a confirmation alert.
- **Hero Statistic:** Place the contextual label and oversized rounded total on the left, with a 40-point keyboard symbol on the right. Use 20-point outer padding and a compact 4-point gap between label and value.
- **Section Headers:** Combine a small SF Symbol with a native headline label. Align left, allow flexible space to the right, and separate major regions with fine inset dividers rather than cards.
- **Cards/Containers:** Default to flat, full-width sections without custom borders or shadows. The only custom callout is the tracking warning: an 8-point gently rounded rectangle, 10-point internal padding, orange-tinted background, solid orange warning symbol, and compact two-line message.
- **Heatmap:** Use 12-point square cells with subtly rounded 2-point corners and 3-point gaps. Arrange seven rows vertically and scroll horizontally across weeks. Mark selection with a 1-point primary outline; mark today with a 1-point secondary outline at 50% opacity. Future or unavailable dates use 45% overall opacity.
- **Year Selector:** Group plain left and right chevrons around a centered, fixed-width monospaced year. Give the group 4-point padding, a 10% secondary tint, and softly rounded 6-point corners.
- **Application Rows:** Use a 32-point application icon, 12-point horizontal gap, and 8-point vertical row padding. Show the application name at medium body weight, the count with monospaced numerals, and the percentage as secondary caption text in a fixed trailing column. Inset row separators by 56 points so they begin beneath the text, not beneath the icon.
- **Progress Bars:** Use a slender 4-point pill track. The track is secondary ink at 10% opacity; the value fill is solid system action blue. Avoid labels inside the bar.
- **Inputs/Forms:** Use native grouped macOS form sections, pickers, toggles, buttons, and alerts. Place descriptive or privacy copy directly beneath its control in secondary caption styling. The settings surface uses regular translucent material and no additional card decoration.
- **Empty States:** Center a 32-point secondary SF Symbol above a short secondary label with a 12-point gap. Keep at least 100 points of vertical breathing room and avoid illustrations or promotional copy.
- **Iconography:** Use SF Symbols with native stroke and weight. Use filled symbols only when state demands urgency, such as the filled warning triangle. Do not mix third-party icon styles into the interface.

## 5. Layout Principles

The menu dashboard uses a fixed 380-by-700-point canvas. The settings window uses a fixed 500-by-450-point canvas. Preserve these compact desktop proportions when generating new screens; this is not a mobile layout and should not resemble a wide web dashboard.

Build the dashboard as a single vertical flow: hero statistic, optional tracking status, activity section, application section, scrolling application list, and anchored footer actions. The data list absorbs remaining height while headers and footer stay stable. Keep the primary reading direction top to bottom and avoid side navigation.

Use a restrained spacing scale centered on 4, 6, 8, 10, 12, 16, and 20 points. Standard horizontal content padding is approximately 16 points. Use 12 to 16 points between section headings and their content, 8 to 12 points within compact components, and 20 points around the hero statistic. Larger 40-point gaps belong only to intentionally sparse empty states.

Align text, heatmap, and row content to shared horizontal guides. Keep numbers right-aligned within repeated rows so comparisons are easy. Use flexible space to separate labels from values or actions, and fixed widths only where they prevent visual jitter, such as the year and percentage columns.

New views should remain locally focused, privacy-conscious, and information-dense without becoming visually heavy. Extend the existing system with native macOS patterns, adaptive colors, flat sectioning, modest rounded geometry, monospaced changing data, and SF Symbols. Avoid gradients, heavy shadows, large decorative cards, oversized marketing typography, and saturated brand color across broad surfaces.
