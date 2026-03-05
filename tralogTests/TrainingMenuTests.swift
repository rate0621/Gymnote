//
//  TrainingMenuTests.swift
//  tralogTests
//
//  TrainingMenuItem・BodyPart のテスト
//

import Testing
@testable import tralog

struct TrainingMenuTests {

    // MARK: - BodyPart

    @Test func bodyPart_allCases() {
        #expect(BodyPart.allCases.count == 4)
        #expect(BodyPart.allCases.contains(.upperBody))
        #expect(BodyPart.allCases.contains(.lowerBody))
        #expect(BodyPart.allCases.contains(.core))
        #expect(BodyPart.allCases.contains(.cardio))
    }

    @Test func bodyPart_rawValues() {
        #expect(BodyPart.upperBody.rawValue == "上半身")
        #expect(BodyPart.lowerBody.rawValue == "下半身")
        #expect(BodyPart.core.rawValue == "体幹")
        #expect(BodyPart.cardio.rawValue == "有酸素運動")
    }

    // MARK: - メニュー一覧

    @Test func menus_upperBody_notEmpty() {
        let menus = BodyPart.upperBody.menus
        #expect(!menus.isEmpty)
        #expect(menus.contains(where: { $0.name == "ベンチプレス" }))
        #expect(menus.contains(where: { $0.name == "懸垂" }))
    }

    @Test func menus_upperBody_inputTypes() {
        let menus = BodyPart.upperBody.menus
        // 懸垂と腕立て伏せはrepsOnly
        let chinUp = menus.first(where: { $0.name == "懸垂" })
        #expect(chinUp?.inputType == .repsOnly)
        // ベンチプレスはweightReps
        let bench = menus.first(where: { $0.name == "ベンチプレス" })
        #expect(bench?.inputType == .weightReps)
    }

    @Test func menus_lowerBody_notEmpty() {
        let menus = BodyPart.lowerBody.menus
        #expect(!menus.isEmpty)
        #expect(menus.contains(where: { $0.name == "スクワット" }))
        #expect(menus.contains(where: { $0.name == "デッドリフト" }))
    }

    @Test func menus_core_containsTimeAndReps() {
        let menus = BodyPart.core.menus
        // プランクはtimeOnly
        let plank = menus.first(where: { $0.name == "プランク" })
        #expect(plank?.inputType == .timeOnly)
        // クランチはrepsOnly
        let crunch = menus.first(where: { $0.name == "クランチ" })
        #expect(crunch?.inputType == .repsOnly)
    }

    @Test func menus_cardio_variousInputTypes() {
        let menus = BodyPart.cardio.menus
        // トレッドミルはinclineSpeedTime
        let treadmill = menus.first(where: { $0.name == "トレッドミル" })
        #expect(treadmill?.inputType == .inclineSpeedTime)
        // バイクはlevelTime
        let bike = menus.first(where: { $0.name == "バイク" })
        #expect(bike?.inputType == .levelTime)
        // ウォーキングはdistanceTime
        let walking = menus.first(where: { $0.name == "ウォーキング" })
        #expect(walking?.inputType == .distanceTime)
    }

    // MARK: - TrainingMenuItem Equatable

    @Test func menuItem_equality() {
        let a = TrainingMenuItem(name: "ベンチプレス", inputType: .weightReps)
        let b = TrainingMenuItem(name: "ベンチプレス", inputType: .weightReps)
        #expect(a == b)
    }

    @Test func menuItem_inequality_name() {
        let a = TrainingMenuItem(name: "ベンチプレス", inputType: .weightReps)
        let b = TrainingMenuItem(name: "スクワット", inputType: .weightReps)
        #expect(a != b)
    }

    @Test func menuItem_inequality_inputType() {
        let a = TrainingMenuItem(name: "テスト", inputType: .weightReps)
        let b = TrainingMenuItem(name: "テスト", inputType: .repsOnly)
        #expect(a != b)
    }
}
