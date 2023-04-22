//
//  CreateNoteView.swift
//  Audio
//
//  Created by Stefan Britton on 2023-04-20.
//

import SwiftUI
//import EventKit


struct CreateNoteView: View {
    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(\.managedObjectContext)
    private var viewContext
    
    @EnvironmentObject
    private var summarizer: Summarizer
    
        
//        @State
//        private var showShareSheet: Bool = false
    
    @State
    private var showSaveAlert: Bool = false
    
    
    @State private var itemsToShare: [String] = []
    
    var body: some View {
        List {
//            Button("Share Action Items") {
//                           showShareSheet = true
//                       }
//                       .sheet(isPresented: $showShareSheet) {
//                           ShareSheet(activityItems: summarizer.actionItems)
//                       }
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
                } else if summarizer.isSummarizing {
                    VStack(alignment: .leading) {
                        Text("Summarizing...")
                        ProgressView() // Indeterminate progress view (spinning)
                    }
                } else if summarizer.summary == nil {
                    Button("") {
                        clear()
                    }
                } else {
                    Button("Clear") {
                        clear()
                    }
                }
            }
            if let title = summarizer.title {
                Section("Title") {
                    Text(title)
                }
            }
            if let subtitle = summarizer.subtitle {
                Section("Subtitle") {
                    Text(subtitle)
                }
            }
            if let summary = summarizer.summary {
                Section("Summary") {
                    Text(summary)
                }
                Section("Action Items") {
                    ForEach(summarizer.actionItems, id: \.self) { actionItem in
                        Text(actionItem)
                    }
                }
            }
            Section("Transcript") {
                Text(summarizer.text)
            }
        }
//        .actionSheet(isPresented: $showShareSheet) {
//            ActionSheet(
//                title: Text("Share Action Items"),
//                buttons: [
//                    .default(Text("Share"), action: {
//                        itemsToShare = summarizer.actionItems
//                        showShareSheet = true
//                    }),
//                    .default(Text("Export to To-Do List"), action: {
//                        exportToReminders()
//                    }),
//                    .cancel()
//                ]
//            )
//        }
//                .sheet(isPresented: $showShareSheet) {
//                    ActivityView(activityItems: itemsToShare, applicationActivities: nil)
//                }
        
        .navigationTitle(summarizer.title ?? "New Recording")
        .interactiveDismissDisabled(hasSummary || summarizer.isRecording)
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
        !(summarizer.summary?.isEmpty ?? true)
    }
    
    private func clear() {
        summarizer.clear()
    }
    
    private func saveAndDismiss() {
        withAnimation {
            let system = Note(context: viewContext)
            system.dateCreated = .now
            system.text = summarizer.text
            system.title = summarizer.title
            system.summary = summarizer.summary
            system.subtitle = summarizer.subtitle
            system.actionItems = summarizer.actionItems.joined(separator: ",")

            do {
                try viewContext.save()
                summarizer.clear()
                dismiss()
            } catch let nsError as NSError {
                fatalError("\(nsError), \(nsError.userInfo)")
            }
        }
    }
//    private func exportToReminders() {
//        let eventStore = EKEventStore()
//        eventStore.requestAccess(to: .reminder) { (granted, error) in
//            if granted {
//                // Create a reminder for each action item
//                for item in summarizer.actionItems {
//                    let reminder = EKReminder(eventStore: eventStore)
//                    reminder.title = item
//                    reminder.calendar = eventStore.defaultCalendarForNewReminders()
//
//                    do {
//                        // Save the reminder
//                        try eventStore.save(reminder, commit: true)
//                    } catch {
//                        // Handle error when saving the reminder
//                        print("Error saving reminder: \(error)")
//                    }
//                }
//            } else {
//                // Handle error when access is not granted
//                print("Access to Reminders app not granted")
//            }
//        }
//    }
//
//    struct ShareSheet: UIViewControllerRepresentable {
//        typealias UIViewControllerType = UIActivityViewController
//
//        var activityItems: [String]
//
//        func makeUIViewController(context: Context) -> UIActivityViewController {
//            let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
//            return activityViewController
//        }
//
//        func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
//            // No need to update anything
//        }
//    }
    struct CreateNoteView_Previews: PreviewProvider {
        static var summarizer = Summarizer()
        
        static var previews: some View {
            NavigationStack {
                CreateNoteView()
                    .environmentObject(summarizer)
            }
        }
    }
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
}
