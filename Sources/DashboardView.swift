import SwiftUI
import AppKit

// MARK: - File Description
// Main dashboard interface displaying keystroke statistics.
// Shows total counts, activity heatmap, and per-application breakdown.

struct DashboardView: View {
    @ObservedObject var tracker: KeyTracker
    @EnvironmentObject var prefs: AppPreferences
    @State private var selectedDate: Date = Date()
    
    private var isTodaySelected: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    private var displayedCount: Int {
        if isTodaySelected {
            return tracker.todayKeystrokes
        } else {
            let dateString = dateFormatter.string(from: selectedDate)
            return tracker.dailyHistory[dateString]?.totalKeystrokes ?? 0
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    
    private var displayedApps: [String: Int]? {
        let dateString = dateFormatter.string(from: selectedDate)
        return tracker.dailyHistory[dateString]?.appBreakdown
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Total Keystrokes
            TotalStatsView(
                total: displayedCount,
                title: isTodaySelected ? NSLocalizedString("title_today_keystrokes", comment: "") : dateFormatter.string(from: selectedDate),
                showBackToToday: !isTodaySelected,
                onBackToToday: { selectedDate = Date() }
            )

            if tracker.trackingState != .active {
                TrackingStatusView(tracker: tracker)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
            
            Divider()
                .padding(.horizontal)
            
            // Activity: Heatmap
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(NSLocalizedString("label_activity", comment: ""), systemImage: "chart.xyaxis.line")
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal)
                
                HeatmapView(tracker: tracker, selectedDate: $selectedDate)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            
            Divider()
                .padding(.horizontal)
            
            // Apps List Header
            HStack {
                Label(NSLocalizedString("label_applications", comment: ""), systemImage: "app.dashed")
                    .font(.headline)
                    Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Apps List (Scrollable)
            ScrollView {
                if let stats = displayedApps, !stats.isEmpty {
                    let sortedStats = stats.sorted(by: { $0.value > $1.value })
                    LazyVStack(spacing: 0) {
                        ForEach(Array(sortedStats.enumerated()), id: \.element.key) { index, item in
                            let (app, count) = item
                            AppRow(appName: app, count: count, total: displayedCount, icon: tracker.appIcon(for: app))
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                            
                            if index < sortedStats.count - 1 {
                                Divider().padding(.leading, 56)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text(NSLocalizedString("label_no_activity", comment: ""))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .padding(.top, 40)
                }
            }
            
            // Footer
            Divider()
            HStack {
                Button(action: {
                    SettingsWindowManager.shared.show(with: tracker, prefs: prefs)
                }) {
                    Label(NSLocalizedString("action_settings", comment: ""), systemImage: "gearshape")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Label(NSLocalizedString("action_quit", comment: ""), systemImage: "power")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(width: 380, height: 700)
        .onAppear {
            // Ensure we show today's data if opened on a new day
            if !Calendar.current.isDateInToday(selectedDate) {
                selectedDate = Date()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            // Auto-switch to new day at midnight
            selectedDate = Date()
        }
    }
}

private struct TrackingStatusView: View {
    @ObservedObject var tracker: KeyTracker

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedStringKey("tracking_inactive_title"))
                    .font(.subheadline.weight(.semibold))
                Text(LocalizedStringKey("tracking_inactive_message"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(LocalizedStringKey("action_fix_permission")) {
                tracker.openAccessibilitySettings()
                tracker.requestAccessibilityPermission()
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct TotalStatsView: View {
    let total: Int
    let title: String
    let showBackToToday: Bool
    let onBackToToday: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if showBackToToday {
                        Button(action: onBackToToday) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.blue)
                        .help(NSLocalizedString("back_to_today", comment: ""))
                    }
                }
                
                Text("\(total)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            Spacer()
            Image(systemName: "keyboard")
                .font(.system(size: 40))
                .foregroundColor(.blue.opacity(0.8))
        }
        .padding(20)
    }
}

struct AppRow: View {
    let appName: String
    let count: Int
    let total: Int
    let icon: NSImage
    
    var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(appName)
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text("\(count)")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.primary)
                        
                        Text(String(format: "(%.1f%%)", percentage * 100))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.1))
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: max(0, g.size.width * percentage))
                    }
                }
                .frame(height: 4)
            }
        }
    }
}
