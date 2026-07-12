import AppKit
import ApplicationServices
import SwiftUI
// MARK: - File Description
// Tracks global keystrokes, aggregates per-app statistics, and manages local persistence.
enum TrackingState: Equatable {
    case active
    case permissionRequired
    case unavailable
}

final class KeyTracker: ObservableObject {
    @Published private(set) var totalKeystrokes = 0
    @Published private(set) var currentApp = NSLocalizedString("unknown_application", comment: "")
    @Published private(set) var appStats: [String: Int] = [:]
    @Published private(set) var dailyHistory: [String: DailyStats] = [:]
    @Published private(set) var trackingState: TrackingState = .permissionRequired

    private enum PersistenceKey {
        static let total = "totalKey"
        static let apps = "appStats"
        static let history = "dailyHistory"
    }

    private let prefs: AppPreferences
    private var appBundleIDByName: [String: String] = [:]
    private var iconCache: [String: NSImage] = [:]
    private var observerTokens: [NSObjectProtocol] = []
    private var autosaveTimer: DispatchSourceTimer?
    private var permissionTimer: DispatchSourceTimer?
    private var dirty = false
    private var saveCounter = 0
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var eventTapRunLoop: CFRunLoop?

    private let blockedKeyCodes: Set<Int> = Set([51, 57, 117] + Array(122...135))

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var todayKeystrokes: Int {
        dailyHistory[dateKey(for: Date())]?.totalKeystrokes ?? 0
    }

    init(prefs: AppPreferences) {
        self.prefs = prefs
        loadData()
        setupWorkspaceObserver()
        setupLifecycleObservers()
        setupAutosave()
        startTracking(promptForPermission: true)
    }

    deinit {
        saveData(force: true)
        stopTracking()
        autosaveTimer?.cancel()
        permissionTimer?.cancel()
        observerTokens.forEach {
            NotificationCenter.default.removeObserver($0)
            NSWorkspace.shared.notificationCenter.removeObserver($0)
        }
    }

    func requestAccessibilityPermission() {
        startTracking(promptForPermission: true)
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    func startTracking(promptForPermission: Bool = false) {
        guard eventTap == nil else {
            trackingState = .active
            return
        }

        guard isAccessibilityTrusted(prompt: promptForPermission) else {
            trackingState = .permissionRequired
            startPermissionMonitor()
            return
        }

        permissionTimer?.cancel()
        permissionTimer = nil

        let eventMask = CGEventMask(1) << CGEventType.keyDown.rawValue
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, type, event, userInfo in
                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let tracker = Unmanaged<KeyTracker>.fromOpaque(userInfo).takeUnretainedValue()

                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    tracker.reenableEventTap()
                } else if type == .keyDown {
                    tracker.handleKeyPress(event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            trackingState = .unavailable
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        eventTapRunLoop = CFRunLoopGetMain()
        if let source = runLoopSource, let runLoop = eventTapRunLoop {
            CFRunLoopAddSource(runLoop, source, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        trackingState = .active
    }

    func stopTracking() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource, let runLoop = eventTapRunLoop {
            CFRunLoopRemoveSource(runLoop, source, .commonModes)
        }
        runLoopSource = nil
        eventTapRunLoop = nil
        eventTap = nil
    }

    func appIcon(for name: String) -> NSImage {
        let cacheKey = appBundleIDByName[name] ?? name
        if let cached = iconCache[cacheKey] { return cached }

        if let bundleID = appBundleIDByName[name],
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return cacheIcon(NSWorkspace.shared.icon(forFile: url.path), for: cacheKey)
        }
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }),
           let url = app.bundleURL {
            return cacheIcon(NSWorkspace.shared.icon(forFile: url.path), for: cacheKey)
        }

        let fallback = NSImage(named: NSImage.applicationIconName)
            ?? NSImage(size: NSSize(width: 32, height: 32))
        return cacheIcon(fallback, for: cacheKey)
    }

    func clearAllData() {
        var store = statisticsStore
        store.reset()
        apply(store)
        iconCache.removeAll()
        dirty = false
        saveCounter = 0

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: PersistenceKey.total)
        defaults.removeObject(forKey: PersistenceKey.apps)
        defaults.removeObject(forKey: PersistenceKey.history)
    }

    private var statisticsStore: StatisticsStore {
        StatisticsStore(
            totalKeystrokes: totalKeystrokes,
            appStats: appStats,
            dailyHistory: dailyHistory
        )
    }

    private func apply(_ store: StatisticsStore) {
        totalKeystrokes = store.totalKeystrokes
        appStats = store.appStats
        dailyHistory = store.dailyHistory
    }

    private func setupWorkspaceObserver() {
        updateCurrentApplication(NSWorkspace.shared.frontmostApplication)
        let token = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.updateCurrentApplication(app)
        }
        observerTokens.append(token)
    }

    private func setupLifecycleObservers() {
        let center = NotificationCenter.default
        observerTokens.append(center.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.saveData(force: true)
        })
        observerTokens.append(center.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.objectWillChange.send()
        })
        observerTokens.append(center.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self, self.eventTap == nil else { return }
            self.startTracking()
        })
    }

    private func updateCurrentApplication(_ app: NSRunningApplication?) {
        guard let app, let name = app.localizedName, !name.isEmpty else { return }
        currentApp = name
        if let bundleID = app.bundleIdentifier {
            appBundleIDByName[name] = bundleID
        }
    }

    private func handleKeyPress(_ event: CGEvent) {
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        let app = currentApp
        let date = dateKey(for: Date())

        if keyCode == 51 && prefs.decrementOnBackspace {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                var store = self.statisticsStore
                guard store.removeKeystroke(app: app, date: date) else { return }
                self.apply(store)
                self.markDirty(saveThreshold: 20)
            }
            return
        }
        guard shouldCount(event) else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            var store = self.statisticsStore
            store.recordKeystroke(app: app, date: date)
            self.apply(store)
            self.markDirty(saveThreshold: 100)
        }
    }

    private func shouldCount(_ event: CGEvent) -> Bool {
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        guard !blockedKeyCodes.contains(keyCode), let nativeEvent = NSEvent(cgEvent: event) else {
            return false
        }
        let modifiers = nativeEvent.modifierFlags
        guard !modifiers.contains(.command),
              !modifiers.contains(.control),
              !modifiers.contains(.option) else {
            return false
        }
        return !(nativeEvent.charactersIgnoringModifiers?.isEmpty ?? true)
    }

    private func reenableEventTap() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: true)
        DispatchQueue.main.async { [weak self] in
            self?.trackingState = .active
        }
    }

    private func isAccessibilityTrusted(prompt: Bool) -> Bool {
        guard prompt else { return AXIsProcessTrusted() }
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
        return AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
    }

    private func startPermissionMonitor() {
        guard permissionTimer == nil else { return }
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            guard let self, AXIsProcessTrusted() else { return }
            self.startTracking()
        }
        timer.resume()
        permissionTimer = timer
    }

    private func setupAutosave() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in self?.saveData() }
        timer.resume()
        autosaveTimer = timer
    }

    private func markDirty(saveThreshold: Int) {
        dirty = true
        saveCounter += 1
        if saveCounter >= saveThreshold {
            saveData()
        }
    }

    private func saveData(force: Bool = false) {
        guard force || dirty else { return }
        do {
            let encoder = JSONEncoder()
            let defaults = UserDefaults.standard
            defaults.set(totalKeystrokes, forKey: PersistenceKey.total)
            defaults.set(try encoder.encode(appStats), forKey: PersistenceKey.apps)
            defaults.set(try encoder.encode(dailyHistory), forKey: PersistenceKey.history)
            dirty = false
            saveCounter = 0
        } catch {
            NSLog("Keymit failed to save statistics: %@", error.localizedDescription)
        }
    }

    private func loadData() {
        let defaults = UserDefaults.standard
        let decoder = JSONDecoder()
        let apps = defaults.data(forKey: PersistenceKey.apps)
            .flatMap { try? decoder.decode([String: Int].self, from: $0) } ?? [:]

        var history: [String: DailyStats] = [:]
        if let data = defaults.data(forKey: PersistenceKey.history) {
            if let decoded = try? decoder.decode([String: DailyStats].self, from: data) {
                history = decoded
            } else if let legacy = try? decoder.decode([String: Int].self, from: data) {
                history = legacy.reduce(into: [:]) { result, entry in
                    result[entry.key] = DailyStats(
                        date: entry.key,
                        totalKeystrokes: max(0, entry.value),
                        appBreakdown: [:]
                    )
                }
                dirty = true
            }
        }

        apply(StatisticsStore(
            totalKeystrokes: defaults.integer(forKey: PersistenceKey.total),
            appStats: apps,
            dailyHistory: history
        ))
    }

    private func dateKey(for date: Date) -> String {
        dateFormatter.string(from: date)
    }

    @discardableResult
    private func cacheIcon(_ image: NSImage, for key: String) -> NSImage {
        let resized = NSImage(size: NSSize(width: 48, height: 48))
        resized.lockFocus()
        image.draw(
            in: NSRect(origin: .zero, size: resized.size),
            from: NSRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1
        )
        resized.unlockFocus()
        if iconCache.count >= 128, let oldestKey = iconCache.keys.first {
            iconCache.removeValue(forKey: oldestKey)
        }
        iconCache[key] = resized
        return resized
    }
}
