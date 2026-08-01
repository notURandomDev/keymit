import SwiftUI

// MARK: - File Description
// Provides the user interface for application settings.
// Includes language selection, tracking preferences, data management, and version information.

struct SettingsView: View {
    @ObservedObject var tracker: KeyTracker
    @EnvironmentObject var prefs: AppPreferences
    @State private var selectedLanguage: String = "_system"
    @State private var showRestart = false
    @State private var showConfirm = false
    @State private var launchAtLoginError: String?

    var body: some View {
        Form {
            // General Section
            Section {
                Picker(LocalizedStringKey("section_language"), selection: $selectedLanguage) {
                    Text(LocalizedStringKey("lang_system")).tag("_system")
                    Text(LocalizedStringKey("lang_en")).tag("en")
                    Text(LocalizedStringKey("lang_zh_hans")).tag("zh-Hans")
                }
                Picker(
                    LocalizedStringKey("picker_number_display"),
                    selection: $prefs.menuBarNumberDisplayMode
                ) {
                    Text(LocalizedStringKey("number_display_full"))
                        .tag(MenuBarNumberDisplayMode.full)
                    Text(LocalizedStringKey("number_display_compact"))
                        .tag(MenuBarNumberDisplayMode.compact)
                }
                Text(LocalizedStringKey("desc_number_display"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Toggle(
                    LocalizedStringKey("toggle_launch_at_login"),
                    isOn: Binding(
                        get: { prefs.launchAtLogin },
                        set: { enabled in
                            do {
                                try prefs.setLaunchAtLogin(enabled)
                            } catch {
                                launchAtLoginError = error.localizedDescription
                            }
                        }
                    )
                )
            } header: {
                Label(LocalizedStringKey("section_general"), systemImage: "gearshape")
            }

            // Tracking Section
            Section {
                Toggle(LocalizedStringKey("toggle_decrement_backspace"), isOn: $prefs.decrementOnBackspace)
                Text(LocalizedStringKey("desc_decrement_backspace"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label(LocalizedStringKey("section_tracking"), systemImage: "keyboard")
            }

            // Data Section
            Section {
                Text(LocalizedStringKey("privacy_summary"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    VStack(alignment: .leading) {
                        Text(LocalizedStringKey("desc_clear_all"))
                        Text(LocalizedStringKey("subtitle_manage_data_privacy"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(LocalizedStringKey("action_wipe_data")) {
                        showConfirm = true
                    }
                }
            } header: {
                Label(LocalizedStringKey("section_data"), systemImage: "externaldrive")
            }

            // About Section
            Section {
                HStack {
                    Text(LocalizedStringKey("label_version"))
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label(LocalizedStringKey("section_about"), systemImage: "info.circle")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .frame(width: 500, height: 450)
        .onAppear {
            selectedLanguage = prefs.language
        }
        .onChange(of: selectedLanguage) { newValue in
            if newValue != prefs.language { showRestart = true }
        }
        .alert(LocalizedStringKey("alert_confirm_wipe_title"), isPresented: $showConfirm) {
            Button(LocalizedStringKey("action_cancel"), role: .cancel) {}
            Button(LocalizedStringKey("action_clear"), role: .destructive) { tracker.clearAllData() }
        } message: {
            Text(LocalizedStringKey("alert_confirm_wipe_message"))
        }
        .alert(LocalizedStringKey("alert_restart_title"), isPresented: $showRestart) {
            Button(LocalizedStringKey("restart_later"), role: .cancel) {
                selectedLanguage = prefs.language
            }
            Button(LocalizedStringKey("restart_now")) {
                prefs.language = selectedLanguage
                RestartHelper.relaunch()
            }
        } message: {
            Text(LocalizedStringKey("alert_restart_message"))
        }
        .alert(
            LocalizedStringKey("launch_at_login_error_title"),
            isPresented: Binding(
                get: { launchAtLoginError != nil },
                set: { if !$0 { launchAtLoginError = nil } }
            )
        ) {
            Button(LocalizedStringKey("action_ok"), role: .cancel) {}
        } message: {
            Text(launchAtLoginError ?? "")
        }
    }
}
