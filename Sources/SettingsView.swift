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

    var body: some View {
        Form {
            // General Section
            Section {
                Picker(LocalizedStringKey("section_language"), selection: $selectedLanguage) {
                    Text(LocalizedStringKey("lang_system")).tag("_system")
                    Text(LocalizedStringKey("lang_en")).tag("en")
                    Text(LocalizedStringKey("lang_zh_hans")).tag("zh-Hans")
                }
                Toggle(LocalizedStringKey("toggle_launch_at_login"), isOn: $prefs.launchAtLogin)
            } header: {
                Label("General", systemImage: "gearshape")
            }

            // Tracking Section
            Section {
                Toggle(LocalizedStringKey("toggle_decrement_backspace"), isOn: $prefs.decrementOnBackspace)
                Text(LocalizedStringKey("desc_decrement_backspace"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Tracking", systemImage: "keyboard")
            }

            // Data Section
            Section {
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
                Label("Data", systemImage: "externaldrive")
            }

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("About", systemImage: "info.circle")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.regularMaterial)
        .frame(width: 500, height: 450)
        .onAppear {
            selectedLanguage = prefs.language
        }
        .onChange(of: selectedLanguage) { _, newValue in
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
    }
}
