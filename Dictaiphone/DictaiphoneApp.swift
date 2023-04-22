//
//  DictaiphoneApp.swift
//  Dictaiphone
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI

@main
struct DictaiphoneApp: App {
    @StateObject
    var summarizer: Summarizer = Summarizer()
    
    var body: some Scene {
        WindowGroup {
            NotesListView()
                .environmentObject(summarizer)
                .environment(\.managedObjectContext, DataStore.main.viewContext)
        }
    }
}
