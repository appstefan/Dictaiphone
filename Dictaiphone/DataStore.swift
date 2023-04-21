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
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "DataModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("\(error), \(error.userInfo)")
            }
        })
    }
}

extension DataStore {
    static let main = DataStore()
    
    static let mock = DataStore(inMemory: true)
    
    static func mock(count: Int) -> DataStore {
        mockNotes(count: count)
        return mock
    }
    
    private static func mockNotes(count: Int) {
        for index in 0..<count {
            let _ = Note.mock(hoursAgo: index)
        }
        do {
            try mock.viewContext.save()
        } catch let nsError as NSError {
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

extension Note {
    static func mock(hoursAgo: Int) -> Note {
        let note = Note(context: DataStore.mock.viewContext)
        note.dateCreated = Date.now.addingTimeInterval(TimeInterval(-(60 * 60 * hoursAgo)))
        note.title = "Makeshift Standup, Longer title which may need to wrap to a second line"
        note.summary = "This is a mock summary from GPT"
        note.subtitle = "Talks about Makeshift, OpenAI Credits and Twitter Threads"
        note.text = "So I'm thinking about makeshift namecards and how we can do as much as possible with them. I know we have a custom stable diffusion model and really cool art but I'm worried do people, like, So I'm thinking about makeshift namecards and how we can do as much as possible with them. I know we have a custom stable diffusion model and really cool art but I'm worried do people, like"
        return note
    }
}
