import Foundation

// MARK: - File Description
// Defines the available menu bar number modes and their deterministic formatting rules.
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
