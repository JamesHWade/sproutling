//
//  SoundManager.swift
//  Sproutling
//
//  Audio playback manager for sounds and speech
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit
import SwiftUI

class SoundManager: ObservableObject {
    static let shared = SoundManager()

    private var audioPlayer: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    // ElevenLabs integration
    private var elevenLabsPlayer: AVAudioPlayer?
    private var speechQueue: [SpeechTask] = []
    private var isProcessingQueue = false

    // Settings - persisted via UserDefaults
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true
    @AppStorage("elevenLabsEnabled") var elevenLabsEnabled: Bool = true
    @AppStorage("selectedVoiceId") private var selectedVoiceId: String = ElevenLabsService.Voice.bella.rawValue

    /// Speech task for queue management
    private struct SpeechTask {
        let text: String
        let settings: ElevenLabsService.VoiceSettings
        let useElevenLabs: Bool
        let completion: (() -> Void)?
    }

    private init() {
        setupAudioSession()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    // MARK: - Play Sound Effect
    func playSound(_ sound: SoundEffect) {
        guard soundEnabled else { return }

        // Try to play custom mp3 file first
        if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.play()
                return
            } catch {
                print("Failed to play custom sound: \(error)")
            }
        }

        // Fallback to system sounds
        playSystemSound(for: sound)
    }

    // MARK: - System Sound Fallbacks
    private func playSystemSound(for sound: SoundEffect) {
        let soundID: SystemSoundID
        switch sound {
        case .correct:
            soundID = 1025  // Pleasant positive tone
        case .incorrect:
            soundID = 1053  // Gentle negative tone
        case .tap:
            soundID = 1104  // Soft tap
        case .celebration:
            soundID = 1335  // Cheerful sound
        case .pop:
            soundID = 1306  // Pop sound
        case .whoosh:
            soundID = 1018  // Swoosh transition
        }
        AudioServicesPlaySystemSound(soundID)
    }

    // MARK: - Text to Speech
    func speak(_ text: String, rate: Float = 0.4) {
        guard soundEnabled else { return }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.2 // Slightly higher pitch for child-friendly voice
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        synthesizer.speak(utterance)
    }

    // MARK: - Speak Letter Sound
    func speakLetterSound(_ letter: String) {
        let phonics: [String: String] = [
            "A": "ah",
            "B": "buh",
            "C": "kuh",
            "D": "duh",
            "E": "eh",
            "F": "fuh",
            "G": "guh",
            "H": "huh",
            "I": "ih",
            "J": "juh",
            "K": "kuh",
            "L": "luh",
            "M": "muh",
            "N": "nuh",
            "O": "oh",
            "P": "puh",
            "Q": "kwuh",
            "R": "ruh",
            "S": "sss",
            "T": "tuh",
            "U": "uh",
            "V": "vuh",
            "W": "wuh",
            "X": "ks",
            "Y": "yuh",
            "Z": "zzz"
        ]

        if let sound = phonics[letter.uppercased()] {
            speak(sound, rate: 0.3)
        }
    }

    // MARK: - Speak Number
    func speakNumber(_ number: Int) {
        speak(String(number), rate: 0.35)
    }

    // MARK: - Stop Speaking
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        elevenLabsPlayer?.stop()
        speechQueue.removeAll()
        isProcessingQueue = false
    }

    // MARK: - ElevenLabs Integration

    /// Check if ElevenLabs is available (has API key and is enabled)
    var isElevenLabsAvailable: Bool {
        Task {
            return await ElevenLabsService.shared.hasAPIKey() && elevenLabsEnabled
        }
        // Synchronous check - returns cached state
        return elevenLabsEnabled
    }

    /// Speak text using ElevenLabs if available, falling back to system TTS
    /// - Parameters:
    ///   - text: Text to speak
    ///   - settings: Voice settings (defaults to child-friendly)
    ///   - completion: Called when speech completes
    func speakWithElevenLabs(
        _ text: String,
        settings: ElevenLabsService.VoiceSettings = .childFriendly,
        completion: (() -> Void)? = nil
    ) {
        guard soundEnabled else {
            completion?()
            return
        }

        let task = SpeechTask(
            text: text,
            settings: settings,
            useElevenLabs: true,
            completion: completion
        )
        speechQueue.append(task)
        processNextSpeechTask()
    }

    /// Speak personalized text with child's name
    /// - Parameters:
    ///   - template: Text template (use {name} as placeholder)
    ///   - childName: Child's name to insert
    ///   - completion: Called when speech completes
    func speakPersonalized(_ template: String, childName: String, completion: (() -> Void)? = nil) {
        let personalizedText = template.replacingOccurrences(of: "{name}", with: childName)
        speakWithElevenLabs(personalizedText, settings: .encouraging, completion: completion)
    }

    /// Speak an instruction or question
    func speakInstruction(_ text: String, completion: (() -> Void)? = nil) {
        speakWithElevenLabs(text, settings: .childFriendly, completion: completion)
    }

    /// Speak a number using ElevenLabs
    func speakNumberWithElevenLabs(_ number: Int, completion: (() -> Void)? = nil) {
        speakWithElevenLabs(String(number), settings: .quickPrompt, completion: completion)
    }

    /// Speak a letter name using ElevenLabs
    func speakLetterWithElevenLabs(_ letter: String, completion: (() -> Void)? = nil) {
        speakWithElevenLabs(letter.uppercased(), settings: .quickPrompt, completion: completion)
    }

    /// Speak a letter's phonetic sound using ElevenLabs
    func speakLetterSoundWithElevenLabs(_ letter: String, completion: (() -> Void)? = nil) {
        // Map letters to phonetic sounds that ElevenLabs can pronounce naturally
        let phonics: [String: String] = [
            "A": "ah", "B": "buh", "C": "kuh", "D": "duh", "E": "eh",
            "F": "fuh", "G": "guh", "H": "huh", "I": "ih", "J": "juh",
            "K": "kuh", "L": "luh", "M": "muh", "N": "nuh", "O": "oh",
            "P": "puh", "Q": "kwuh", "R": "ruh", "S": "sss", "T": "tuh",
            "U": "uh", "V": "vuh", "W": "wuh", "X": "ks", "Y": "yuh", "Z": "zzz"
        ]

        if let sound = phonics[letter.uppercased()] {
            speakWithElevenLabs(sound, settings: .quickPrompt, completion: completion)
        } else {
            completion?()
        }
    }

    // MARK: - Speech Queue Processing

    private func processNextSpeechTask() {
        guard !isProcessingQueue, !speechQueue.isEmpty else { return }

        isProcessingQueue = true
        let task = speechQueue.removeFirst()

        Task {
            await processSpeechTask(task)
        }
    }

    private func processSpeechTask(_ task: SpeechTask) async {
        defer {
            DispatchQueue.main.async { [weak self] in
                self?.isProcessingQueue = false
                task.completion?()
                self?.processNextSpeechTask()
            }
        }

        // Try ElevenLabs first if enabled
        if task.useElevenLabs && elevenLabsEnabled {
            let hasKey = await ElevenLabsService.shared.hasAPIKey()
            if hasKey {
                // Check cache first
                if let cachedData = await AudioCacheManager.shared.getCached(
                    text: task.text,
                    voiceId: selectedVoiceId
                ) {
                    await playAudioData(cachedData)
                    return
                }

                // Generate new audio
                do {
                    let voiceEnum = ElevenLabsService.Voice(rawValue: selectedVoiceId) ?? .bella
                    let audioData = try await ElevenLabsService.shared.generateSpeech(
                        text: task.text,
                        voice: voiceEnum,
                        settings: task.settings
                    )

                    // Cache the audio
                    await AudioCacheManager.shared.cache(
                        data: audioData,
                        text: task.text,
                        voiceId: selectedVoiceId
                    )

                    await playAudioData(audioData)
                    return
                } catch {
                    print("ElevenLabs TTS failed, falling back to system: \(error)")
                    // Fall through to system TTS
                }
            }
        }

        // Fallback to system TTS
        await MainActor.run {
            speak(task.text, rate: 0.4)
        }
    }

    @MainActor
    private func playAudioData(_ data: Data) async {
        do {
            elevenLabsPlayer = try AVAudioPlayer(data: data)
            elevenLabsPlayer?.prepareToPlay()
            elevenLabsPlayer?.play()

            // Wait for playback to complete
            while elevenLabsPlayer?.isPlaying == true {
                try? await Task.sleep(nanoseconds: 50_000_000)  // 50ms
            }
        } catch {
            print("Failed to play ElevenLabs audio: \(error)")
        }
    }

    // MARK: - Preloading

    /// Preload common phrases for instant playback
    func preloadCommonAudio() {
        guard elevenLabsEnabled else { return }

        Task {
            let hasKey = await ElevenLabsService.shared.hasAPIKey()
            guard hasKey else { return }

            let voiceId = selectedVoiceId
            let voice = ElevenLabsService.Voice(rawValue: voiceId) ?? .bella

            await AudioCacheManager.shared.preloadCommonPhrases(voiceId: voiceId) { text in
                try await ElevenLabsService.shared.generateSpeech(
                    text: text,
                    voice: voice,
                    settings: .quickPrompt
                )
            }
        }
    }
}

// MARK: - Sound Effects
enum SoundEffect: String {
    case correct = "correct"
    case incorrect = "incorrect"
    case tap = "tap"
    case celebration = "celebration"
    case pop = "pop"
    case whoosh = "whoosh"
}

// MARK: - Haptic Feedback Helper
struct HapticFeedback {
    private static var isEnabled: Bool {
        SoundManager.shared.hapticsEnabled
    }

    static func light() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    static func medium() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    static func heavy() {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    static func success() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    static func error() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    static func warning() {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
}
