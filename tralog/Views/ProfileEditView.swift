//
//  ProfileEditView.swift
//  tralog
//
//  Created by rate on 2025/12/25.
//

import SwiftUI
import CoreData

struct ProfileEditView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfile.updatedAt, ascending: false)],
        animation: .default
    ) private var profiles: FetchedResults<UserProfile>

    // 入力状態
    @State private var birthYear: Int = 1990
    @State private var gender: Gender = .male
    @State private var heightText: String = "170.0"
    @State private var weightText: String = "65.0"
    @State private var selectedGoals: Set<TrainingGoal> = [.maintenance]
    @State private var bodyFatPercentage: String = ""

    // 年の選択肢（1940〜2030）
    private let yearOptions: [Int] = Array((1940...2030).reversed())

    // 入力値から数値を取得
    private var height: Double {
        Double(heightText) ?? 170.0
    }

    private var weight: Double {
        Double(weightText) ?? 65.0
    }

    // エラー通知
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // 基本情報
                Section(header: Text("基本情報")) {
                    // 生年
                    Picker("生年", selection		: $birthYear) {
                        ForEach(yearOptions, id: \.self) { year in
                            Text("\(String(year))年").tag(year)
                        }
                    }

                    // 性別
                    Picker("性別", selection: $gender) {
                        ForEach(Gender.allCases) { g in
                            Text(g.rawValue).tag(g)
                        }
                    }
                }

                // 体格
                Section(header: Text("体格")) {
                    // 身長
                    HStack {
                        Text("身長")
                        TextField("170.0", text: $heightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm")
                            .foregroundColor(.secondary)
                    }

                    // 体重
                    HStack {
                        Text("体重")
                        TextField("65.0", text: $weightText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                            .foregroundColor(.secondary)
                    }

                    // 体脂肪率（任意）
                    HStack {
                        Text("体脂肪率")
                        TextField("任意", text: $bodyFatPercentage)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("%")
                            .foregroundColor(.secondary)
                    }
                }

                // BMI（自動計算）
                Section(header: Text("BMI（自動計算）")) {
                    if let bmi = calculateBMI(weight: weight, height: height) {
                        HStack {
                            Text("BMI")
                            Spacer()
                            Text(String(format: "%.1f", bmi))
                                .fontWeight(.bold)
                            Text("(\(bmiCategory(bmi)))")
                                .foregroundColor(.secondary)
                        }
                    }

                    // 出典リンク
                    Link(destination: URL(string: "https://kennet.mhlw.go.jp/information/information/food/e-02-001")!) {
                        HStack {
                            Text("出典: 厚生労働省")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }

                // 目標（複数選択可能）
                Section(header: Text("トレーニングの目標（複数選択可）")) {
                    ForEach(TrainingGoal.allCases) { goal in
                        Button {
                            toggleGoal(goal)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(goal.rawValue)
                                        .foregroundColor(.primary)
                                    Text(goal.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedGoals.contains(goal) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .fontWeight(.bold)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        if saveProfile() {
                            dismiss()
                        }
                    }
                    .fontWeight(.bold)
                    .disabled(selectedGoals.isEmpty)
                }
            }
            .onAppear {
                loadExistingProfile()
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func toggleGoal(_ goal: TrainingGoal) {
        if selectedGoals.contains(goal) {
            selectedGoals.remove(goal)
        } else {
            selectedGoals.insert(goal)
        }
    }

    private func loadExistingProfile() {
        guard let profile = profiles.first else { return }

        birthYear = profile.birthYear >= 1940 ? Int(profile.birthYear) : 1990
        if let g = Gender(rawValue: profile.gender ?? "") {
            gender = g
        }
        heightText = profile.height > 0 ? String(format: "%.1f", profile.height) : "170.0"
        weightText = profile.weight > 0 ? String(format: "%.1f", profile.weight) : "65.0"

        // カンマ区切りの目標を復元
        if let goalString = profile.goal, !goalString.isEmpty {
            let goalStrings = goalString.split(separator: ",").map { String($0) }
            selectedGoals = Set(goalStrings.compactMap { TrainingGoal(rawValue: $0) })
        }

        if profile.bodyFatPercentage > 0 {
            bodyFatPercentage = String(format: "%.1f", profile.bodyFatPercentage)
        }
    }

    @discardableResult
    private func saveProfile() -> Bool {
        // 既存のプロフィールがあれば更新、なければ新規作成
        let profile = profiles.first ?? UserProfile(context: viewContext)

        if profile.id == nil {
            profile.id = UUID()
        }
        profile.birthYear = Int16(birthYear)
        profile.gender = gender.rawValue
        profile.height = height
        profile.weight = weight
        // 目標をカンマ区切りで保存
        profile.goal = selectedGoals.map { $0.rawValue }.joined(separator: ",")
        if let fat = Double(bodyFatPercentage), fat > 0 {
            profile.bodyFatPercentage = fat
        } else {
            profile.bodyFatPercentage = 0
        }
        profile.updatedAt = Date()

        do {
            try viewContext.save()
            return true
        } catch {
            errorMessage = "プロフィールの保存に失敗しました"
            showingError = true
            return false
        }
    }
}

// キーボードを閉じる
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ProfileEditView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
