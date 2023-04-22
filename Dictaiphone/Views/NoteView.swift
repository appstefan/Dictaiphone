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
            VStack(alignment: .listRowSeparatorLeading, spacing: 4) {
                Text(note.title ?? "")
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(note.dateCreated ?? .now, format: .dateTime)
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
        NoteView(note: .mock(hoursAgo: 1))
    }
}
