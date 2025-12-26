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

    private var inputType: InputType {
        InputType(rawValue: record.inputType ?? "") ?? .weightReps
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 日付とメニュー表示
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dateString(from: record.date ?? Date()))
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
                    inputPickerView(for: inputType)

                    // 保存ボタン
                    Button {
                        saveChanges()
                        dismiss()
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
                    deleteRecord()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この記録を削除してもよろしいですか？")
            }
            .onAppear {
                // 既存の値を読み込み
                selectedValue1 = record.value1
                selectedValue2 = record.value2
                selectedValue3 = Int(record.value3)
            }
        }
    }

    @ViewBuilder
    private func inputPickerView(for inputType: InputType) -> some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(inputType.value1Label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker(inputType.value1Label, selection: $selectedValue1) {
                    ForEach(inputType.value1Options, id: \.self) { value in
                        Text(formatValue1(value, for: inputType)).tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(width: 80, height: 120)
                .clipped()
                Text(inputType.value1Unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if inputType.value2Label != nil {
                VStack(spacing: 4) {
                    Text(inputType.value2Label!)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker(inputType.value2Label!, selection: $selectedValue2) {
                        ForEach(inputType.value2Options, id: \.self) { value in
                            Text(formatValue2(value, for: inputType)).tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 120)
                    .clipped()
                    Text(inputType.value2Unit!)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if inputType.value3Label != nil {
                VStack(spacing: 4) {
                    Text(inputType.value3Label!)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker(inputType.value3Label!, selection: $selectedValue3) {
                        ForEach(inputType.value3Options, id: \.self) { value in
                            Text("\(value)").tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80, height: 120)
                    .clipped()
                    Text(inputType.value3Unit!)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func formatValue1(_ value: Double, for inputType: InputType) -> String {
        switch inputType {
        case .weightReps, .inclineSpeedTime, .distanceTime:
            return String(format: "%.1f", value)
        case .timeOnly, .repsOnly, .levelTime:
            return "\(Int(value))"
        }
    }

    private func formatValue2(_ value: Double, for inputType: InputType) -> String {
        switch inputType {
        case .inclineSpeedTime:
            return String(format: "%.1f", value)
        default:
            return "\(Int(value))"
        }
    }

    private func saveChanges() {
        record.value1 = selectedValue1
        record.value2 = selectedValue2
        record.value3 = Int16(selectedValue3)

        do {
            try viewContext.save()
        } catch {
            print("Error saving: \(error)")
        }
    }

    private func deleteRecord() {
        viewContext.delete(record)

        do {
            try viewContext.save()
        } catch {
            print("Error deleting: \(error)")
        }
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
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
