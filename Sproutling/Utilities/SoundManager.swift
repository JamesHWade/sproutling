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

    // Settings - persisted via UserDefaults
    @AppStorage("soundEnabled") var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") var hapticsEnabled: Bool = true

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
