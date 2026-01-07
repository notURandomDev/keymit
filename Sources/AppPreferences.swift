import Foundation
import SwiftUI

class AppPreferences: ObservableObject {
    @Published var language: String {
        didSet {
            UserDefaults.standard.set(language, forKey: "appLanguage")
            if language == "_system" {
                UserDefaults.standard.removeObject(forKey: "AppleLanguages")
            } else {
                UserDefaults.standard.set([language], forKey: "AppleLanguages")
            }
            UserDefaults.standard.synchronize()
        }
    }
    @Published var decrementOnBackspace: Bool {
        didSet { UserDefaults.standard.set(decrementOnBackspace, forKey: "decrementOnBackspace") }
    }

    init() {
        language = UserDefaults.standard.string(forKey: "appLanguage") ?? "_system"
        decrementOnBackspace = UserDefaults.standard.object(forKey: "decrementOnBackspace") as? Bool ?? false
    }

    var locale: Locale {
        switch language {
        case "en": return Locale(identifier: "en")
        case "zh-Hans": return Locale(identifier: "zh-Hans")
        default: return Locale.current
        }
    }
}
