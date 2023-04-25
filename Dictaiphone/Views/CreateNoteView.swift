//
//  CreateNoteView.swift
//  Audio
//
//  Created by Stefan Britton on 2023-04-20.
//
import SwiftUI

struct CreateNoteView: View {
    @ObservedObject var audioRecorder: AudioRecorder

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.colorScheme)
    var colorScheme

    @Environment(\.managedObjectContext)
    private var viewContext
    
    @EnvironmentObject
    private var summarizer: Summarizer

    @State
    private var showSaveAlert: Bool = false
    

    var body: some View {
        let gradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.181, green: 0.192, blue: 0.187),
                Color(red: 0.042, green: 0.042, blue: 0.042)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return ZStack {
            // Use the gradient as the background of the ZStack
            Rectangle()
                .fill(gradient)
                .edgesIgnoringSafeArea(.all)
            VStack {
                // Waveform view
                
                
                if summarizer.isRecording {
                    CustomWaveformView(amplitudes: summarizer.waveformAmplitudes)
                        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100, alignment: .center)
                    // Recording label and Summarize button while recording
                    Text("Recording...")
                        .font(.title2)
                        .padding(.bottom, 10)
                    
                    Button(action: {
                        summarizer.stopRecording()
                        audioRecorder.stopRecording()
                    }, label: {
                        HStack {
                            Image("mic") // Add the desired icon
                            Text("Summarize")
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                    })
                } else {
                    if summarizer.isTranscribing {
                        VStack(alignment: .leading) {
                            Text("Transcribing...")
                            ProgressView(value: summarizer.transcribeProgress)
                        }
                    } else if summarizer.isSummarizing {
                        VStack(alignment: .leading) {
                            Text("Summarizing...")
                            ProgressView() // Indeterminate progress view (spinning)
                        }
                    } else {
                        // Display data after recording is stopped
                        List {
                            
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
                    }
                }
            }
            .padding()
            .onAppear {
                // Start recording automatically when the view appears
                summarizer.startRecording()
                audioRecorder.startRecording()
            }
            // The rest of your body code here...
            //.navigationTitle(summarizer.title ?? "New Recording")
            .interactiveDismissDisabled(hasSummary || summarizer.isRecording)
            .toolbar {
                if let summary = summarizer.summary, !summary.isEmpty {
                    ToolbarItem(placement: .principal) {
                        Text(summarizer.title ?? "New Recording")
                            .font(.headline)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if hasSummary {
                        Button("Save") {
                            audioRecorder.stopRecording()
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
    }
    private var hasSummary: Bool {
        !(summarizer.summary?.isEmpty ?? true)
    }
    
    private func clear() {
        summarizer.clear()
    }
    
    private func saveAndDismiss() {
        print("Saving and dismissing...")
            print("AudioRecorder's audioFileURL: \(audioRecorder.audioFileURL)")

        withAnimation {
            let system = Note(context: viewContext)
            system.dateCreated = .now
            system.text = summarizer.text
            system.title = summarizer.title
            system.summary = summarizer.summary
            system.subtitle = summarizer.subtitle
            system.actionItems = summarizer.actionItems.joined(separator: "\n")
            
            // Set the audioFilePath property of the new note to the file path of the recorded audio
            system.audioFilePath = audioRecorder.audioFilePath
                print("Saving audioFilePath: \(String(describing: audioRecorder.audioFilePath))") // Check the printed output
                    do {
                        try viewContext.save()
                        summarizer.clear()
                        audioRecorder.audioFilePath = nil // Clear the audio file path
                        dismiss()
                    } catch let nsError as NSError {
                        fatalError("\(nsError), \(nsError.userInfo)")
                    }
                }
            }
}
