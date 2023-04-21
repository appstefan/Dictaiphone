//
//  CreateNoteView.swift
//  Audio
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI

struct CreateNoteView: View {
    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(\.managedObjectContext)
    private var context
    
    @EnvironmentObject
    var speechSummarizer: SpeechSummarizer
    
    @State
    var title: String?
    
    @State
    var subtitle: String?
    
    @State
    var summary: String?
    
    @State
    var isSummarizing: Bool = false
    
    var body: some View {
        List {
            Section("") {
                if speechSummarizer.isAuthorized {
                    if speechSummarizer.isRecording {
                        Button("Stop") {
                            speechSummarizer.stop()
                            summarize()
                        }
                    } else if speechSummarizer.text.isEmpty {
                        Button("Start") {
                            do {
                                try speechSummarizer.start()
                            } catch {
                                print(error)
                            }
                        }
                    } else if isSummarizing {
                        Text("Loading...")
                    } else {
                        Button("Save") {
                            save()
                        }
                    }
                } else {
                    Button("Authorize") {
                        speechSummarizer.auth()
                    }
                }
            }
            if let title {
                Section("Title") {
                    Text(title)
                }
            }
            if let subtitle {
                Section("Subtitle") {
                    Text(subtitle)
                }
            }
            if let summary {
                Section("Summary") {
                    Text(summary)
                }
            }
            Section("Transcript") {
                Text(speechSummarizer.text)
            }
        }
        .navigationTitle("New recording")
    }
    
    @MainActor
    private func summarize() {
        self.isSummarizing = true
        Task {
            self.summary = try await speechSummarizer.createSummary()
            if let summary {
                self.title = try await speechSummarizer.createTitle(summary)
                self.subtitle = try await speechSummarizer.createSubtitle(summary)
            }
            self.isSummarizing = false
        }
    }
    
    private func save() {
        withAnimation {
            let system = Note(context: context)
            system.dateCreated = .now
            system.text = speechSummarizer.text
            system.title = title
            system.summary = summary
            system.subtitle = subtitle
            do {
                try context.save()
                dismiss()
            } catch let nsError as NSError {
                fatalError("\(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct CreateNoteView_Previews: PreviewProvider {
    static var speechSummarizer = SpeechSummarizer()
    
    static var previews: some View {
        NavigationStack {
            CreateNoteView()
                .environmentObject(speechSummarizer)
        }
    }
}
