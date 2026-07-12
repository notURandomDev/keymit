import AppKit
// MARK: - File Description
// Relaunches Keymit when settings changes require the application to restart.
enum RestartHelper {
    static func relaunch() {
        let appPath = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = [
            "-c",
            "sleep 0.5; /usr/bin/open -n -- \"$1\"",
            "Keymit-relaunch",
            appPath
        ]
        do {
            try task.run()
        } catch {
            NSLog("Keymit failed to schedule relaunch: %@", error.localizedDescription)
            return
        }
        NSApp.terminate(nil)
    }
}
