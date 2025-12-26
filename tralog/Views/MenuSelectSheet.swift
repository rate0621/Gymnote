//
//  MenuSelectSheet.swift
//  tralog
//
//  Created by rate on 2025/12/25.
//

import SwiftUI

struct MenuSelectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedBodyPart: BodyPart?
    @Binding var selectedMenuItem: TrainingMenuItem?

    @State private var currentTab: BodyPart = .upperBody

    var body: some View {
        NavigationView {
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
                    ForEach(currentTab.menus) { menu in
                        Button {
                            selectedBodyPart = currentTab
                            selectedMenuItem = menu
                            dismiss()
                        } label: {
                            HStack {
                                Text(menu.name)
                                    .foregroundColor(.primary)
                                Spacer()
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
        }
    }
}

#Preview {
    MenuSelectSheet(
        selectedBodyPart: .constant(.upperBody),
        selectedMenuItem: .constant(TrainingMenuItem(name: "ベンチプレス", inputType: .weightReps))
    )
}
