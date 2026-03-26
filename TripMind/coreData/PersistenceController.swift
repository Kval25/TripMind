//
//  PersistenceController.swift
//  TripMind
//
//  Created by REAL  on 26/03/26.
//

import CoreData

struct PersistenceController{
    static let shared = PersistenceController()
    
    let container : NSPersistentContainer
    
    init(){
        container = NSPersistentContainer(name: "TripMind")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData failed to load: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    var context: NSManagedObjectContext {
        container.viewContext
    }
    func save(){
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            }catch{
                print("CoreData save error: \(error)")
            }
        }
    }
    
}
