//
//  NoteDetailView.swift
//  Dictaiphone
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI

struct NoteDetailView: View {
    let note: Note
    
    var body: some View {
        List {
            Section("Transcript") {
                NavigationLink(
                    destination: {
                        TranscriptView(note: note)
                    },
                    label: {
                        Text(note.text ?? "")
                            .frame(maxHeight: 100)
                    }
                )
            }
            Section("Summary") {
                Text(note.summary ?? "")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NoteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NoteDetailView(note: DataStore.mockNote(DataStore.mock.context))
        }
    }
}
