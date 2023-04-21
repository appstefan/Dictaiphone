//
//  TranscriptView.swift
//  Dictaiphone
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI

struct TranscriptView: View {
    let note: Note
    
    var body: some View {
        List {
            Section("Full Transcript") {
                Text(note.text ?? "")
            }
        }
    }
}

struct TranscriptView_Previews: PreviewProvider {
    static var previews: some View {
        TranscriptView(note: DataStore.mockNote(DataStore.mock.context))
    }
}
