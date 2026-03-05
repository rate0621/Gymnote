//
//  UserProfileDataTests.swift
//  tralogTests
//
//  Gender・TrainingGoal のテスト
//

import Testing
@testable import tralog

struct UserProfileDataTests {

    // MARK: - Gender

    @Test func gender_allCases() {
        #expect(Gender.allCases.count == 3)
    }

    @Test func gender_rawValues() {
        #expect(Gender.male.rawValue == "男性")
        #expect(Gender.female.rawValue == "女性")
        #expect(Gender.other.rawValue == "その他")
    }

    // MARK: - TrainingGoal

    @Test func trainingGoal_allCases() {
        #expect(TrainingGoal.allCases.count == 5)
    }

    @Test func trainingGoal_rawValues() {
        #expect(TrainingGoal.muscleGain.rawValue == "筋肥大")
        #expect(TrainingGoal.weightLoss.rawValue == "減量")
        #expect(TrainingGoal.maintenance.rawValue == "健康維持")
        #expect(TrainingGoal.strength.rawValue == "筋力アップ")
        #expect(TrainingGoal.endurance.rawValue == "持久力向上")
    }

    @Test func trainingGoal_descriptions_notEmpty() {
        for goal in TrainingGoal.allCases {
            #expect(!goal.description.isEmpty)
        }
    }
}
