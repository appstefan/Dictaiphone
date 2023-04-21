//
//  SpeechSummarizer.swift
//  Dictaiphone
//
//  Created by Stefan Britton on 2023-04-20.
//

import Foundation
import Speech
import AVFoundation
import OpenAIKit
import AsyncHTTPClient

class SpeechSummarizer: ObservableObject {
    @Published
    var text: String = ""
    
    @Published
    var isRecording: Bool = false
    
    @Published
    var isAuthorized: Bool = false
    
    private let client: OpenAIKit.Client
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    
    private func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { checkedContinuation in
            SFSpeechRecognizer.requestAuthorization { status in
                checkedContinuation.resume(with: .success(status))
            }
        }
    }
    
    init() {
        client = OpenAIKit.Client(
            httpClient: HTTPClient(eventLoopGroupProvider: .createNew),
            configuration: Configuration(apiKey: OpenAI.apiKey)
        )
    }
    
    @MainActor
    func auth() {
        Task {
            switch await requestAuthorization() {
            case .authorized:
                self.isAuthorized = true
            default:
                self.isAuthorized = false
            }
        }
    }
    
    @MainActor
    func start() throws {
        let audioSession = AVAudioSession.sharedInstance()
        
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else {
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        self.recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            if let result = result {
                
                self.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                self.isRecording = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        self.isRecording = true
    }
    
    func stop() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        self.isRecording = false
    }
    
    func createSummary() async throws -> String? {
        let prompt: String = """
            The following is a voice memo transcript. Your job is to summarize the memo in under 500 characters with bullet points and action items:
            
            Transcript: ###
            \(text)
            ###
            
            Summary:
            """
            let completion = try await client.chats.create(
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
    
    func createSubtitle(_ summary: String) async throws -> String? {
        let prompt: String = """
            The following is a summary of a voice memo transcript. Your job is to list a few of the key topics, comma separated:
            
            Summary: ###
            \(summary)
            ###
            
            Key topics:
            """
        let completion = try await client.chats.create(
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
    
    func createTitle(_ summary: String) async throws -> String? {
        let prompt: String = """
            The following is a summary of a voice memo transcript. Your job is to create a short title for the voice memo:
            
            Summary: ###
            \(summary)
            ###
            
            Title:
            """
        let completion = try await client.chats.create(
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
}


