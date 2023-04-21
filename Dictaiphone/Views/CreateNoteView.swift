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
    private var speechSummarizer: SpeechSummarizer
    
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
                if speechSummarizer.isRecording {
                    Button("Stop") {
                        speechSummarizer.stop()
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
                } else if let summary {
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
                Text(speechSummarizer.text)
            }
        }
        .navigationTitle("New recording")
        .onAppear {
            if !speechSummarizer.isAuthorized {
                speechSummarizer.authorize()
            }
        }
        .interactiveDismissDisabled(hasSummary || isSummarizing || speechSummarizer.isRecording)
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
        self.speechSummarizer.text = ""
    }
    
    @MainActor
    private func summarize() {
        guard !speechSummarizer.text.isEmpty else {
            return
        }
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
    
    private func saveAndDismiss() {
        withAnimation {
            let system = Note(context: viewContext)
            system.dateCreated = .now
            system.text = speechSummarizer.text
            system.title = title
            system.summary = summary
            system.subtitle = subtitle
            do {
                try viewContext.save()
                speechSummarizer.text = ""
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



//                .alert(
//                    "Discard this note?",
//                    isPresented: $showSaveAlert
//                ) {
//                    Button(role: .destructive) {
//                        dismiss()
//                    } label: {
//                        Text("Discard")
//                    }
//                } message: {
//                    Text("This transcipt and the summary will not be saved.")
//                }
