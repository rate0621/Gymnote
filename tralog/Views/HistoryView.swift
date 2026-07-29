//
//  HistoryView.swift
//  tralog
//
//  Created by rate on 2025/12/26.
//

import SwiftUI
import CoreData
import Combine

struct HistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase

    // カレンダー状態
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Date()

    // 現在表示している日（日付跨ぎの検知用）
    @State private var displayedDay: Date = Calendar.current.startOfDay(for: Date())

    // シート表示
    @State private var isShowingAddSheet = false
    @State private var recordToEdit: TrainingRecord?
    @State private var isShowingMemoSheet = false

    // 選択日のメモ
    @State private var selectedDateMemo: DailyMemo?

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
        NavigationStack {
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
            .sheet(isPresented: $isShowingMemoSheet, onDismiss: reloadSelectedDateMemo) {
                DailyMemoSheet(date: selectedDate)
            }
            .onAppear {
                reloadSelectedDateMemo()
            }
            .onChange(of: selectedDate) { _, newDate in
                updateSelectedDatePredicate(for: newDate)
                reloadSelectedDateMemo()
            }
            .onChange(of: displayedMonth) { _, newMonth in
                updateMonthPredicate(for: newMonth)
            }
            .onChange(of: scenePhase) { _, newPhase in
                // バックグラウンドで日を跨いだ場合に復帰時点で作り直す
                if newPhase == .active {
                    refreshIfDayChanged()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
                // フォアグラウンドのまま0時を跨いだ場合（通知はバックグラウンドスレッドで届く）
                refreshIfDayChanged()
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

            Text(DateFormatters.yearMonth.string(from: displayedMonth))
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
        let grouped = MenuGroupedRecord.group(from: selectedDateRecords)

        return VStack(alignment: .leading, spacing: 12) {
            Text(DateFormatters.dayRecord.string(from: selectedDate))
                .font(.headline)
                .padding(.horizontal)

            // その日のメモ
            memoCard

            if grouped.isEmpty {
                Text("この日の記録はありません")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(grouped) { group in
                    recordCard(for: group)
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

    // メニュー1件分のカード（ヘッダー＋値行。値行タップで編集シート）
    private func recordCard(for group: MenuGroupedRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // ヘッダー（メニュー名 + 部位）
            VStack(alignment: .leading, spacing: 2) {
                Text(group.menuName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                Text(group.bodyPart)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // 値行（実施順）
            ForEach(group.lines, id: \.key) { line in
                Button {
                    recordToEdit = line.records.first
                } label: {
                    HStack(spacing: 8) {
                        Text(line.inputType.formatRecord(value1: line.value1, value2: line.value2, value3: line.value3))
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        if line.setCount > 1 {
                            Text("×\(line.setCount)セット")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // 選択日のメモカード（タップで編集）
    @ViewBuilder
    private var memoCard: some View {
        if let text = selectedDateMemo?.memo, !text.isEmpty {
            Button {
                isShowingMemoSheet = true
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "note.text")
                        Text("メモ")
                            .font(.caption)
                        Spacer()
                        Image(systemName: "pencil")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)

                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    // 日付が変わっていたら選択日と表示月を今日基準に戻す
    private func refreshIfDayChanged() {
        let today = calendar.startOfDay(for: Date())
        guard today != displayedDay else { return }

        displayedDay = today

        // selectedDate / displayedMonth のonChangeがpredicate更新とメモ再取得を担う
        let now = Date()
        selectedDate = now
        displayedMonth = now
    }

    // 選択日のメモを取得し直す
    private func reloadSelectedDateMemo() {
        selectedDateMemo = TrainingRecordQueries.memo(for: selectedDate, in: viewContext)
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
}

#Preview {
    HistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
