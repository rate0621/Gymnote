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
    // グループに含まれる記録の実体（date降順）
    let records: [TrainingRecord]

    /// FetchedResultsからグループ化した記録を生成
    /// 呼び出し元はdate降順でフェッチしている前提（recordsの並びもそれに従う）
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
                    latestDate: max(recordDate, existing.latestDate),
                    records: existing.records + [record]
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
                    latestDate: recordDate,
                    records: [record]
                )
            }
        }

        return Array(dict.values).sorted { $0.latestDate > $1.latestDate }
    }
}

/// メニュー単位でまとめた記録（1メニュー＝1カード）
struct MenuGroupedRecord: Identifiable {
    let menuName: String
    let bodyPart: String
    let inputType: InputType
    // カードの並び順用（そのメニューの最新記録日時）
    let latestDate: Date
    // 値単位の行。カード内は時系列昇順（古い順＝実施順）
    let lines: [GroupedRecord]

    var id: String { menuName }

    /// 値単位のグループをメニュー名でまとめ直す
    /// カード同士はlatestDate降順、カード内のlinesはlatestDate昇順（実施順）
    static func group(from records: FetchedResults<TrainingRecord>) -> [MenuGroupedRecord] {
        let lines = GroupedRecord.group(from: records)

        // 出現順（＝latestDate降順）を保ったままメニュー名でまとめる
        var order: [String] = []
        var dict: [String: [GroupedRecord]] = [:]

        for line in lines {
            if dict[line.menuName] == nil {
                order.append(line.menuName)
                dict[line.menuName] = [line]
            } else {
                dict[line.menuName]?.append(line)
            }
        }

        return order.compactMap { menuName -> MenuGroupedRecord? in
            guard let group = dict[menuName], let first = group.first else { return nil }
            return MenuGroupedRecord(
                menuName: menuName,
                bodyPart: first.bodyPart,
                inputType: first.inputType,
                latestDate: group.map(\.latestDate).max() ?? first.latestDate,
                lines: group.sorted { $0.latestDate < $1.latestDate }
            )
        }
        .sorted { $0.latestDate > $1.latestDate }
    }
}
