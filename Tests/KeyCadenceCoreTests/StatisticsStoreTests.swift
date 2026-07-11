import XCTest
@testable import KeyCadenceCore

final class StatisticsStoreTests: XCTestCase {
    func testRecordingKeepsLifetimeAndDailyStatsInSync() {
        var store = StatisticsStore()

        store.recordKeystroke(app: "Editor", date: "2026-07-11")
        store.recordKeystroke(app: "Editor", date: "2026-07-11")
        store.recordKeystroke(app: "Browser", date: "2026-07-12")

        XCTAssertEqual(store.totalKeystrokes, 3)
        XCTAssertEqual(store.appStats, ["Editor": 2, "Browser": 1])
        XCTAssertEqual(store.dailyHistory["2026-07-11"]?.totalKeystrokes, 2)
        XCTAssertEqual(store.dailyHistory["2026-07-12"]?.appBreakdown, ["Browser": 1])
    }

    func testBackspaceUpdatesTheVisibleDailyStats() {
        var store = StatisticsStore()
        store.recordKeystroke(app: "Editor", date: "2026-07-11")

        XCTAssertTrue(store.removeKeystroke(app: "Editor", date: "2026-07-11"))
        XCTAssertEqual(store.totalKeystrokes, 0)
        XCTAssertEqual(store.appStats, [:])
        XCTAssertEqual(store.dailyHistory["2026-07-11"]?.totalKeystrokes, 0)
        XCTAssertEqual(store.dailyHistory["2026-07-11"]?.appBreakdown, [:])
    }

    func testBackspaceDoesNotRemoveAnotherAppsKeystroke() {
        var store = StatisticsStore()
        store.recordKeystroke(app: "Editor", date: "2026-07-11")

        XCTAssertFalse(store.removeKeystroke(app: "Browser", date: "2026-07-11"))
        XCTAssertEqual(store.totalKeystrokes, 1)
        XCTAssertEqual(store.dailyHistory["2026-07-11"]?.totalKeystrokes, 1)
    }

    func testInitializationSanitizesCorruptNegativeValues() {
        let store = StatisticsStore(
            totalKeystrokes: -4,
            appStats: ["Editor": -2, "Browser": 3],
            dailyHistory: [
                "2026-07-11": DailyStats(
                    date: "wrong-date",
                    totalKeystrokes: -1,
                    appBreakdown: ["Editor": -5]
                )
            ]
        )

        XCTAssertEqual(store.totalKeystrokes, 0)
        XCTAssertEqual(store.appStats, ["Browser": 3])
        XCTAssertEqual(store.dailyHistory["2026-07-11"]?.date, "2026-07-11")
        XCTAssertEqual(store.dailyHistory["2026-07-11"]?.totalKeystrokes, 0)
    }

    func testResetClearsOnlyStatisticsState() {
        var store = StatisticsStore()
        store.recordKeystroke(app: "Editor", date: "2026-07-11")

        store.reset()

        XCTAssertEqual(store, StatisticsStore())
    }
}
