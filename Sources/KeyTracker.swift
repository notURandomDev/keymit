import SwiftUI
import ApplicationServices
import Cocoa

// MARK: - File Description
// Core tracking logic for global keystroke monitoring.
// Captures keyboard events, aggregates per-application statistics, and manages data persistence.

struct DailyStats: Codable, Identifiable {
    var id: String { date }
    let date: String // YYYY-MM-DD
    var totalKeystrokes: Int
    var appBreakdown: [String: Int]
}

class KeyTracker: ObservableObject {
    private let prefs: AppPreferences
    @Published var totalKeystrokes: Int = 0
    @Published var currentApp: String = "Unknown"
    @Published var appStats: [String: Int] = [:]
    @Published var dailyHistory: [String: DailyStats] = [:] // YYYY-MM-DD -> DailyStats
    private var appBundleIdByName: [String: String] = [:]
    private var iconCache: [String: NSImage] = [:]
    
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    // MARK: - Computed Properties
    
    var todayKeystrokes: Int {
        let today = dateFormatter.string(from: Date())
        return dailyHistory[today]?.totalKeystrokes ?? 0
    }
    
    // Keys excluded from typing count: Backspace, Forward Delete, Caps Lock, F1–F12
    private let blockedKeyCodes: Set<Int> = Set([51, 117, 57] + Array(122...135))
    private var autosaveTimer: DispatchSourceTimer?
    private var dirty: Bool = false
    private var saveCounter: Int = 0
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    init(prefs: AppPreferences) {
        self.prefs = prefs
        self.loadData()                 // Load persisted totals and per-app breakdown
        self.setupWorkspaceObserver()   // Watch frontmost app activation to tag keystrokes
        self.startTracking()            // Install CGEventTap for global keyDown events
        self.setupAutosave()            // Periodic flush to reduce write pressure
        NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.saveData(force: true)
        }
        
        // Refresh UI on day change to reset daily counters
        NotificationCenter.default.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    // Observe frontmost application changes
    private func setupWorkspaceObserver() {
        // Initialize current app info at launch
        if let app = NSWorkspace.shared.frontmostApplication {
            if let name = app.localizedName { self.currentApp = name }
            if let bid = app.bundleIdentifier, let name = app.localizedName { appBundleIdByName[name] = bid }
        }
        
        // React to app activation changes
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
               let name = app.localizedName {
                self.currentApp = name
                if let bid = app.bundleIdentifier { self.appBundleIdByName[name] = bid }
            }
        }
    }
    
    deinit {
        stopTracking()
    }

    // Stop global keyboard tracking and clean up resources
    func stopTracking() {
        if let eventTap = eventTap {
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
                self.runLoopSource = nil
            }
            // CGEventTap doesn't need explicit release if we just let go of the CFMachPort, 
            // but disabling it is good practice.
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }
    }
    
    // Start global keyboard tracking
    func startTracking() {
        // Prevent double start
        if eventTap != nil { return }
        
        // Check Accessibility permission (prompt only when not trusted)
        if !AXIsProcessTrusted() {
            let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue()
            let options = [key: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
            print("Please grant Accessibility permission in System Settings.")
            return
        }
        
        // Only listen to keyDown events for typing
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        // Create event tap bound to the current run loop
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                if let observer = refcon {
                    let mySelf = Unmanaged<KeyTracker>.fromOpaque(observer).takeUnretainedValue()
                    mySelf.handleKeyPress(event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    // Apply filtering, then update counters and schedule persistence
    private func handleKeyPress(_ event: CGEvent) {
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        if keyCode == 51 && prefs.decrementOnBackspace {
            DispatchQueue.main.async {
                if self.totalKeystrokes > 0 { self.totalKeystrokes -= 1 }
                let current = self.appStats[self.currentApp, default: 0]
                self.appStats[self.currentApp] = max(0, current - 1)
                self.dirty = true
                self.saveCounter += 1
                if self.saveCounter >= 20 { self.saveData() }
            }
            return
        }
        guard shouldCount(event) else { return }
        DispatchQueue.main.async {
            self.totalKeystrokes += 1
            self.appStats[self.currentApp, default: 0] += 1
            
            let today = self.dateFormatter.string(from: Date())
            var stats = self.dailyHistory[today] ?? DailyStats(date: today, totalKeystrokes: 0, appBreakdown: [:])
            stats.totalKeystrokes += 1
            stats.appBreakdown[self.currentApp, default: 0] += 1
            self.dailyHistory[today] = stats
            
            self.dirty = true
            self.saveCounter += 1
            if self.saveCounter >= 100 { self.saveData() }
        }
    }

    // Return true for typing-like keys; exclude function/control and empty events
    private func shouldCount(_ event: CGEvent) -> Bool {
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        if blockedKeyCodes.contains(keyCode) { return false }
        if let ne = NSEvent(cgEvent: event) {
            let f = ne.modifierFlags
            if f.contains(.command) || f.contains(.control) || f.contains(.option) { return false }
            if let s = ne.charactersIgnoringModifiers, s.isEmpty { return false }
        }
        return true
    }

    // Resolve app icon via bundle identifier or running app URL; cache results
    func appIcon(for name: String) -> NSImage {
        let cacheKey = appBundleIdByName[name] ?? name
        if let cached = iconCache[cacheKey] { return cached }
        if let bid = appBundleIdByName[name],
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
            let img = NSWorkspace.shared.icon(forFile: url.path)
            cacheIcon(img, for: cacheKey)
            return img
        }
        if let running = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name }),
           let url = running.bundleURL {
            let img = NSWorkspace.shared.icon(forFile: url.path)
            cacheIcon(img, for: cacheKey)
            return img
        }
        if let path = NSWorkspace.shared.fullPath(forApplication: name) {
            let img = NSWorkspace.shared.icon(forFile: path)
            cacheIcon(img, for: cacheKey)
            return img
        }
        let fallback = NSImage(named: NSImage.applicationIconName) ?? NSImage(size: NSSize(width: 32, height: 32))
        cacheIcon(fallback, for: cacheKey)
        return fallback
    }
    
    private func cacheIcon(_ image: NSImage, for key: String) {
        // Resize to a reasonable small size (e.g. 48x48) to save memory
        let resized = resize(image: image, to: NSSize(width: 48, height: 48))
        
        // Simple eviction policy: random removal if over limit
        if iconCache.count >= 128 {
            // Remove a random element
            iconCache.remove(at: iconCache.startIndex)
        }
        iconCache[key] = resized
    }
    
    private func resize(image: NSImage, to newSize: NSSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
    
    // Simple persistence using UserDefaults with throttling
    private func saveData(force: Bool = false) {
        guard force || dirty else { return }
        UserDefaults.standard.set(totalKeystrokes, forKey: "totalKey")
        if let data = try? JSONEncoder().encode(appStats) {
            UserDefaults.standard.set(data, forKey: "appStats")
        }
        if let historyData = try? JSONEncoder().encode(dailyHistory) {
            UserDefaults.standard.set(historyData, forKey: "dailyHistory")
        }
        dirty = false
        saveCounter = 0
    }
    
    private func loadData() {
        self.totalKeystrokes = UserDefaults.standard.integer(forKey: "totalKey")
        if let data = UserDefaults.standard.data(forKey: "appStats"),
           let stats = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.appStats = stats
        }
        if let historyData = UserDefaults.standard.data(forKey: "dailyHistory") {
            // Try decoding new format first
            if let history = try? JSONDecoder().decode([String: DailyStats].self, from: historyData) {
                self.dailyHistory = history
            } 
            // Fallback to legacy format migration
            else if let legacyHistory = try? JSONDecoder().decode([String: Int].self, from: historyData) {
                self.dailyHistory = legacyHistory.mapValues { count in
                    DailyStats(date: "", totalKeystrokes: count, appBreakdown: [:])
                }
                // Fix date strings in migrated objects since mapValues doesn't give us the key
                for (date, _) in legacyHistory {
                    self.dailyHistory[date]?.appBreakdown = [:] // Ensure init
                    // Re-create the struct with correct date
                    if let existing = self.dailyHistory[date] {
                        self.dailyHistory[date] = DailyStats(date: date, totalKeystrokes: existing.totalKeystrokes, appBreakdown: [:])
                    }
                }
            }
        }
    }

    func clearAllData() {
        totalKeystrokes = 0
        appStats = [:]
        dailyHistory = [:]
        iconCache = [:]
        if let domain = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: domain)
        }
        UserDefaults.standard.synchronize()
    }

    private func setupAutosave() {
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in self?.saveData() }
        timer.resume()
        autosaveTimer = timer
    }
}
