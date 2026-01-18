//
//  ElevenLabsService.swift
//  Sproutling
//
//  API client for ElevenLabs text-to-speech
//

import Foundation

/// Service for communicating with the ElevenLabs TTS API
actor ElevenLabsService {
    static let shared = ElevenLabsService()

    private let baseURL = "https://api.elevenlabs.io/v1"
    private let session: URLSession

    // Voice IDs from ElevenLabs - curated for children's educational content
    enum Voice: String, CaseIterable, Identifiable {
        // Female voices
        case bella = "EXAVITQu4vr4xnSDxMaL"       // Bella - warm, gentle (default)
        case rachel = "21m00Tcm4TlvDq8ikWAM"     // Rachel - calm, clear
        case domi = "AZnzlk1XvdvUeBnXmlld"       // Domi - young, friendly
        case elli = "MF3mGyEYCl7XYWbV9V6O"       // Elli - young, expressive
        case charlotte = "XB0fDUnXU5powFXDhCwa"  // Charlotte - warm, Swedish accent
        case alice = "Xb7hH8MSUJpSbSDYk0k2"      // Alice - British, confident
        case matilda = "XrExE9yKIg1WjnnlVkGX"    // Matilda - warm, storyteller
        case lily = "pFZP5JQG7iQjIQuC4Bku"       // Lily - British, gentle
        case grace = "oWAxZDx7w5VEj9dCyTzz"      // Grace - Southern US, soothing
        case aria = "9BWtsMINqrJLrRacOk9x"       // Aria - expressive, engaging

        // Male voices
        case josh = "TxGEqnHWrfWFTfGW9XjX"       // Josh - warm, friendly
        case adam = "pNInz6obpgDQGcFmaJgB"       // Adam - clear, articulate
        case bill = "pqHfZKP75CvOlQylNhV4"       // Bill - American, trustworthy
        case george = "JBFqnCBsd6RMkjVDRZzb"     // George - British, warm
        case callum = "N2lVS1w4EtoT3dr4eOWO"     // Callum - Scottish, friendly
        case charlie = "IKne3meq5aSn9XLyUdCD"    // Charlie - Australian, casual
        case daniel = "onwK4e9ZLuTAKqWW03F9"     // Daniel - British, deep

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .bella: return "Bella"
            case .rachel: return "Rachel"
            case .domi: return "Domi"
            case .elli: return "Elli"
            case .charlotte: return "Charlotte"
            case .alice: return "Alice"
            case .matilda: return "Matilda"
            case .lily: return "Lily"
            case .grace: return "Grace"
            case .aria: return "Aria"
            case .josh: return "Josh"
            case .adam: return "Adam"
            case .bill: return "Bill"
            case .george: return "George"
            case .callum: return "Callum"
            case .charlie: return "Charlie"
            case .daniel: return "Daniel"
            }
        }

        var description: String {
            switch self {
            case .bella: return "Warm & gentle, like a kind teacher"
            case .rachel: return "Calm & clear, great for instructions"
            case .domi: return "Young & cheerful, playful energy"
            case .elli: return "Bright & expressive, full of wonder"
            case .charlotte: return "Warm Swedish accent, soothing"
            case .alice: return "British, confident & encouraging"
            case .matilda: return "Storyteller voice, great for reading"
            case .lily: return "Soft British accent, gentle & patient"
            case .grace: return "Southern US charm, warm & comforting"
            case .aria: return "Expressive & engaging, fun personality"
            case .josh: return "Friendly & supportive, like a big brother"
            case .adam: return "Clear & articulate, easy to understand"
            case .bill: return "Trustworthy American, calm & steady"
            case .george: return "Warm British, like a friendly uncle"
            case .callum: return "Friendly Scottish accent, cheerful"
            case .charlie: return "Casual Australian, fun & relaxed"
            case .daniel: return "Deep British voice, calm & reassuring"
            }
        }

        /// Whether this is a female voice (for filtering)
        var isFemale: Bool {
            switch self {
            case .bella, .rachel, .domi, .elli, .charlotte, .alice, .matilda, .lily, .grace, .aria:
                return true
            case .josh, .adam, .bill, .george, .callum, .charlie, .daniel:
                return false
            }
        }
    }

    /// Model IDs for speech generation
    enum Model: String {
        case flashV2_5 = "eleven_flash_v2_5"      // Fastest (~75ms), 32 languages - best for real-time
        case turboV2_5 = "eleven_turbo_v2_5"      // High quality + low latency, 32 languages
        case multilingualV2 = "eleven_multilingual_v2"  // Highest quality, rich emotion, 29 languages
    }

    /// Errors that can occur during TTS generation
    enum ElevenLabsError: LocalizedError {
        case noAPIKey
        case invalidURL
        case networkError(Error)
        case httpError(Int, String?)
        case noAudioData
        case rateLimited
        case unauthorized
        case insufficientCredits

        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "No ElevenLabs API key configured"
            case .invalidURL:
                return "Invalid URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .httpError(let code, let message):
                return "HTTP error \(code): \(message ?? "Unknown error")"
            case .noAudioData:
                return "No audio data received"
            case .rateLimited:
                return "Rate limited - too many requests"
            case .unauthorized:
                return "Invalid API key"
            case .insufficientCredits:
                return "Insufficient ElevenLabs credits"
            }
        }
    }

    /// Voice settings for fine-tuning output
    struct VoiceSettings: Codable {
        let stability: Double
        let similarityBoost: Double
        let style: Double?
        let useSpeakerBoost: Bool?
        let speed: Double?  // 0.7-1.2 range, default 1.0

        enum CodingKeys: String, CodingKey {
            case stability
            case similarityBoost = "similarity_boost"
            case style
            case useSpeakerBoost = "use_speaker_boost"
            case speed
        }

        /// Default settings optimized for children's educational content
        /// Calm, clear voice at a comfortable pace
        static let childFriendly = VoiceSettings(
            stability: 0.80,           // High stability for calm, clear speech
            similarityBoost: 0.75,     // Good voice quality
            style: 0.0,                // Neutral style - not too excited
            useSpeakerBoost: true,     // Enhanced clarity
            speed: 0.85                // Slightly slower for children
        )

        /// Fast settings for short prompts like numbers and letters
        static let quickPrompt = VoiceSettings(
            stability: 0.85,           // Very stable for short utterances
            similarityBoost: 0.75,
            style: 0.0,
            useSpeakerBoost: true,
            speed: 0.95
        )

        /// Warm encouragement - friendly but not over-the-top
        static let encouraging = VoiceSettings(
            stability: 0.75,           // Slightly more expressive but still calm
            similarityBoost: 0.75,
            style: 0.1,                // Minimal style variation
            useSpeakerBoost: true,
            speed: 0.9
        )
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public API

    /// Generate speech from text
    /// - Parameters:
    ///   - text: The text to convert to speech
    ///   - voice: The voice to use (defaults to Bella for warmth)
    ///   - model: The model to use (defaults to Flash v2.5 for speed)
    ///   - settings: Voice settings (defaults to child-friendly)
    /// - Returns: Audio data (MP3 format)
    func generateSpeech(
        text: String,
        voice: Voice = .bella,
        model: Model = .flashV2_5,
        settings: VoiceSettings = .childFriendly
    ) async throws -> Data {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            throw ElevenLabsError.noAPIKey
        }

        let urlString = "\(baseURL)/text-to-speech/\(voice.rawValue)"
        guard let url = URL(string: urlString) else {
            throw ElevenLabsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")

        var voiceSettingsDict: [String: Any] = [
            "stability": settings.stability,
            "similarity_boost": settings.similarityBoost,
            "style": settings.style ?? 0.0,
            "use_speaker_boost": settings.useSpeakerBoost ?? true
        ]

        // Add speed if specified (0.7-1.2 range)
        if let speed = settings.speed {
            voiceSettingsDict["speed"] = max(0.7, min(1.2, speed))
        }

        let body: [String: Any] = [
            "text": text,
            "model_id": model.rawValue,
            "voice_settings": voiceSettingsDict
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ElevenLabsError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.noAudioData
        }

        switch httpResponse.statusCode {
        case 200:
            guard !data.isEmpty else {
                throw ElevenLabsError.noAudioData
            }
            return data

        case 401:
            throw ElevenLabsError.unauthorized

        case 429:
            throw ElevenLabsError.rateLimited

        case 402:
            throw ElevenLabsError.insufficientCredits

        default:
            let message = String(data: data, encoding: .utf8)
            throw ElevenLabsError.httpError(httpResponse.statusCode, message)
        }
    }

    /// Fetch available voices from the API
    func fetchVoices() async throws -> [VoiceInfo] {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            throw ElevenLabsError.noAPIKey
        }

        guard let url = URL(string: "\(baseURL)/voices") else {
            throw ElevenLabsError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ElevenLabsError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ElevenLabsError.noAudioData
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw ElevenLabsError.unauthorized
            }
            let message = String(data: data, encoding: .utf8)
            throw ElevenLabsError.httpError(httpResponse.statusCode, message)
        }

        let decoder = JSONDecoder()
        let voicesResponse = try decoder.decode(VoicesResponse.self, from: data)
        return voicesResponse.voices
    }

    /// Result of API key validation
    enum ValidationResult {
        case valid
        case invalid
        case networkError(Error)
        case rateLimited
        case insufficientCredits

        var isValid: Bool {
            if case .valid = self { return true }
            return false
        }

        var userMessage: String? {
            switch self {
            case .valid:
                return nil
            case .invalid:
                return "Invalid API key. Please check and try again."
            case .networkError:
                return "Network error. Please check your connection."
            case .rateLimited:
                return "Too many requests. Please wait a moment."
            case .insufficientCredits:
                return "Insufficient ElevenLabs credits."
            }
        }
    }

    /// Check if the API is available and the key is valid
    /// Uses a minimal TTS request instead of /voices endpoint (which requires extra permissions)
    func validateAPIKey() async -> ValidationResult {
        do {
            // Try a minimal TTS request - this tests actual speech generation
            _ = try await generateSpeech(text: "Hi", voice: .bella, model: .flashV2_5, settings: .quickPrompt)
            return .valid
        } catch ElevenLabsError.unauthorized {
            return .invalid
        } catch ElevenLabsError.rateLimited {
            return .rateLimited
        } catch ElevenLabsError.insufficientCredits {
            return .insufficientCredits
        } catch ElevenLabsError.networkError(let error) {
            return .networkError(error)
        } catch ElevenLabsError.noAPIKey {
            return .invalid
        } catch {
            return .networkError(error)
        }
    }

    // MARK: - API Key Management

    private let apiKeyKeychainKey = "elevenlabs_api_key"

    /// Bundled API key for trial usage (obfuscated)
    /// Users can use ElevenLabs without setting up their own key
    private var bundledAPIKey: String? {
        // Simple XOR obfuscation - not secure but deters casual inspection
        // To update: use ElevenLabsService.obfuscate("new_key") and replace bytes
        let obfuscated: [UInt8] = [
            0x29, 0x31, 0x05, 0x63, 0x3B, 0x68, 0x6F, 0x69, 0x39, 0x6D,
            0x6D, 0x3E, 0x38, 0x63, 0x38, 0x3B, 0x6E, 0x68, 0x6D, 0x6C,
            0x6C, 0x38, 0x3B, 0x3C, 0x62, 0x3B, 0x3C, 0x39, 0x69, 0x3C,
            0x69, 0x3E, 0x6B, 0x6D, 0x6F, 0x63, 0x6E, 0x3C, 0x63, 0x68,
            0x6B, 0x6E, 0x62, 0x38, 0x68, 0x3F, 0x3B, 0x69, 0x3F, 0x63,
            0x6B
        ]

        guard !obfuscated.isEmpty else { return nil }
        return deobfuscate(obfuscated)
    }

    /// XOR key for obfuscation (simple deterrent, not security)
    private static let xorKey: UInt8 = 0x5A

    /// Helper to obfuscate an API key (call once to get bytes for bundledAPIKey)
    /// Use in debugger: `po ElevenLabsService.obfuscate("your_key")` then copy bytes
    private static func obfuscate(_ key: String) -> [UInt8] {
        return key.utf8.map { $0 ^ xorKey }
    }

    /// Deobfuscate the bundled key
    private func deobfuscate(_ bytes: [UInt8]) -> String? {
        let decoded = bytes.map { $0 ^ Self.xorKey }
        guard let result = String(bytes: decoded, encoding: .utf8), !result.isEmpty else {
            print("[ElevenLabsService] Deobfuscation failed - invalid bundled key bytes")
            return nil
        }
        return result
    }

    /// Get the API key - user's key takes priority, falls back to bundled
    func getAPIKey() -> String? {
        // Check for user's own key first
        if let userKey = getUserAPIKey() {
            return userKey
        }
        // Fall back to bundled key for trial usage
        return bundledAPIKey
    }

    /// Get only the user's stored API key (not bundled)
    func getUserAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.sproutling.app",
            kSecAttrAccount as String: apiKeyKeychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }

        return key
    }

    /// Save the user's API key to keychain
    @discardableResult
    func saveAPIKey(_ key: String) -> Bool {
        // Delete existing key
        deleteAPIKey()

        guard let keyData = key.data(using: .utf8) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.sproutling.app",
            kSecAttrAccount as String: apiKeyKeychainKey,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Delete the user's API key from keychain
    @discardableResult
    func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.sproutling.app",
            kSecAttrAccount as String: apiKeyKeychainKey
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Check if any API key is available (user's or bundled)
    func hasAPIKey() -> Bool {
        return getAPIKey() != nil
    }

    /// Check if user has their own API key configured
    func hasUserAPIKey() -> Bool {
        return getUserAPIKey() != nil
    }

    /// Check if currently using the bundled key (trial mode)
    func isUsingBundledKey() -> Bool {
        return getUserAPIKey() == nil && bundledAPIKey != nil
    }
}

// MARK: - Voice Info Response Models

struct VoiceInfo: Codable, Identifiable {
    let voiceId: String
    let name: String
    let category: String?
    let description: String?
    let labels: [String: String]?

    var id: String { voiceId }

    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case name
        case category
        case description
        case labels
    }
}

struct VoicesResponse: Codable {
    let voices: [VoiceInfo]
}
