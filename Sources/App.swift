import SwiftUI
// MARK: - File Description
// Main application entry point for Keymit, configuring its menu bar dashboard and settings scene.
@main
struct KeymitApp: App {
    @StateObject private var prefs: AppPreferences
    @StateObject private var tracker: KeyTracker
    
    init() {
        let preferences = AppPreferences()
        _prefs = StateObject(wrappedValue: preferences)
        _tracker = StateObject(wrappedValue: KeyTracker(prefs: preferences))
    }

    var body: some Scene {
        // Menu bar extra shows a window-based dashboard
        MenuBarExtra {
            DashboardView(tracker: tracker)
                .environmentObject(prefs)
                .environment(\.locale, prefs.locale)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                // Realtime keystroke count in menu bar
                Text("\(tracker.todayKeystrokes)")
                    .font(.monospacedDigit(.body)())
            }
        }
        .menuBarExtraStyle(.window) // Show window instead of a plain menu
        // Settings scene for preferences UI
        Settings {
            SettingsView(tracker: tracker)
                .environmentObject(prefs)
                .environment(\.locale, prefs.locale)
        }
    }
}
