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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 日付表示
                    Text(dateString(from: targetDate))
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
                        inputPickerView(for: menuItem.inputType)

                        // 登録ボタン
                        Button {
                            saveRecord()
                            dismiss()
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

    private func saveRecord() {
        guard let menuItem = selectedMenuItem,
              let part = selectedBodyPart else { return }

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
        } catch {
            print("Error saving: \(error)")
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
    RecordAddSheet(targetDate: Date())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
