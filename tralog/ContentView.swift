//
//  ContentView.swift
//  tralog
//
//  Created by rate on 2025/12/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // 今日の記録を取得
    @FetchRequest private var todayRecords: FetchedResults<TrainingRecord>

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
            ScrollView {
                VStack(spacing: 20) {
                    // メニュー選択エリア（タップでシート表示）
                    Button {
                        isShowingMenuSheet = true
                    } label: {
                        HStack {
                            if let menuItem = selectedMenuItem, let part = selectedBodyPart {
                                Text(part.rawValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(4)
                                Text(menuItem.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                            } else {
                                Text("メニューを選択")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // 入力Picker（メニューのInputTypeに応じて動的に変化）
                    if let menuItem = selectedMenuItem {
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

                    // 今日の記録
                    let grouped = GroupedRecord.group(from: todayRecords)
                    if !grouped.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("今日の記録")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(grouped, id: \.key) { group in
                                Button {
                                    selectFromRecord(group)
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
                        .padding(.top, 20)
                    }

                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
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
            .sheet(isPresented: $isShowingMenuSheet) {
                MenuSelectSheet(
                    selectedBodyPart: $selectedBodyPart,
                    selectedMenuItem: $selectedMenuItem
                )
            }
            .sheet(isPresented: $isShowingProfileSheet) {
                ProfileEditView()
            }
            .onChange(of: selectedMenuItem) { _, newItem in
                if isRestoringFromRecord {
                    isRestoringFromRecord = false
                    return
                }
                if let item = newItem {
                    selectedValue1 = item.inputType.value1Default
                    selectedValue2 = item.inputType.value2Default
                    selectedValue3 = item.inputType.value3Default
                }
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
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
