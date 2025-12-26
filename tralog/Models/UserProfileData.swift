//
//  UserProfileData.swift
//  tralog
//
//  Created by rate on 2025/12/25.
//

import Foundation

enum Gender: String, CaseIterable, Identifiable {
    case male = "男性"
    case female = "女性"
    case other = "その他"

    var id: String { rawValue }
}

enum TrainingGoal: String, CaseIterable, Identifiable {
    case muscleGain = "筋肥大"
    case weightLoss = "減量"
    case maintenance = "健康維持"
    case strength = "筋力アップ"
    case endurance = "持久力向上"

    var id: String { rawValue }

    var description: String {
        switch self {
        case .muscleGain: return "筋肉を大きくしたい"
        case .weightLoss: return "体重・体脂肪を減らしたい"
        case .maintenance: return "今の体型を維持したい"
        case .strength: return "重い重量を扱えるようになりたい"
        case .endurance: return "スタミナをつけたい"
        }
    }
}

// BMI計算
func calculateBMI(weight: Double, height: Double) -> Double? {
    guard height > 0, weight > 0 else { return nil }
    let heightInMeters = height / 100.0
    return weight / (heightInMeters * heightInMeters)
}

// BMI判定
func bmiCategory(_ bmi: Double) -> String {
    switch bmi {
    case ..<18.5: return "低体重"
    case 18.5..<25: return "普通体重"
    case 25..<30: return "肥満(1度)"
    case 30..<35: return "肥満(2度)"
    case 35..<40: return "肥満(3度)"
    default: return "肥満(4度)"
    }
}
