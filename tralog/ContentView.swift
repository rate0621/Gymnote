//
//  ContentView.swift
//  tralog
//
//  Created by rate on 2025/12/25.
//

import SwiftUI
import CoreData
import Combine

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.scenePhase) private var scenePhase

    // 今日の記録を取得
    @FetchRequest private var todayRecords: FetchedResults<TrainingRecord>

    // 現在表示している日（日付跨ぎの検知用）
    @State private var displayedDay: Date = Calendar.current.startOfDay(for: Date())

    // 入力状態
    @State private var isShowingMenuSheet = false
    @State private var isShowingProfileSheet = false
    @State private var selectedBodyPart: BodyPart?
    @State private var selectedMenuItem: TrainingMenuItem?
    @State private var selectedValue1: Double = 20.0
    @State private var selectedValue2: Double = 10.0
    @State private var selectedValue3: Int = 20

    // 記録からの復元中フラグ（onChangeでデフォルト値に上書きされないようにする）
    @State private var isRestoringFromRecord = false

    // 記録の編集
    @State private var recordToEdit: TrainingRecord?

    // トレーニング終了 → メモ入力
    @State private var showingFinishConfirm = false
    @State private var isShowingMemoSheet = false

    // エラー通知
    @State private var showingError = false
    @State private var errorMessage = ""

    init() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        _todayRecords = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \TrainingRecord.date, ascending: false)],
            predicate: NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate),
            animation: .default
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 入力エリアは上部に固定
                menuSelectButton

                if let menuItem = selectedMenuItem {
                    inputSection(for: menuItem)
                }

                // 今日の記録だけをスクロールさせる
                ScrollView {
                    todayRecordSection
                }
            }
            .padding(.top)
            .navigationTitle("Gymnote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingProfileSheet = true
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title3)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                finishTrainingButton
            }
            .sheet(isPresented: $isShowingMenuSheet) {
                MenuSelectSheet(
                    selectedBodyPart: $selectedBodyPart,
                    selectedMenuItem: $selectedMenuItem
                )
            }
            .sheet(isPresented: $isShowingProfileSheet) {
                ProfileEditView()
            }
            .sheet(item: $recordToEdit) { record in
                RecordEditSheet(record: record)
            }
            .sheet(isPresented: $isShowingMemoSheet) {
                DailyMemoSheet(date: Date())
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
            .onChange(of: selectedMenuItem) { _, newItem in
                if isRestoringFromRecord {
                    isRestoringFromRecord = false
                    return
                }
                if let item = newItem {
                    applyPreset(for: item)
                }
            }
            .alert("トレーニングを終了しますか？", isPresented: $showingFinishConfirm) {
                Button("OK") {
                    isShowingMemoSheet = true
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("今日のトレーニングメモを記録できます")
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - サブビュー

    // メニュー選択エリア（タップでシート表示）
    private var menuSelectButton: some View {
        Button {
            isShowingMenuSheet = true
        } label: {
            // 高さを固定して、メニュー名の長さや選択状態で下のエリアがガタつかないようにする
            HStack {
                if let menuItem = selectedMenuItem, let part = selectedBodyPart {
                    Text(part.rawValue)
                        .font(.caption)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                    Text(menuItem.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else {
                    Text("メニューを選択")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .frame(height: 32)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }

    // 入力Picker（メニューのInputTypeに応じて動的に変化）と登録ボタン
    private func inputSection(for menuItem: TrainingMenuItem) -> some View {
        VStack(spacing: 20) {
            InputPickerView(
                inputType: menuItem.inputType,
                value1: $selectedValue1,
                value2: $selectedValue2,
                value3: $selectedValue3
            )

            // 登録ボタン
            Button {
                saveRecord()
            } label: {
                Text("登録")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }

    // 今日の記録（同じメニューは1カードにまとめる）
    private var groupedTodayRecords: [MenuGroupedRecord] {
        MenuGroupedRecord.group(from: todayRecords)
    }

    // 今日の記録
    @ViewBuilder
    private var todayRecordSection: some View {
        if !groupedTodayRecords.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("今日の記録")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(groupedTodayRecords) { group in
                    recordCard(for: group)
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 20)
        }
    }

    // メニュー1件分のカード（ヘッダー＋値行）
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
                recordLine(for: line)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    // 値1行（本体タップ＝値の復元、鉛筆タップ＝編集シート。Buttonのネストを避けて並列に置く）
    private func recordLine(for line: GroupedRecord) -> some View {
        HStack(spacing: 8) {
            Button {
                selectFromRecord(line)
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
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                recordToEdit = line.records.first
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
    }

    // トレーニング終了ボタン（今日の記録が1件以上あるときだけ表示）
    @ViewBuilder
    private var finishTrainingButton: some View {
        if !todayRecords.isEmpty {
            Button {
                showingFinishConfirm = true
            } label: {
                HStack {
                    Image(systemName: "flag.checkered")
                    Text("トレーニング終了")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    // MARK: - アクション

    /// 日付が変わっていたら「今日の記録」と入力状態を今日基準に作り直す
    private func refreshIfDayChanged() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard today != displayedDay else { return }

        displayedDay = today

        // FetchRequestのpredicateを今日の範囲へ差し替える
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: today)!
        todayRecords.nsPredicate = NSPredicate(
            format: "date >= %@ AND date < %@",
            today as NSDate,
            endOfDay as NSDate
        )

        // 前日の入力状態をクリアする（selectedMenuItemがnilなのでapplyPresetは走らない）
        isRestoringFromRecord = false
        selectedMenuItem = nil
        selectedBodyPart = nil
    }

    /// 選択した種目の初期値をPickerへ反映する
    private func applyPreset(for item: TrainingMenuItem) {
        let preset = TrainingRecordQueries.presetValues(for: item, in: viewContext)
        selectedValue1 = preset.value1
        selectedValue2 = preset.value2
        selectedValue3 = preset.value3
    }

    /// 記録からメニューと値を復元する
    private func selectFromRecord(_ group: GroupedRecord) {
        // 部位を特定
        guard let bodyPart = BodyPart.allCases.first(where: { $0.rawValue == group.bodyPart }) else { return }

        // メニューを特定
        guard let menuItem = bodyPart.menus.first(where: { $0.name == group.menuName }) else { return }

        // 値を先にセット（onChangeでデフォルト値に上書きされないようにフラグを立てる）
        isRestoringFromRecord = true
        selectedValue1 = group.value1
        selectedValue2 = group.value2
        selectedValue3 = group.value3
        selectedBodyPart = bodyPart
        selectedMenuItem = menuItem
    }

    private func saveRecord() {
        guard let menuItem = selectedMenuItem,
              let part = selectedBodyPart else { return }

        withAnimation {
            let newRecord = TrainingRecord(context: viewContext)
            newRecord.id = UUID()
            newRecord.date = Date()
            newRecord.bodyPart = part.rawValue
            newRecord.menuName = menuItem.name
            newRecord.inputType = menuItem.inputType.rawValue
            newRecord.value1 = selectedValue1
            newRecord.value2 = selectedValue2
            newRecord.value3 = Int16(selectedValue3)

            do {
                try viewContext.save()
            } catch {
                errorMessage = "記録の保存に失敗しました"
                showingError = true
            }
        }
    }

}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
