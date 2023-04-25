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
        
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title ?? "")
                    .font(.custom("Fonts/Inter-Bold.otf", size: 20))
                    .fixedSize(horizontal: false, vertical: true)
                Text(note.dateCreated ?? .now, format: .dateTime)
                    .font(.custom("Inter-Medium", size: 15))
                    .foregroundColor(.secondary)
            }
            Text(note.subtitle ?? "")
                .foregroundColor(.secondary)
            
            // Calculate the number of action items
            let actionItemCount = (note.actionItems ?? "")
                .split(separator: "\n")
                .count
            
            // Display the count of action items as a callout
            if actionItemCount > 0 {
                Text("\(actionItemCount) Action Item\(actionItemCount > 1 ? "s" : "")")
                    .font(.custom("Inter-Bold", size: 15))
                    .foregroundColor(.accentColor)
            }
        }
    }
}

struct NoteView_Previews: PreviewProvider {
    static var previews: some View {
        NoteView(note: .mock(hoursAgo: 1))
    }
}
