//
//  DailyMemoSheet.swift
//  tralog
//
//  その日のトレーニングメモを入力するシート
//

import SwiftUI
import CoreData

struct DailyMemoSheet: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let date: Date

    @State private var memoText = ""

    // エラー通知
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                // 対象日
                Text(DateFormatters.fullDate.string(from: date))
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                // メモ入力
                TextEditor(text: $memoText)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                // 保存ボタン
                Button {
                    if saveMemo() {
                        dismiss()
                    }
                } label: {
                    Text("保存")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("トレーニングメモ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("エラー", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                memoText = TrainingRecordQueries.memo(for: date, in: viewContext)?.memo ?? ""
            }
        }
    }

    @discardableResult
    private func saveMemo() -> Bool {
        do {
            try TrainingRecordQueries.upsertMemo(memoText, for: date, in: viewContext)
            return true
        } catch {
            errorMessage = "メモの保存に失敗しました"
            showingError = true
            return false
        }
    }
}

#Preview {
    DailyMemoSheet(date: Date())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
