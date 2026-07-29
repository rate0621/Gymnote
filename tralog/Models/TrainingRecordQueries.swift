//
//  TrainingRecordQueries.swift
//  tralog
//
//  Core Dataへのワンショットクエリ集（監視不要なため@FetchRequestは使わない）
//

import CoreData

enum TrainingRecordQueries {

    // MARK: - 記録

    /// 指定メニューの直近1件の記録を取得する
    static func latestRecord(forMenu name: String, in context: NSManagedObjectContext) -> TrainingRecord? {
        let request = NSFetchRequest<TrainingRecord>(entityName: "TrainingRecord")
        request.predicate = NSPredicate(format: "menuName == %@", name)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrainingRecord.date, ascending: false)]
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("直近記録の取得に失敗しました: \(error)")
            return nil
        }
    }

    /// メニュー名ごとの最終実施日を取得する
    static func latestDatesByMenuName(in context: NSManagedObjectContext) -> [String: Date] {
        let request = NSFetchRequest<TrainingRecord>(entityName: "TrainingRecord")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrainingRecord.date, ascending: false)]

        do {
            let records = try context.fetch(request)
            // date降順なので、メニュー名の初出がそのまま最終実施日になる
            return records.reduce(into: [String: Date]()) { result, record in
                guard let name = record.menuName, let date = record.date else { return }
                if result[name] == nil {
                    result[name] = date
                }
            }
        } catch {
            print("最終実施日の取得に失敗しました: \(error)")
            return [:]
        }
    }

    // MARK: - メモ

    /// 指定日のメモを取得する（1日1件）
    static func memo(for date: Date, in context: NSManagedObjectContext) -> DailyMemo? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

        let request = NSFetchRequest<DailyMemo>(entityName: "DailyMemo")
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("メモの取得に失敗しました: \(error)")
            return nil
        }
    }

    /// 指定日のメモを保存する（既存があれば更新、なければ新規作成）
    static func upsertMemo(_ text: String, for date: Date, in context: NSManagedObjectContext) throws {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let existing = memo(for: date, in: context)
        let target = existing ?? DailyMemo(context: context)

        if existing == nil {
            target.id = UUID()
        }
        target.date = startOfDay
        target.memo = text

        try context.save()
    }
}

// MARK: - 種目選択時のプリセット値

/// 種目選択時にPickerへ流し込む初期値
struct MenuPresetValues {
    let value1: Double
    let value2: Double
    let value3: Int
}

extension TrainingRecordQueries {
    /// 種目選択時の初期値を決める
    /// 優先順位: ①直近記録の値（入力タイプが一致する場合のみ） → ②種目デフォルト値
    static func presetValues(for item: TrainingMenuItem, in context: NSManagedObjectContext) -> MenuPresetValues {
        if let latest = latestRecord(forMenu: item.name, in: context),
           latest.inputType == item.inputType.rawValue {
            return MenuPresetValues(
                value1: latest.value1,
                value2: latest.value2,
                value3: Int(latest.value3)
            )
        }

        return MenuPresetValues(
            value1: item.effectiveValue1Default,
            value2: item.inputType.value2Default,
            value3: item.inputType.value3Default
        )
    }
}
