//
//  RecordEditSheet.swift
//  tralog
//
//  Created by rate on 2025/12/26.
//

import SwiftUI
import CoreData

struct RecordEditSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var record: TrainingRecord

    @State private var selectedValue1: Double = 20.0
    @State private var selectedValue2: Double = 10.0
    @State private var selectedValue3: Int = 20
    @State private var showingDeleteConfirm = false

    // エラー通知
    @State private var showingError = false
    @State private var errorMessage = ""

    private var inputType: InputType {
        InputType(rawValue: record.inputType ?? "") ?? .weightReps
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 日付とメニュー表示
                    VStack(alignment: .leading, spacing: 8) {
                        Text(DateFormatters.fullDate.string(from: record.date ?? Date()))
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Text(record.bodyPart ?? "")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                            Text(record.menuName ?? "")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // 入力Picker
                    InputPickerView(
                        inputType: inputType,
                        value1: $selectedValue1,
                        value2: $selectedValue2,
                        value3: $selectedValue3
                    )

                    // 保存ボタン
                    Button {
                        if saveChanges() {
                            dismiss()
                        }
                    } label: {
                        Text("保存")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    // 削除ボタン
                    Button {
                        showingDeleteConfirm = true
                    } label: {
                        Text("この記録を削除")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .navigationTitle("記録を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("削除の確認", isPresented: $showingDeleteConfirm) {
                Button("削除", role: .destructive) {
                    if deleteRecord() {
                        dismiss()
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この記録を削除してもよろしいですか？")
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                selectedValue1 = record.value1
                selectedValue2 = record.value2
                selectedValue3 = Int(record.value3)
            }
        }
    }

    @discardableResult
    private func saveChanges() -> Bool {
        record.value1 = selectedValue1
        record.value2 = selectedValue2
        record.value3 = Int16(selectedValue3)

        do {
            try viewContext.save()
            return true
        } catch {
            errorMessage = "記録の保存に失敗しました"
            showingError = true
            return false
        }
    }

    @discardableResult
    private func deleteRecord() -> Bool {
        viewContext.delete(record)

        do {
            try viewContext.save()
            return true
        } catch {
            errorMessage = "記録の削除に失敗しました"
            showingError = true
            return false
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let record = TrainingRecord(context: context)
    record.id = UUID()
    record.date = Date()
    record.bodyPart = "上半身"
    record.menuName = "ベンチプレス"
    record.inputType = "weightReps"
    record.value1 = 60.0
    record.value2 = 10.0
    record.value3 = 0

    return RecordEditSheet(record: record)
        .environment(\.managedObjectContext, context)
}
