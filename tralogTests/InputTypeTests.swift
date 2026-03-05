//
//  InputTypeTests.swift
//  tralogTests
//
//  InputType の各種プロパティ・フォーマットをテスト
//

import Testing
@testable import tralog

struct InputTypeTests {

    // MARK: - formatRecord

    @Test func formatRecord_weightReps() {
        let result = InputType.weightReps.formatRecord(value1: 60.0, value2: 10.0)
        #expect(result == "60.0kg × 10回")
    }

    @Test func formatRecord_weightReps_decimal() {
        let result = InputType.weightReps.formatRecord(value1: 22.5, value2: 8.0)
        #expect(result == "22.5kg × 8回")
    }

    @Test func formatRecord_timeOnly() {
        let result = InputType.timeOnly.formatRecord(value1: 30.0, value2: 0.0)
        #expect(result == "30秒")
    }

    @Test func formatRecord_repsOnly() {
        let result = InputType.repsOnly.formatRecord(value1: 15.0, value2: 0.0)
        #expect(result == "15回")
    }

    @Test func formatRecord_inclineSpeedTime() {
        let result = InputType.inclineSpeedTime.formatRecord(value1: 3.5, value2: 8.0, value3: 20)
        #expect(result == "3.5% / 8.0km/h / 20分")
    }

    @Test func formatRecord_levelTime() {
        let result = InputType.levelTime.formatRecord(value1: 5.0, value2: 20.0)
        #expect(result == "Lv5 / 20分")
    }

    @Test func formatRecord_distanceTime() {
        let result = InputType.distanceTime.formatRecord(value1: 5.5, value2: 30.0)
        #expect(result == "5.5km / 30分")
    }

    // MARK: - formatPickerValue1

    @Test func formatPickerValue1_decimal() {
        #expect(InputType.weightReps.formatPickerValue1(60.5) == "60.5")
        #expect(InputType.inclineSpeedTime.formatPickerValue1(3.5) == "3.5")
        #expect(InputType.distanceTime.formatPickerValue1(10.0) == "10.0")
    }

    @Test func formatPickerValue1_integer() {
        #expect(InputType.timeOnly.formatPickerValue1(30.0) == "30")
        #expect(InputType.repsOnly.formatPickerValue1(15.0) == "15")
        #expect(InputType.levelTime.formatPickerValue1(5.0) == "5")
    }

    // MARK: - formatPickerValue2

    @Test func formatPickerValue2_inclineSpeedTime_decimal() {
        #expect(InputType.inclineSpeedTime.formatPickerValue2(8.5) == "8.5")
    }

    @Test func formatPickerValue2_others_integer() {
        #expect(InputType.weightReps.formatPickerValue2(10.0) == "10")
        #expect(InputType.levelTime.formatPickerValue2(20.0) == "20")
        #expect(InputType.distanceTime.formatPickerValue2(30.0) == "30")
    }

    // MARK: - ラベル・単位

    @Test func labels_weightReps() {
        let t = InputType.weightReps
        #expect(t.value1Label == "重量")
        #expect(t.value1Unit == "kg")
        #expect(t.value2Label == "回数")
        #expect(t.value2Unit == "回")
        #expect(t.value3Label == nil)
        #expect(t.value3Unit == nil)
    }

    @Test func labels_timeOnly() {
        let t = InputType.timeOnly
        #expect(t.value1Label == "時間")
        #expect(t.value1Unit == "秒")
        #expect(t.value2Label == nil)
        #expect(t.value2Unit == nil)
    }

    @Test func labels_inclineSpeedTime() {
        let t = InputType.inclineSpeedTime
        #expect(t.value1Label == "傾斜")
        #expect(t.value2Label == "速度")
        #expect(t.value3Label == "時間")
        #expect(t.value3Unit == "分")
    }

    // MARK: - デフォルト値

    @Test func defaults_weightReps() {
        #expect(InputType.weightReps.value1Default == 10.0)
        #expect(InputType.weightReps.value2Default == 15.0)
        #expect(InputType.weightReps.value3Default == 0)
    }

    @Test func defaults_inclineSpeedTime() {
        #expect(InputType.inclineSpeedTime.value1Default == 1.0)
        #expect(InputType.inclineSpeedTime.value2Default == 8.0)
        #expect(InputType.inclineSpeedTime.value3Default == 20)
    }

    // MARK: - 選択肢

    @Test func options_weightReps_value1_range() {
        let opts = InputType.weightReps.value1Options
        #expect(opts.first == 0.0)
        #expect(opts.last == 100.0)
        #expect(opts.contains(22.5))
    }

    @Test func options_timeOnly_value2_empty() {
        #expect(InputType.timeOnly.value2Options.isEmpty)
        #expect(InputType.repsOnly.value2Options.isEmpty)
    }

    @Test func options_inclineSpeedTime_value3() {
        let opts = InputType.inclineSpeedTime.value3Options
        #expect(opts.first == 1)
        #expect(opts.last == 60)
        #expect(opts.count == 60)
    }

    @Test func options_others_value3_empty() {
        #expect(InputType.weightReps.value3Options.isEmpty)
        #expect(InputType.timeOnly.value3Options.isEmpty)
        #expect(InputType.levelTime.value3Options.isEmpty)
    }

    // MARK: - rawValue

    @Test func rawValue_roundtrip() {
        for inputType in [InputType.weightReps, .timeOnly, .repsOnly, .inclineSpeedTime, .levelTime, .distanceTime] {
            #expect(InputType(rawValue: inputType.rawValue) == inputType)
        }
    }
}
