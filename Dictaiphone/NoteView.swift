//
//  NoteView.swift
//  Audio
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI

struct NoteView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .listRowSeparatorLeading, spacing: 8) {
                Text(note.title ?? "")
                    .font(.headline)
                if let dateCreated = note.dateCreated {
                    HStack(spacing: 0) {
                        Text(dateCreated, style: .time)
                        Text("・")
                        Text(dateCreated, style: .date)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            Text(note.subtitle ?? "")
                .foregroundColor(.secondary)
        }
    }
}

struct NoteView_Previews: PreviewProvider {
    static var previews: some View {
        NoteView(note: DataStore.mockNote(DataStore.mock.context))
    }
}
