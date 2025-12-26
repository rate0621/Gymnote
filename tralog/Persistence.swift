//
//  Persistence.swift
//  tralog
//
//  Created by rate on 2025/12/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // サンプルデータを作成
        let sampleData: [(String, String, String, Double, Double, Int16)] = [
            ("上半身", "ベンチプレス", "weightReps", 60.0, 10.0, 0),
            ("上半身", "ベンチプレス", "weightReps", 60.0, 8.0, 0),
            ("下半身", "スクワット", "weightReps", 80.0, 8.0, 0),
            ("体幹", "プランク", "timeOnly", 60.0, 0.0, 0),
            ("有酸素運動", "トレッドミル", "inclineSpeedTime", 2.0, 8.5, 20),
        ]

        for (bodyPart, menuName, inputType, value1, value2, value3) in sampleData {
            let record = TrainingRecord(context: viewContext)
            record.id = UUID()
            record.date = Date()
            record.bodyPart = bodyPart
            record.menuName = menuName
            record.inputType = inputType
            record.value1 = value1
            record.value2 = value2
            record.value3 = value3
        }

        // サンプルユーザープロフィール
        let profile = UserProfile(context: viewContext)
        profile.id = UUID()
        profile.birthYear = 1990
        profile.gender = "男性"
        profile.height = 170.0
        profile.weight = 65.0
        profile.goal = "健康維持"
        profile.bodyFatPercentage = 18.0
        profile.updatedAt = Date()

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "tralog")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
