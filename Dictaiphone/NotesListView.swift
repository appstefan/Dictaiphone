//
//  NotesList.swift
//  Audio
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI

struct NotesListView: View {
    @Environment(\.managedObjectContext)
    private var context
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Note.dateCreated, ascending: false)
        ],
        animation: .default)
    private var notes: FetchedResults<Note>
    
    @State
    var isSheetPresented: Bool = false
    
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
                        Button(action: add) {
                            Label("Add Note", systemImage: "plus")
                        }
                    }
                }
                .navigationTitle("Dictaiphone")
                .sheet(isPresented: $isSheetPresented) {
                    CreateNoteView()
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
    
    private func add() {
        isSheetPresented = true
    }
    
    private func delete(_ note: Note) {
        withAnimation {
            context.delete(note)
            do {
                try context.save()
            } catch let nsError as NSError {
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct NotesListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NotesListView()
                .environment(\.managedObjectContext, DataStore.mock.context)
        }
    }
}
