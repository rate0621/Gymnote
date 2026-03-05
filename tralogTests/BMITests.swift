//
//  BMITests.swift
//  tralogTests
//
//  BMI計算・判定ロジックのテスト
//

import Foundation
import Testing
@testable import tralog

struct BMITests {

    // MARK: - calculateBMI

    @Test func bmi_normalCalculation() {
        // 170cm, 65kg → BMI ≒ 22.49
        let bmi = calculateBMI(weight: 65.0, height: 170.0)
        #expect(bmi != nil)
        #expect(abs(bmi! - 22.49) < 0.1)
    }

    @Test func bmi_heavyWeight() {
        // 160cm, 90kg → BMI = 90 / 2.56 ≒ 35.16
        let bmi = calculateBMI(weight: 90.0, height: 160.0)
        #expect(bmi != nil)
        #expect(abs(bmi! - 35.16) < 0.1)
    }

    @Test func bmi_zeroHeight_returnsNil() {
        #expect(calculateBMI(weight: 65.0, height: 0.0) == nil)
    }

    @Test func bmi_zeroWeight_returnsNil() {
        #expect(calculateBMI(weight: 0.0, height: 170.0) == nil)
    }

    @Test func bmi_negativeValues_returnsNil() {
        #expect(calculateBMI(weight: -10.0, height: 170.0) == nil)
        #expect(calculateBMI(weight: 65.0, height: -170.0) == nil)
    }

    // MARK: - bmiCategory

    @Test func category_underweight() {
        #expect(bmiCategory(17.0) == "低体重")
        #expect(bmiCategory(18.4) == "低体重")
    }

    @Test func category_normal() {
        #expect(bmiCategory(18.5) == "普通体重")
        #expect(bmiCategory(22.0) == "普通体重")
        #expect(bmiCategory(24.9) == "普通体重")
    }

    @Test func category_obese1() {
        #expect(bmiCategory(25.0) == "肥満(1度)")
        #expect(bmiCategory(29.9) == "肥満(1度)")
    }

    @Test func category_obese2() {
        #expect(bmiCategory(30.0) == "肥満(2度)")
        #expect(bmiCategory(34.9) == "肥満(2度)")
    }

    @Test func category_obese3() {
        #expect(bmiCategory(35.0) == "肥満(3度)")
        #expect(bmiCategory(39.9) == "肥満(3度)")
    }

    @Test func category_obese4() {
        #expect(bmiCategory(40.0) == "肥満(4度)")
        #expect(bmiCategory(50.0) == "肥満(4度)")
    }
}
