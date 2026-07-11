import Foundation
import SwiftUI

// MARK: - File Description
// Manages application-wide preferences and settings.
// Handles language, tracking behavior, and launch at login options with persistence.

final class AppPreferences: ObservableObject {
    static let supportedLanguages = ["_system", "en", "zh-Hans"]

    @Published var language: String {
        didSet {
            guard Self.supportedLanguages.contains(language) else {
                language = "_system"
                return
            }
            UserDefaults.standard.set(language, forKey: "appLanguage")
            if language == "_system" {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([language], forKey: "AppleLanguages")
            }
        }
    }
    @Published var decrementOnBackspace: Bool {
        didSet { UserDefaults.standard.set(decrementOnBackspace, forKey: "decrementOnBackspace") }
    }
    @Published private(set) var launchAtLogin: Bool

    init() {
        let storedLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "_system"
        language = Self.supportedLanguages.contains(storedLanguage) ? storedLanguage : "_system"
        decrementOnBackspace = UserDefaults.standard.object(forKey: "decrementOnBackspace") as? Bool ?? false
        launchAtLogin = LaunchManager.isLaunchAtLoginEnabled()
    }

    func setLaunchAtLogin(_ enabled: Bool) throws {
        try LaunchManager.setLaunchAtLogin(enabled)
        launchAtLogin = LaunchManager.isLaunchAtLoginEnabled()
    }

    var locale: Locale {
        switch language {
        case "en": return Locale(identifier: "en")
        case "zh-Hans": return Locale(identifier: "zh-Hans")
        default: return Locale.current
        }
    }
}
