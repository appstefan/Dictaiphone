//
//  DataStore.swift
//  Audio
//
//  Created by Stefan Britton on 2023-04-20.
//

import CoreData
import Foundation

struct DataStore {
    let container: NSPersistentContainer
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension DataStore {
    static let main = DataStore()
    
    static var mock: DataStore = {
        let result = DataStore(inMemory: true)
        let viewContext = result.context
        for index in 0..<5 {
            let note = mockNote(viewContext)
        }
        do {
            try viewContext.save()
        } catch let nsError as NSError {
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    static func mockNote(_ context: NSManagedObjectContext) -> Note {
        let note = Note(context: context)
        note.dateCreated = .now
        note.title = "Makeshift Standup"
        note.summary = "This is a mock summary from GPT"
        note.subtitle = "Talks about Makeshift, OpenAI Credits and Twitter Threads"
        note.text = "So I'm thinking about makeshift namecards and how we can do as much as possible with them. I know we have a custom stable diffusion model and really cool art but I'm worried do people, like, So I'm thinking about makeshift namecards and how we can do as much as possible with them. I know we have a custom stable diffusion model and really cool art but I'm worried do people, like"
        return note
    }
}
