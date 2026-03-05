//
//  RecordAddSheet.swift
//  tralog
//
//  Created by rate on 2025/12/26.
//

import SwiftUI
import CoreData

struct RecordAddSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let targetDate: Date

    @State private var isShowingMenuSheet = false
    @State private var selectedBodyPart: BodyPart?
    @State private var selectedMenuItem: TrainingMenuItem?
    @State private var selectedValue1: Double = 20.0
    @State private var selectedValue2: Double = 10.0
    @State private var selectedValue3: Int = 20

    // エラー通知
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 日付表示
                    Text(DateFormatters.fullDate.string(from: targetDate))
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.top)

                    // メニュー選択エリア
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

                    // 入力Picker
                    if let menuItem = selectedMenuItem {
                        InputPickerView(
                            inputType: menuItem.inputType,
                            value1: $selectedValue1,
                            value2: $selectedValue2,
                            value3: $selectedValue3
                        )

                        // 登録ボタン
                        Button {
                            if saveRecord() {
                                dismiss()
                            }
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

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("記録を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isShowingMenuSheet) {
                MenuSelectSheet(
                    selectedBodyPart: $selectedBodyPart,
                    selectedMenuItem: $selectedMenuItem
                )
            }
            .onChange(of: selectedMenuItem) { _, newItem in
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

    @discardableResult
    private func saveRecord() -> Bool {
        guard let menuItem = selectedMenuItem,
              let part = selectedBodyPart else { return false }

        let newRecord = TrainingRecord(context: viewContext)
        newRecord.id = UUID()
        newRecord.date = targetDate
        newRecord.bodyPart = part.rawValue
        newRecord.menuName = menuItem.name
        newRecord.inputType = menuItem.inputType.rawValue
        newRecord.value1 = selectedValue1
        newRecord.value2 = selectedValue2
        newRecord.value3 = Int16(selectedValue3)

        do {
            try viewContext.save()
            return true
        } catch {
            errorMessage = "記録の保存に失敗しました"
            showingError = true
            return false
        }
    }
}

#Preview {
    RecordAddSheet(targetDate: Date())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
