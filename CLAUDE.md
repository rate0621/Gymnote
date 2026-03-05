# tralog (Gymnote) - トレーニング記録アプリ

## プロジェクト概要
ジムでのトレーニング記録を管理するiOSネイティブアプリ。ホイールピッカーによる素早い入力とカレンダーでの振り返りが特徴。

## 技術スタック
- **言語**: Swift 5 / SwiftUI
- **データ**: Core Data (SQLite)
- **対象OS**: iOS 17+
- **外部依存**: なし（完全オフライン動作）

## ディレクトリ構成
```
tralog/
├── tralogApp.swift          # エントリーポイント
├── ContentView.swift         # メイン記録画面（今日の記録）
├── Persistence.swift         # Core Data スタック
├── Models/
│   ├── TrainingMenu.swift    # InputType enum, TrainingMenuItem, BodyPart
│   └── UserProfileData.swift # Gender, TrainingGoal, BMI計算
├── Views/
│   ├── MainTabView.swift     # タブ（記録する / 確認する）
│   ├── HistoryView.swift     # カレンダー + 日別記録一覧
│   ├── MenuSelectSheet.swift # 種目選択シート
│   ├── RecordAddSheet.swift  # 記録追加（過去日）
│   ├── RecordEditSheet.swift # 記録編集・削除
│   └── ProfileEditView.swift # プロフィール編集
└── tralog.xcdatamodeld/      # Core Data スキーマ
    └── TrainingRecord, UserProfile エンティティ
```

## Core Data エンティティ
- **TrainingRecord**: id, date, bodyPart, menuName, inputType, value1, value2, value3
- **UserProfile**: id, birthYear, gender, height, weight, goal, bodyFatPercentage, updatedAt

## 入力タイプ (InputType)
| タイプ | 用途 | 値 |
|--------|------|-----|
| weightReps | 重量×回数 | kg, 回 |
| timeOnly | 時間のみ | 秒 |
| repsOnly | 回数のみ | 回 |
| inclineSpeedTime | 傾斜×速度×時間 | %, km/h, 分 |
| levelTime | 負荷×時間 | Lv, 分 |
| distanceTime | 距離×時間 | km, 分 |

## ビルド
```bash
# Xcodeで開く
open tralog.xcodeproj
# ビルド（コマンドライン）
xcodebuild -project tralog.xcodeproj -scheme tralog -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## 既知の技術的負債
- `inputPickerView`, `formatValue1/2`, `groupedRecords` が ContentView, RecordAddSheet, RecordEditSheet で重複
- テストなし
- エラーハンドリングが `print()` のみ
- `NavigationView`（非推奨）を使用中 → `NavigationStack` に移行予定
