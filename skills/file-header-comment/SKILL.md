---
name: "file-header-comment"
description: "Adds or updates file-level header comments explaining core functionality. Invoke when creating new files, modifying existing files, or when user requests adding file documentation."
---

# File Header Comment

This skill adds or updates file-level header comments to source files, explaining their core functionality.

## Header Comment Format

For Swift files, use the following format at the top of the file:

```swift
// MARK: - File Description
// <Brief description of the file's core purpose and main responsibilities>
```

### Format Requirements

**STRICTLY follow this format:**

1. **First line**: `// MARK: - File Description` (EXACTLY this text, no variations)
2. **Second line**: Brief description (1-2 sentences maximum)
3. **Placement**: Immediately after import statements, before any code
4. **No extra lines**: No blank lines before or after the comment block
5. **No file name**: Do NOT include `//  Filename.swift` lines
6. **No target name**: Do NOT include `//  Application` or similar lines
7. **No separators**: Do NOT include `//` separator lines

### Correct Example

```swift
import SwiftUI
import AppKit

// MARK: - File Description
// Main dashboard interface displaying keystroke statistics.
// Shows total counts, activity heatmap, and per-application breakdown.

struct DashboardView: View {
    // ...
}
```

### Incorrect Examples (DO NOT DO THIS)

```swift
// ❌ WRONG: File name and target name included
//
//  DashboardView.swift
//  Application
//
//  Main dashboard interface displaying keystroke statistics.
//

// ❌ WRONG: Extra blank lines
import SwiftUI

// MARK: - File Description

// Main dashboard interface displaying keystroke statistics.

struct DashboardView: View { }

// ❌ WRONG: Missing MARK comment
import SwiftUI
// Main dashboard interface displaying keystroke statistics.

// ❌ WRONG: Comment before imports
// MARK: - File Description
// Main dashboard interface displaying keystroke statistics.

import SwiftUI
```

## Guidelines

1. **Placement**: Place the comment immediately after import statements, before any code
2. **Brevity**: Keep descriptions concise (1-2 sentences maximum)
3. **Focus**: Describe what the file does, not how it does it
4. **Language**: Use the same language as the user's request (default: English)
5. **Strict Format**: MUST use exactly `// MARK: - File Description` as the first line

## When to Invoke

- User creates a new source file
- User modifies a file significantly
- User explicitly requests adding file documentation
- As part of a pre-commit hook for new or modified files

## Process

1. Read the file to understand its content
2. Analyze the main classes, structs, and functions to determine core purpose
3. Generate a concise description following the format above
4. Add or update the header comment at the appropriate location
5. **CRITICAL**: Verify the format matches exactly the specification below
6. Remove any existing non-compliant header comments

## Format Verification Checklist

Before completing the task, verify:

- [ ] First line is exactly `// MARK: - File Description`
- [ ] No file name line (e.g., `//  DashboardView.swift`)
- [ ] No target name line (e.g., `//  Application`)
- [ ] No separator lines (e.g., `//` alone)
- [ ] Comment is placed after all import statements
- [ ] No blank lines before the comment
- [ ] No blank lines after the comment
- [ ] Description is 1-2 sentences maximum
- [ ] Description focuses on "what" not "how"

## Example

For a file named `KeyTracker.swift` that tracks keystrokes:

```swift
import SwiftUI
import ApplicationServices
import Cocoa

// MARK: - File Description
// Tracks global keystrokes, aggregates per-app statistics, and manages data persistence.

struct DailyStats: Codable, Identifiable {
    // ...
}

class KeyTracker: ObservableObject {
    // ...
}
```
