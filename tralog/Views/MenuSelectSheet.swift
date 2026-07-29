//
//  MenuSelectSheet.swift
//  tralog
//
//  Created by rate on 2025/12/25.
//

import SwiftUI
import CoreData

struct MenuSelectSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBodyPart: BodyPart?
    @Binding var selectedMenuItem: TrainingMenuItem?

    @State private var currentTab: BodyPart = .upperBody

    // メニュー名ごとの最終実施日（シート表示中は並びを固定して誤タップを防ぐ）
    @State private var latestDates: [String: Date] = [:]

    /// 記録あり同士は最新順、記録ありは未使用より上、未使用同士は定義順
    private var sortedMenus: [TrainingMenuItem] {
        currentTab.menus.enumerated().sorted { lhs, rhs in
            switch (latestDates[lhs.element.name], latestDates[rhs.element.name]) {
            case let (lhsDate?, rhsDate?):
                return lhsDate == rhsDate ? lhs.offset < rhs.offset : lhsDate > rhsDate
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                return lhs.offset < rhs.offset
            }
        }
        .map { $0.element }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 部位タブ
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(BodyPart.allCases) { part in
                            Button {
                                currentTab = part
                            } label: {
                                Text(part.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(currentTab == part ? .bold : .regular)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(currentTab == part ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(currentTab == part ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                .background(Color(.systemBackground))

                Divider()

                // メニューリスト
                List {
                    ForEach(sortedMenus) { menu in
                        Button {
                            selectedBodyPart = currentTab
                            selectedMenuItem = menu
                            dismiss()
                        } label: {
                            HStack {
                                Text(menu.name)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Spacer()
                                if let latestDate = latestDates[menu.name] {
                                    lastPerformedBadge(for: latestDate)
                                }
                                if selectedMenuItem?.name == menu.name && selectedBodyPart == currentTab {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("メニューを選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                latestDates = TrainingRecordQueries.latestDatesByMenuName(in: viewContext)
            }
        }
    }

    // MARK: - 実施済みバッジ

    /// 最終実施日を示す控えめなバッジ
    private func lastPerformedBadge(for date: Date) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "clock.arrow.circlepath")
            Text(relativeText(for: date))
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(1)
        .fixedSize()
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.gray.opacity(0.15))
        .clipShape(Capsule())
    }

    /// 最終実施日の相対表記（startOfDay同士の差で計算し、時刻差による誤判定を防ぐ）
    private func relativeText(for date: Date) -> String {
        let calendar = Calendar.current
        let from = calendar.startOfDay(for: date)
        let to = calendar.startOfDay(for: Date())
        let days = calendar.dateComponents([.day], from: from, to: to).day ?? 0

        switch days {
        case ...0: return "今日"   // 未来日付は起こらない想定だが今日扱いにする
        case 1: return "昨日"
        case 2...30: return "\(days)日前"
        default: return "かなり前"
        }
    }
}

#Preview {
    MenuSelectSheet(
        selectedBodyPart: .constant(.upperBody),
        selectedMenuItem: .constant(TrainingMenuItem(name: "ベンチプレス", inputType: .weightReps))
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
