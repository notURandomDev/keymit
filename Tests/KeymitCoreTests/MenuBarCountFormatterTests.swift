import XCTest
@testable import KeymitCore

// MARK: - File Description
// Verifies the exact and compact number formats used in the menu bar.
final class MenuBarCountFormatterTests: XCTestCase {
    func testFullModePreservesExactCounts() {
        XCTAssertEqual(MenuBarCountFormatter.string(for: 0, mode: .full), "0")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 8_399, mode: .full), "8399")
    }

    func testCompactModePreservesCountsBelowOneThousand() {
        XCTAssertEqual(MenuBarCountFormatter.string(for: 0, mode: .compact), "0")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 8, mode: .compact), "8")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 999, mode: .compact), "999")
    }

    func testCompactModeTruncatesCountsToWholeThousands() {
        XCTAssertEqual(MenuBarCountFormatter.string(for: 1_000, mode: .compact), "1K")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 8_399, mode: .compact), "8K")
        XCTAssertEqual(MenuBarCountFormatter.string(for: 10_999, mode: .compact), "10K")
    }
}
