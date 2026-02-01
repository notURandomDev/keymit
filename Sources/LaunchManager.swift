import Foundation
import ServiceManagement

class LaunchManager {
    private static let bundleIdentifier = "com.user.KeyLog"
    
    static func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            guard let jobs = (SMCopyAllJobDictionaries(kSMDomainUserLaunchd).takeRetainedValue() as? [[String: AnyObject]]) else {
                return false
            }
            
            return jobs.contains { $0["Label"] as? String == bundleIdentifier }
        }
    }
    
    static func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        } else {
            if SMLoginItemSetEnabled(bundleIdentifier as CFString, enabled) {
                print("Successfully \(enabled ? "enabled" : "disabled") launch at login")
            } else {
                print("Failed to \(enabled ? "enable" : "disable") launch at login")
            }
        }
    }
}
