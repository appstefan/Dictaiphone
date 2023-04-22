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
    private var viewContext

    @EnvironmentObject
    private var summarizer: Summarizer
    
    @State
    private var title: String?
    
    @State
    private var subtitle: String?
    
    @State
    private var summary: String?
    
    @State
    private var isSummarizing: Bool = false
    
    @State
    private var showSaveAlert: Bool = false
    
    var body: some View {
        List {
            Section("") {
                if summarizer.isRecording {
                    Button("Stop") {
                        summarizer.stopRecording()
                    }
                } else if !summarizer.hasRecording {
                    Button("Start") {
                        summarizer.startRecording()
                    }
                } else if summarizer.isTranscribing {
                    VStack(alignment: .leading) {
                        Text("Transcribing...")
                        ProgressView(value: summarizer.transcribeProgress)
                    }
                } else if isSummarizing {
                    Text("Summarizing...")
                } else if summary != nil {
                    Button("Clear") {
                        clear()
                    }
                } else {
                    Button("Clear") {
                        clear()
                    }
                    Button("Summarize!") {
                        summarize()
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
                Text(summarizer.text)
            }
        }
        .navigationTitle("New recording")
        .interactiveDismissDisabled(hasSummary || isSummarizing || summarizer.isRecording)
        .toolbar {
            if hasSummary {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Discard", role: .destructive) {
                        clear()
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if hasSummary {
                    Button("Save") {
                        saveAndDismiss()
                    }
                } else {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var hasSummary: Bool {
        !(summary?.isEmpty ?? true)
    }
    
    private func clear() {
        self.title = nil
        self.subtitle = nil
        self.summary = nil
        self.summarizer.clear()
    }
    
    @MainActor
    private func summarize() {
        guard !summarizer.text.isEmpty else {
            return
        }
        self.isSummarizing = true
        Task {
            self.summary = try await summarizer.makeSummary()
            if let summary {
                self.title = try await summarizer.makeTitle(summary)
                self.subtitle = try await summarizer.makeSubtitle(summary)
            }
            self.isSummarizing = false
        }
    }
    
    private func saveAndDismiss() {
        withAnimation {
            let system = Note(context: viewContext)
            system.dateCreated = .now
            system.text = summarizer.text
            system.title = title
            system.summary = summary
            system.subtitle = subtitle
            do {
                try viewContext.save()
                summarizer.clear()
                dismiss()
            } catch let nsError as NSError {
                fatalError("\(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct CreateNoteView_Previews: PreviewProvider {
    static var summarizer = Summarizer()
    
    static var previews: some View {
        NavigationStack {
            CreateNoteView()
                .environmentObject(summarizer)
        }
    }
}
