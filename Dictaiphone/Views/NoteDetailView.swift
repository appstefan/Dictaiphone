//
//  NoteDetailView.swift
//  Dictaiphone
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI
import AVFoundation



struct NoteDetailView: View {
    let note: Note
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var showShareSheet = false

    
    private var itemsToShare: [Any] {
           let actionItemsString = note.actionItems ?? ""
           let actionItemsArray = actionItemsString
               .components(separatedBy: "-")
               .map { $0.trimmingCharacters(in: .whitespaces) }
               .filter { !$0.isEmpty }
           let formattedActionItems = actionItemsArray.joined(separator: "\n")
           
           return [
                "Title: \(note.title ?? "")",
                "Summary: \(note.summary ?? "")",
               "Action Items:\n\(formattedActionItems)"
           ]
       }
  
 
    var body: some View {
        List {
            Section("Transcript") {
                NavigationLink(
                    destination: {
                        FullTranscriptView(note: note)
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
            Section("Action Items") {
                            // Split the action items string into an array
                            let actionItemsArray = note.actionItems?.split(separator: "\n").map(String.init) ?? []
                            
                            // Display each action item on its own line
                            ForEach(actionItemsArray, id: \.self) { actionItem in
                                Text(actionItem)
                            }
                        }
                    }
        Button(action: {
            if isPlaying {
                audioPlayer?.pause()
            } else {
                if audioPlayer == nil {
                    // Initialize the audio player with the audio file path from the note
                    if let audioFilePath = note.audioFilePath, let audioURL = URL(string: audioFilePath) {
                        do {
                            let player = try AVAudioPlayer(contentsOf: audioURL)
                            audioPlayer = player
                        } catch {
                            print("Error initializing audio player: \(error)")
                        }
                    } else {
                        print("Audio file path: \(String(describing: note.audioFilePath))")
                        print("Converted audio URL: \(String(describing: URL(string: note.audioFilePath ?? "")))")
                    }
                }
                audioPlayer?.prepareToPlay() // Explicitly prepare the audio player
                audioPlayer?.play()
            }
            // Toggle playback state
            isPlaying.toggle()
        }) {
            HStack {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                Text(isPlaying ? "Pause" : "Play")
            }
            .padding()
        }

        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: {
            showShareSheet = true
        }, label: {
            Image(systemName: "square.and.arrow.up")
        }))
        .sheet(isPresented: $showShareSheet) {
            // Present a UIActivityViewController to share the items
            ActivityView(activityItems: itemsToShare, applicationActivities: nil)
        }
    }
}

struct NoteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NoteDetailView(note: .mock(hoursAgo: 1))
        }
    }
}

// The ActivityView is a wrapper around UIActivityViewController
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]?
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {
    }
}
