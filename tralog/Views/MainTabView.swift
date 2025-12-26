//
//  MainTabView.swift
//  tralog
//
//  Created by rate on 2025/12/26.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    var body: some View {
        TabView {
            ContentView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("記録する")
                }

            HistoryView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("確認する")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
