//
//  InputPickerView.swift
//  tralog
//
//  入力タイプに応じたホイールPicker
//

import SwiftUI

struct InputPickerView: View {
    let inputType: InputType
    @Binding var value1: Double
    @Binding var value2: Double
    @Binding var value3: Int

    var body: some View {
        HStack(spacing: 0) {
            pickerColumn(
                label: inputType.value1Label,
                unit: inputType.value1Unit,
                selection: $value1,
                options: inputType.value1Options,
                format: { inputType.formatPickerValue1($0) }
            )

            if let label = inputType.value2Label, let unit = inputType.value2Unit {
                pickerColumn(
                    label: label,
                    unit: unit,
                    selection: $value2,
                    options: inputType.value2Options,
                    format: { inputType.formatPickerValue2($0) }
                )
            }

            if let label = inputType.value3Label, let unit = inputType.value3Unit {
                intPickerColumn(
                    label: label,
                    unit: unit,
                    selection: $value3,
                    options: inputType.value3Options
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    /// Double値のPickerカラム
    private func pickerColumn(
        label: String,
        unit: String,
        selection: Binding<Double>,
        options: [Double],
        format: @escaping (Double) -> String
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Picker(label, selection: selection) {
                ForEach(options, id: \.self) { value in
                    Text(format(value)).tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 120)
            .clipped()
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    /// Int値のPickerカラム
    private func intPickerColumn(
        label: String,
        unit: String,
        selection: Binding<Int>,
        options: [Int]
    ) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Picker(label, selection: selection) {
                ForEach(options, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80, height: 120)
            .clipped()
            Text(unit)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
