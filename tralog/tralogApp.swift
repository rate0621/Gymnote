//
//  tralogApp.swift
//  tralog
//
//  Created by rate on 2025/12/25.
//

import SwiftUI
import CoreData

@main
struct tralogApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
