import AppKit

// MARK: - File Description
// Provides functionality to relaunch the application.
// Used when language changes or other settings require a restart.

enum RestartHelper {
    static func relaunch() {
        let appPath = Bundle.main.bundlePath
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["sh", "-c", "sleep 0.2; open \"\(appPath)\""]
        try? task.run()
        NSApp.terminate(nil)
    }
}
