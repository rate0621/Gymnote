//
//  TrainingMenu.swift
//  tralog
//
//  Created by rate on 2025/12/25.
//

import Foundation

// 入力タイプ（トレーニングごとに異なる単位）
enum InputType: String {
    case weightReps       // 重量(kg) × 回数
    case timeOnly         // 時間(秒)のみ
    case repsOnly         // 回数のみ
    case inclineSpeedTime // 傾斜(%) × 速度(km/h) × 時間(分)
    case levelTime        // 負荷レベル × 時間(分)
    case distanceTime     // 距離(km) × 時間(分)

    var value1Label: String {
        switch self {
        case .weightReps: return "重量"
        case .timeOnly: return "時間"
        case .repsOnly: return "回数"
        case .inclineSpeedTime: return "傾斜"
        case .levelTime: return "負荷"
        case .distanceTime: return "距離"
        }
    }

    var value1Unit: String {
        switch self {
        case .weightReps: return "kg"
        case .timeOnly: return "秒"
        case .repsOnly: return "回"
        case .inclineSpeedTime: return "%"
        case .levelTime: return "Lv"
        case .distanceTime: return "km"
        }
    }

    var value2Label: String? {
        switch self {
        case .weightReps: return "回数"
        case .timeOnly: return nil
        case .repsOnly: return nil
        case .inclineSpeedTime: return "速度"
        case .levelTime: return "時間"
        case .distanceTime: return "時間"
        }
    }

    var value2Unit: String? {
        switch self {
        case .weightReps: return "回"
        case .timeOnly: return nil
        case .repsOnly: return nil
        case .inclineSpeedTime: return "km/h"
        case .levelTime: return "分"
        case .distanceTime: return "分"
        }
    }

    var value3Label: String? {
        switch self {
        case .inclineSpeedTime: return "時間"
        default: return nil
        }
    }

    var value3Unit: String? {
        switch self {
        case .inclineSpeedTime: return "分"
        default: return nil
        }
    }

    // value1の選択肢
    var value1Options: [Double] {
        switch self {
        case .weightReps:
            return stride(from: 0.0, through: 100.0, by: 0.5).map { $0 }  // 0〜100kg
        case .timeOnly:
            return stride(from: 5.0, through: 180.0, by: 5.0).map { $0 }  // 5秒〜3分
        case .repsOnly:
            return stride(from: 1.0, through: 50.0, by: 1.0).map { $0 }   // 1〜50回
        case .inclineSpeedTime:
            return stride(from: 0.0, through: 15.0, by: 0.5).map { $0 }   // 0〜15%
        case .levelTime:
            return stride(from: 1.0, through: 20.0, by: 1.0).map { $0 }   // レベル1〜20
        case .distanceTime:
            return stride(from: 0.0, through: 20.0, by: 0.5).map { $0 }   // 0〜20km
        }
    }

    // value2の選択肢
    var value2Options: [Double] {
        switch self {
        case .weightReps:
            return stride(from: 1.0, through: 30.0, by: 1.0).map { $0 }   // 1〜30回
        case .timeOnly, .repsOnly:
            return []
        case .inclineSpeedTime:
            return stride(from: 1.0, through: 15.0, by: 0.5).map { $0 }   // 1〜15 km/h
        case .levelTime:
            return stride(from: 1.0, through: 60.0, by: 1.0).map { $0 }   // 1〜60分
        case .distanceTime:
            return stride(from: 1.0, through: 90.0, by: 1.0).map { $0 }   // 1〜90分
        }
    }

    // value3の選択肢
    var value3Options: [Int] {
        switch self {
        case .inclineSpeedTime:
            return Array(1...60)      // 1〜60分
        default:
            return []
        }
    }

    var value1Default: Double {
        switch self {
        case .weightReps: return 10.0
        case .timeOnly: return 30.0
        case .repsOnly: return 10.0
        case .inclineSpeedTime: return 1.0
        case .levelTime: return 5.0
        case .distanceTime: return 5.0
        }
    }

    var value2Default: Double {
        switch self {
        case .weightReps: return 15.0
        case .timeOnly, .repsOnly: return 0.0
        case .inclineSpeedTime: return 8.0
        case .levelTime: return 20.0
        case .distanceTime: return 30.0
        }
    }

    var value3Default: Int {
        switch self {
        case .inclineSpeedTime: return 20
        default: return 0
        }
    }

    // 表示用フォーマット
    func formatRecord(value1: Double, value2: Double, value3: Int = 0) -> String {
        switch self {
        case .weightReps:
            return String(format: "%.1fkg × %d回", value1, Int(value2))
        case .timeOnly:
            return "\(Int(value1))秒"
        case .repsOnly:
            return "\(Int(value1))回"
        case .inclineSpeedTime:
            return String(format: "%.1f%% / %.1fkm/h / %d分", value1, value2, value3)
        case .levelTime:
            return "Lv\(Int(value1)) / \(Int(value2))分"
        case .distanceTime:
            return String(format: "%.1fkm / %d分", value1, Int(value2))
        }
    }
}

// Picker表示用フォーマット
extension InputType {
    func formatPickerValue1(_ value: Double) -> String {
        switch self {
        case .weightReps, .inclineSpeedTime, .distanceTime:
            return String(format: "%.1f", value)
        case .timeOnly, .repsOnly, .levelTime:
            return "\(Int(value))"
        }
    }

    func formatPickerValue2(_ value: Double) -> String {
        switch self {
        case .inclineSpeedTime:
            return String(format: "%.1f", value)
        default:
            return "\(Int(value))"
        }
    }
}

// トレーニングメニュー
struct TrainingMenuItem: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let inputType: InputType

    static func == (lhs: TrainingMenuItem, rhs: TrainingMenuItem) -> Bool {
        lhs.name == rhs.name && lhs.inputType == rhs.inputType
    }

    static func menus(for bodyPart: BodyPart) -> [TrainingMenuItem] {
        switch bodyPart {
        case .upperBody:
            return [
                TrainingMenuItem(name: "ダンベルフライ", inputType: .weightReps),
                TrainingMenuItem(name: "インクラインダンベルフライ", inputType: .weightReps),
                TrainingMenuItem(name: "ダンベルカール", inputType: .weightReps),
                TrainingMenuItem(name: "インクラインダンベルカール", inputType: .weightReps),
                TrainingMenuItem(name: "サイドレイズ", inputType: .weightReps),
                TrainingMenuItem(name: "トライセプスエクステンション", inputType: .weightReps),
                TrainingMenuItem(name: "ケーブルプッシュダウン", inputType: .weightReps),
                TrainingMenuItem(name: "ラットプルダウン", inputType: .weightReps),
                TrainingMenuItem(name: "ショルダープレス", inputType: .weightReps),
                TrainingMenuItem(name: "チェストプレス", inputType: .weightReps),
                TrainingMenuItem(name: "アブドミナルクランチ", inputType: .weightReps),
                TrainingMenuItem(name: "ベンチプレス", inputType: .weightReps),
                TrainingMenuItem(name: "懸垂", inputType: .repsOnly),
                TrainingMenuItem(name: "腕立て伏せ", inputType: .repsOnly),
            ]
        case .lowerBody:
            return [
                TrainingMenuItem(name: "スクワット", inputType: .weightReps),
                TrainingMenuItem(name: "レッグプレス", inputType: .weightReps),
                TrainingMenuItem(name: "アングルドレッグプレス", inputType: .weightReps),
                TrainingMenuItem(name: "レッグカール", inputType: .weightReps),
                TrainingMenuItem(name: "レッグエクステンション", inputType: .weightReps),
                TrainingMenuItem(name: "カーフレイズ", inputType: .weightReps),
                TrainingMenuItem(name: "ヒップスラスト", inputType: .weightReps),
                TrainingMenuItem(name: "ランジ", inputType: .weightReps),
                TrainingMenuItem(name: "デッドリフト", inputType: .weightReps),
            ]
        case .core:
            return [
                TrainingMenuItem(name: "プランク", inputType: .timeOnly),
                TrainingMenuItem(name: "サイドプランク", inputType: .timeOnly),
                TrainingMenuItem(name: "クランチ", inputType: .repsOnly),
                TrainingMenuItem(name: "レッグレイズ", inputType: .repsOnly),
                TrainingMenuItem(name: "バックエクステンション", inputType: .repsOnly),
                TrainingMenuItem(name: "アブローラー", inputType: .repsOnly),
                TrainingMenuItem(name: "ロシアンツイスト", inputType: .repsOnly),
                TrainingMenuItem(name: "ハンギングレッグレイズ", inputType: .repsOnly),
            ]
        case .cardio:
            return [
                TrainingMenuItem(name: "トレッドミル", inputType: .inclineSpeedTime),
                TrainingMenuItem(name: "バイク", inputType: .levelTime),
                TrainingMenuItem(name: "エリプティカル", inputType: .levelTime),
                TrainingMenuItem(name: "ローイング", inputType: .levelTime),
                TrainingMenuItem(name: "ステップマシン", inputType: .levelTime),
                TrainingMenuItem(name: "ウォーキング", inputType: .distanceTime),
                TrainingMenuItem(name: "ランニング（屋外）", inputType: .distanceTime),
                TrainingMenuItem(name: "縄跳び", inputType: .timeOnly),
            ]
        }
    }
}

enum BodyPart: String, CaseIterable, Identifiable {
    case upperBody = "上半身"
    case lowerBody = "下半身"
    case core = "体幹"
    case cardio = "有酸素運動"

    var id: String { rawValue }

    var menus: [TrainingMenuItem] {
        TrainingMenuItem.menus(for: self)
    }
}
