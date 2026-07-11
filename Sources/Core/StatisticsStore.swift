import Foundation

struct DailyStats: Codable, Equatable, Identifiable {
    var id: String { date }
    let date: String
    var totalKeystrokes: Int
    var appBreakdown: [String: Int]
}

struct StatisticsStore: Equatable {
    private(set) var totalKeystrokes: Int
    private(set) var appStats: [String: Int]
    private(set) var dailyHistory: [String: DailyStats]

    init(
        totalKeystrokes: Int = 0,
        appStats: [String: Int] = [:],
        dailyHistory: [String: DailyStats] = [:]
    ) {
        self.totalKeystrokes = max(0, totalKeystrokes)
        self.appStats = appStats.filter { $0.value > 0 }
        self.dailyHistory = dailyHistory.reduce(into: [:]) { result, entry in
            let apps = entry.value.appBreakdown.filter { $0.value > 0 }
            result[entry.key] = DailyStats(
                date: entry.key,
                totalKeystrokes: max(0, entry.value.totalKeystrokes),
                appBreakdown: apps
            )
        }
    }

    mutating func recordKeystroke(app: String, date: String) {
        totalKeystrokes += 1
        appStats[app, default: 0] += 1

        var daily = dailyHistory[date] ?? DailyStats(
            date: date,
            totalKeystrokes: 0,
            appBreakdown: [:]
        )
        daily.totalKeystrokes += 1
        daily.appBreakdown[app, default: 0] += 1
        dailyHistory[date] = daily
    }

    @discardableResult
    mutating func removeKeystroke(app: String, date: String) -> Bool {
        guard var daily = dailyHistory[date],
              let dailyAppCount = daily.appBreakdown[app],
              dailyAppCount > 0 else {
            return false
        }

        daily.totalKeystrokes = max(0, daily.totalKeystrokes - 1)
        setDecrementedValue(in: &daily.appBreakdown, key: app)
        dailyHistory[date] = daily

        totalKeystrokes = max(0, totalKeystrokes - 1)
        setDecrementedValue(in: &appStats, key: app)
        return true
    }

    mutating func reset() {
        totalKeystrokes = 0
        appStats.removeAll()
        dailyHistory.removeAll()
    }

    private func setDecrementedValue(in values: inout [String: Int], key: String) {
        let nextValue = max(0, values[key, default: 0] - 1)
        if nextValue == 0 {
            values.removeValue(forKey: key)
        } else {
            values[key] = nextValue
        }
    }
}
