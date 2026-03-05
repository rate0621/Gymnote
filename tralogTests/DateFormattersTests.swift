//
//  DateFormattersTests.swift
//  tralogTests
//
//  DateFormatters のキャッシュ済みフォーマッターをテスト
//

import Foundation
import Testing
@testable import tralog

struct DateFormattersTests {

    /// テスト用の固定日付を生成
    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return components.date!
    }

    @Test func fullDate_format() {
        let date = makeDate(year: 2026, month: 3, day: 4)
        let result = DateFormatters.fullDate.string(from: date)
        #expect(result == "2026年3月4日")
    }

    @Test func yearMonth_format() {
        let date = makeDate(year: 2026, month: 12, day: 15)
        let result = DateFormatters.yearMonth.string(from: date)
        #expect(result == "2026年12月")
    }

    @Test func dayRecord_format() {
        let date = makeDate(year: 2026, month: 1, day: 9)
        let result = DateFormatters.dayRecord.string(from: date)
        #expect(result == "1月9日の記録")
    }

    @Test func formatters_areCached() {
        // 同じインスタンスが返されることを確認
        let f1 = DateFormatters.fullDate
        let f2 = DateFormatters.fullDate
        #expect(f1 === f2)
    }
}
