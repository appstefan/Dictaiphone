//
//  Summarizer.swift
//  Dictaiphone
//
//  Created by Stefan Britton on 2023-04-20.
//

import OSLog
import Foundation
import AVFoundation
import SwiftWhisper
import OpenAIKit
import AsyncHTTPClient

class Summarizer: NSObject, ObservableObject, AVAudioRecorderDelegate, WhisperDelegate {
    @Published
      var text: String = ""
      
      @Published
      var isRecording: Bool = false
      
      @Published
      var hasRecording: Bool = false
      
      @Published
      var isTranscribing: Bool = false
      
      @Published
      var transcribeProgress: Double = 0
      
      @Published
      var isAuthorized: Bool = false
      
      @Published
      var realTimeTranscription: String = ""
      
      @Published
      var summary: String?
    
      @Published
      var actionItems: [String] = []

      @Published
      var title: String?
      
      @Published
      var subtitle: String?
    
      @Published
      var isSummarizing: Bool = false

    @Published
       var waveformAmplitudes: [CGFloat] = []
    
    private let logger: Logger
    private var isBusy: Bool = false
    private var audioFrames: [Float] = []
    private var whisper: Whisper!
    private let openAI: OpenAIKit.Client
    private var inputNode: AVAudioNode!
    private let audioEngine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()

    override init() {
        self.logger = Logger(subsystem: "com.makeshift.Dictaiphone", category: "Summarizer")
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)
        let configuration = Configuration(apiKey: OpenAI.apiKey)
        self.openAI = OpenAIKit.Client(httpClient: httpClient, configuration: configuration)
        let modelURL = Bundle.main.url(forResource: "ggml-small", withExtension: ".bin")!
        self.whisper = Whisper(fromFileURL: modelURL)
    }

    @MainActor
    func startRecording() {
        self.realTimeTranscription = "" // Reset real-time transcription

        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            try audioSession.setPreferredSampleRate(16000)
            audioSession.requestRecordPermission { isPermitted in
                if isPermitted {
                    self.startAudioEngine()
                } else {
                    // Ask user to give permission in settings?
                }
            }
        } catch {
            logger.error("\(error)")
        }
    }
    
    @MainActor
    func stopRecording() {
        self.realTimeTranscription = "" // Reset real-time transcription

        audioEngine.stop()
        endRecording()
        transcribe()
    }
    
    func clear() {
        self.text = ""
        self.title = nil
        self.subtitle = nil
        self.summary = nil
        self.audioFrames = []
        self.hasRecording = false
    }
    
    func makeSummary() async throws -> String? {
        let prompt: String = """
            The following is a voice memo transcript. Your job is to summarize the memo in under 500 characters. The summary should be three sections: First, a couple sentences of prose summarizing the entire transcription. Then, use bullet points to break down key themes and topics. Finally, find and create detailed action items to be followed up on. The action items section should ALWAYS begin with "Action Items:" (case sensitive).  Preempt things the transcription might have forgotten about or left out and come up with new and novel ideas:
            Transcript: ###
            \(text)
            ###
            
            Summary:
            """
        let completion = try await openAI.chats.create(
            model: Model.GPT3.gpt3_5Turbo,
            messages: [Chat.Message.user(content: prompt)],
            maxTokens: 200
        )
        
        if let fullSummary = completion
            .choices
            .first?
            .message
            .content
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) {
            // Keyword or delimiter to identify the start of action items
            let actionItemsKeyword = "Action Items:"
            
            // Split the full summary into summary and action items based on the keyword
            let summaryComponents = fullSummary.components(separatedBy: actionItemsKeyword)
            let summaryText = summaryComponents.first?.trimmingCharacters(in: .whitespacesAndNewlines)
            let actionItemsText = summaryComponents.dropFirst().joined(separator: actionItemsKeyword).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Split action items by newlines to create an array of individual items
            let actionItemsArray = actionItemsText.split(separator: "\n").map { item -> String in
                let trimmedItem = item.trimmingCharacters(in: .whitespaces)
                if trimmedItem.hasPrefix("-") {
                    return String(trimmedItem.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                return trimmedItem
            }
            
            // Update the summary and action items properties
            self.summary = summaryText
            self.actionItems = actionItemsArray
            
            return summaryText
        }
        return nil
    }




    
    func makeSubtitle(_ summary: String) async throws -> String? {
        let prompt: String = """
            The following is a summary of a voice memo transcript. List three things this talks about, in no more than 2 words each, separated by commas.
            
            Summary: ###
            \(summary)
            ###
            
            Key topics:
            """
        let completion = try await openAI.chats.create(
            model: Model.GPT3.gpt3_5Turbo,
            messages: [Chat.Message.user(content: prompt)],
            maxTokens: 60
        )
        return completion
            .choices
            .first?
            .message
            .content
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func makeTitle(_ summary: String) async throws -> String? {
        let prompt: String = """
            The following is a summary of a voice memo transcript. Create a short title without the use of any quotes or special characters for the voice memo, maximum two words:
            
            Summary: ###
            \(summary)
            ###
            
            Title:
            """
        let completion = try await openAI.chats.create(
            model: Model.GPT3.gpt3_5Turbo,
            messages: [Chat.Message.user(content: prompt)],
            maxTokens: 30
        )
        return completion
            .choices
            .first?
            .message
            .content
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    func extractActionItems() {
            // Clear any previous action items.
            actionItems.removeAll()
            
            guard let summaryText = summary else { return }
            
            let lines = summaryText.split(separator: "\n")
            var foundActionItems = false
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if foundActionItems {
                    actionItems.append(String(trimmedLine))
                } else if trimmedLine.lowercased().contains("action items") {
                    foundActionItems = true
                }
            }
        }
    
    //  MARK: - Private
    
    private func startAudioEngine() {
        audioFrames.removeAll()
        whisper.delegate = self
        inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        // Reset real-time transcription at the start of a new recording.
        self.realTimeTranscription = ""
        
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            // Append recorded audio frames to the buffer.
            let recordedFrames = Array<Float>(UnsafeBufferPointer(buffer.audioBufferList.pointee.mBuffers))
            self.audioFrames.append(contentsOf: recordedFrames)
            
            // Calculate RMS amplitude levels for the waveform
            let chunkSize = 160 // Define the chunk size for RMS calculation
            var rmsAmplitudes: [CGFloat] = []
            for i in stride(from: 0, to: recordedFrames.count, by: chunkSize) {
                let chunk = recordedFrames[i ..< min(i + chunkSize, recordedFrames.count)]
                let rms = sqrt(chunk.map { CGFloat($0) * CGFloat($0) }.reduce(0, +) / CGFloat(chunk.count))
                rmsAmplitudes.append(rms)
            }
            
            DispatchQueue.main.async {
                self.waveformAmplitudes = rmsAmplitudes
                // Print the count and the first few amplitude values
                let count = self.waveformAmplitudes.count
                let firstFewAmplitudes = self.waveformAmplitudes.prefix(10)
            }
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
            self.isRecording = true
        } catch {
            logger.error("\(error)")
            endRecording()
        }
    }


    
    private func endRecording() {
        inputNode.removeTap(onBus: 0)
        self.isRecording = false
        self.hasRecording = !audioFrames.isEmpty
    }
    
    internal func whisper(_ aWhisper: Whisper, didUpdateProgress progress: Double) {
        self.transcribeProgress = max(0, min(1, progress))
    }
    func whisper(_ aWhisper: Whisper, didProcessNewSegments segments: [Segment], atIndex index: Int) {
        // Update the real-time transcription property with the transcribed segment text.
        DispatchQueue.main.async {
            self.realTimeTranscription += segments.map { $0.text }.joined()
        }
    }


    @MainActor
    private func transcribe() {
        self.isTranscribing = true
        Task {
            do {
                let segments = try await self.whisper.transcribe(audioFrames: audioFrames)
                let newText = segments.map(\.text).joined().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                self.text = newText
                self.isTranscribing = false
                // Trigger automatic summarization after transcription.
                try await self.processTranscription()
            } catch {
                logger.error("\(error)")
            }
        }
    }


       // New function to automatically summarize after transcription
    @MainActor
    private func processTranscription() async {
        guard !text.isEmpty else {
            return
        }
        do {
            summary = try await makeSummary()
            if let summary = summary {
                title = try await makeTitle(summary)
                subtitle = try await makeSubtitle(summary)
            }
        } catch {
            logger.error("\(error)")
        }
    }

   }



