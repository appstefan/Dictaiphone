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
        audioEngine.stop()
        endRecording()
        transcribe()
    }
    
    func clear() {
        self.text = ""
        self.audioFrames = []
        self.hasRecording = false
    }
    
    func makeSummary() async throws -> String? {
        let prompt: String = """
            The following is a voice memo transcript. Your job is to summarize the memo in under 500 characters with bullet points and action items:
            
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
        return completion
            .choices
            .first?
            .message
            .content
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    func makeSubtitle(_ summary: String) async throws -> String? {
        let prompt: String = """
            The following is a summary of a voice memo transcript. Your job is to list a few of the key topics, comma separated:
            
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
            The following is a summary of a voice memo transcript. Your job is to create a short title for the voice memo:
            
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
    
    //  MARK: - Private
    
    private func startAudioEngine() {
        audioFrames.removeAll()
        whisper.delegate = self
        inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 8192, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.audioFrames.append(contentsOf: Array<Float>(UnsafeBufferPointer(buffer.audioBufferList.pointee.mBuffers)))
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
    
    @MainActor
    private func transcribe() {
        self.isTranscribing = true
        Task {
            do {
                let segments = try await self.whisper.transcribe(audioFrames: audioFrames)
                let newText = segments.map(\.text).joined().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                self.text = newText
                self.isTranscribing = false
            } catch {
                logger.error("\(error)")
            }
        }
    }
}


