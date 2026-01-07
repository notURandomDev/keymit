import SwiftUI
import AppKit
import Combine

// Manages a single-instance settings window backed by NSWindow
class SettingsWindowManager: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowManager()
    private var window: NSWindow?
    private var cancellable: AnyCancellable?

    // Show or focus settings window; inject environment for localization
    func show(with tracker: KeyTracker, prefs: AppPreferences) {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let content = SettingsView(tracker: tracker)
            .environmentObject(prefs)
            .environment(\.locale, prefs.locale)
        let hosting = NSHostingView(rootView: content)
        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 480, height: 280),
                         styleMask: [.titled, .closable, .miniaturizable, .resizable],
                         backing: .buffered,
                         defer: false)
        w.center()
        w.title = NSLocalizedString("title_settings", comment: "Settings window title")
        w.isReleasedWhenClosed = false
        w.isOpaque = false
        w.backgroundColor = .clear
        w.contentView = hosting
        w.delegate = self
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = w

        // Update window title when language changes to keep UI consistent
        cancellable = prefs.$language
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.window?.title = NSLocalizedString("title_settings", comment: "Settings window title")
            }
    }

    func windowWillClose(_ notification: Notification) {
        if let w = notification.object as? NSWindow, w == window {
            window = nil
            cancellable = nil
        }
    }
}
