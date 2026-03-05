//
//  GroupedRecord.swift
//  tralog
//
//  同じメニュー・値でグループ化した記録
//

import SwiftUI
import CoreData

struct GroupedRecord {
    let key: String
    let menuName: String
    let bodyPart: String
    let inputType: InputType
    let value1: Double
    let value2: Double
    let value3: Int
    let setCount: Int
    let latestDate: Date

    /// FetchedResultsからグループ化した記録を生成
    static func group(from records: FetchedResults<TrainingRecord>) -> [GroupedRecord] {
        var dict: [String: GroupedRecord] = [:]

        for record in records {
            let key = "\(record.menuName ?? "")-\(record.value1)-\(record.value2)-\(record.value3)"
            let recordDate = record.date ?? Date.distantPast
            let recordInputType = InputType(rawValue: record.inputType ?? "") ?? .weightReps

            if let existing = dict[key] {
                dict[key] = GroupedRecord(
                    key: key,
                    menuName: existing.menuName,
                    bodyPart: existing.bodyPart,
                    inputType: existing.inputType,
                    value1: existing.value1,
                    value2: existing.value2,
                    value3: existing.value3,
                    setCount: existing.setCount + 1,
                    latestDate: max(recordDate, existing.latestDate)
                )
            } else {
                dict[key] = GroupedRecord(
                    key: key,
                    menuName: record.menuName ?? "",
                    bodyPart: record.bodyPart ?? "",
                    inputType: recordInputType,
                    value1: record.value1,
                    value2: record.value2,
                    value3: Int(record.value3),
                    setCount: 1,
                    latestDate: recordDate
                )
            }
        }

        return Array(dict.values).sorted { $0.latestDate > $1.latestDate }
    }
}
