//
//  FullTranscriptView.swift
//  Dictaiphone
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI

struct FullTranscriptView: View {
    let note: Note
    
    var body: some View {
        List {
            Section("Full Transcript") {
                Text(note.text ?? "")
            }
        }
    }
}

struct FullTranscriptView_Previews: PreviewProvider {
    static var previews: some View {
        FullTranscriptView(note: .mock(hoursAgo: 0))
    }
}
