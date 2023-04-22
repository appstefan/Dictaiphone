//
//  NotesList.swift
//  Audio
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI

struct NotesListView: View {
    @Environment(\.managedObjectContext)
    var viewContext
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Note.dateCreated, ascending: false)
        ],
        animation: .default)
    var notes: FetchedResults<Note>
    
    @State
    var showCreateNote: Bool = false
    
    @State
    var selectedNote: Note.ID?
    
    var body: some View {
        NavigationSplitView(
            sidebar: {
                List(notes, selection: $selectedNote) { note in
                    NoteView(note: note)
                        .contextMenu {
                            Button("Delete") {
                                delete(note)
                            }
                        }
                }
                .toolbar {
                    ToolbarItem {
                        Button(action: { showCreateNote = true }) {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                .navigationTitle("Dictaitions")
                .sheet(isPresented: $showCreateNote) {
                    NavigationStack {
                        CreateNoteView()
                    }
                }
            },
            detail: {
                if
                    let selectedNote,
                    let note = notes.first(where: { $0.id == selectedNote }) {
                    NavigationStack {
                        NoteDetailView(note: note)
                    }
                }
            }
        )
        
    }
    
    private func delete(_ note: Note) {
        withAnimation {
            viewContext.delete(note)
            do {
                try viewContext.save()
            } catch let nsError as NSError {
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct NotesListView_Previews: PreviewProvider {
    static var previews: some View {
        NotesListView()
            .environment(\.managedObjectContext, DataStore.mock(count: 1).viewContext)
    }
}
