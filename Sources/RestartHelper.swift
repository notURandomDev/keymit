import AppKit

// MARK: - File Description
// Provides functionality to relaunch the application.
// Used when language changes or other settings require a restart.

enum RestartHelper {
    static func relaunch() {
        let appPath = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = [
            "-c",
            "sleep 0.5; /usr/bin/open -n -- \"$1\"",
            "KeyCadence-relaunch",
            appPath
        ]
        do {
            try task.run()
        } catch {
            NSLog("KeyCadence failed to schedule relaunch: %@", error.localizedDescription)
            return
        }
        NSApp.terminate(nil)
    }
}
