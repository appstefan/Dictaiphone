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
    var speechSummarizer: SpeechSummarizer = SpeechSummarizer()
    
    var body: some Scene {
        WindowGroup {
            NotesListView()
                .environmentObject(speechSummarizer)
                .environment(\.managedObjectContext, DataStore.main.context)
        }
    }
}
