//
//  HistoryView.swift
//  tralog
//
//  Created by rate on 2025/12/26.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // カレンダー状態
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()

    // シート表示
    @State private var isShowingAddSheet = false
    @State private var recordToEdit: TrainingRecord?

    // 選択日の記録を取得
    @FetchRequest private var selectedDateRecords: FetchedResults<TrainingRecord>

    // 表示月の全記録を取得（マーキング用）
    @FetchRequest private var monthRecords: FetchedResults<TrainingRecord>

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    init() {
        let today = Date()
        let calendar = Calendar.current

        // 今日の記録
        let startOfDay = calendar.startOfDay(for: today)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        _selectedDateRecords = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \TrainingRecord.date, ascending: false)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate),
            animation: .default
        )

        // 今月の記録
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        _monthRecords = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \TrainingRecord.date, ascending: false)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", startOfMonth as NSDate, endOfMonth as NSDate),
            animation: .default
        )
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // カレンダーヘッダー
                    calendarHeader

                    // 曜日ラベル
                    weekdayHeader

                    // カレンダーグリッド
                    calendarGrid

                    Divider()
                        .padding(.horizontal)

                    // 選択日の記録
                    selectedDateSection
                }
                .padding(.top)
            }
            .navigationTitle("確認する")
            .sheet(isPresented: $isShowingAddSheet) {
                RecordAddSheet(targetDate: selectedDate)
            }
            .sheet(item: $recordToEdit) { record in
                RecordEditSheet(record: record)
            }
            .onChange(of: selectedDate) { _, newDate in
                updateSelectedDatePredicate(for: newDate)
            }
            .onChange(of: displayedMonth) { _, newMonth in
                updateMonthPredicate(for: newMonth)
            }
        }
    }

    // カレンダーヘッダー（月移動）
    private var calendarHeader: some View {
        HStack {
            Button {
                moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .padding(.horizontal)
            }

            Spacer()

            Text(monthYearString(from: displayedMonth))
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Button {
                moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }

    // 曜日ヘッダー
    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(day == "日" ? .red : (day == "土" ? .blue : .secondary))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
    }

    // カレンダーグリッド
    private var calendarGrid: some View {
        let days = daysInMonth()

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { day in
                if let day = day {
                    dayCell(for: day)
                } else {
                    Text("")
                        .frame(height: 40)
                }
            }
        }
        .padding(.horizontal)
    }

    // 日付セル
    private func dayCell(for date: Date) -> some View {
        let dayNumber = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let hasRecords = datesWithRecords.contains(calendar.startOfDay(for: date))

        return Button {
            selectedDate = date
        } label: {
            ZStack {
                // 選択状態の背景
                if isSelected {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                } else if isToday {
                    Circle()
                        .stroke(Color.blue, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }

                VStack(spacing: 2) {
                    Text("\(dayNumber)")
                        .font(.subheadline)
                        .foregroundColor(isSelected ? .white : .primary)

                    // 記録マーカー
                    if hasRecords && !isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                    } else if hasRecords && isSelected {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    // 選択日のセクション
    private var selectedDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(dateString(from: selectedDate))
                .font(.headline)
                .padding(.horizontal)

            if groupedRecords.isEmpty {
                Text("この日の記録はありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(groupedRecords, id: \.key) { group in
                    Button {
                        // 編集シートを表示（最初のレコードを選択）
                        recordToEdit = selectedDateRecords.first(where: {
                            $0.menuName == group.menuName &&
                            $0.value1 == group.value1 &&
                            $0.value2 == group.value2 &&
                            $0.value3 == group.value3
                        })
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(group.menuName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                Text(group.bodyPart)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if group.setCount > 1 {
                                Text("\(group.setCount)セット")
                                    .font(.caption)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                            }
                            Text(group.inputType.formatRecord(value1: group.value1, value2: group.value2, value3: group.value3))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)
                }
            }

            // 記録を追加ボタン
            Button {
                isShowingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("記録を追加")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    // グループ化された記録
    private var groupedRecords: [GroupedRecord] {
        var dict: [String: GroupedRecord] = [:]
        for record in selectedDateRecords {
            let key = "\(record.menuName ?? "")-\(record.value1)-\(record.value2)-\(record.value3)"
            let recordDate = record.date ?? Date.distantPast
            let recordInputType = InputType(rawValue: record.inputType ?? "") ?? .weightReps

            if var existing = dict[key] {
                existing.setCount += 1
                if recordDate > existing.latestDate {
                    existing.latestDate = recordDate
                }
                dict[key] = existing
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

    // 記録がある日のセット
    private var datesWithRecords: Set<Date> {
        Set(monthRecords.compactMap { record in
            guard let date = record.date else { return nil }
            return calendar.startOfDay(for: date)
        })
    }

    // 月内の日付配列を生成
    private func daysInMonth() -> [Date?] {
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)),
              let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }

        return days
    }

    // 月を移動
    private func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    // 選択日のpredicateを更新
    private func updateSelectedDatePredicate(for date: Date) {
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        selectedDateRecords.nsPredicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfDay as NSDate,
            endOfDay as NSDate
        )
    }

    // 月のpredicateを更新
    private func updateMonthPredicate(for date: Date) {
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        monthRecords.nsPredicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            startOfMonth as NSDate,
            endOfMonth as NSDate
        )
    }

    // 日付フォーマット
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日の記録"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
