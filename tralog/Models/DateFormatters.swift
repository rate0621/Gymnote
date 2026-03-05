//
//  DateFormatters.swift
//  tralog
//
//  キャッシュ済みDateFormatterを提供
//

import Foundation

enum DateFormatters {
    /// "yyyy年M月d日"
    static let fullDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月d日"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    /// "yyyy年M月"
    static let yearMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()

    /// "M月d日の記録"
    static let dayRecord: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M月d日の記録"
        f.locale = Locale(identifier: "ja_JP")
        return f
    }()
}
