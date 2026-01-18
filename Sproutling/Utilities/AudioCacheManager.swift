//
//  AudioCacheManager.swift
//  Sproutling
//
//  Caches generated TTS audio to minimize API calls
//

import Foundation
import CryptoKit

/// Manages caching of TTS-generated audio files
actor AudioCacheManager {
    static let shared = AudioCacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheAge: TimeInterval = 30 * 24 * 60 * 60  // 30 days
    private var memoryCache: [String: Data] = [:]
    private let maxMemoryCacheSize = 50  // Max items in memory

    private init() {
        // Use Caches directory for audio files
        let cachesPath = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesPath.appendingPathComponent("TTSAudio", isDirectory: true)

        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Cache Key Generation

    /// Generate a unique cache key from text and voice
    func cacheKey(for text: String, voiceId: String) -> String {
        let combined = "\(text)_\(voiceId)"
        let hash = SHA256.hash(data: combined.data(using: .utf8)!)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Cache Operations

    /// Get cached audio data if available
    func getCached(text: String, voiceId: String) async -> Data? {
        let key = cacheKey(for: text, voiceId: voiceId)

        // Check memory cache first
        if let data = memoryCache[key] {
            return data
        }

        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key + ".mp3")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        // Check if cache is expired
        if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
           let modDate = attributes[.modificationDate] as? Date {
            if Date().timeIntervalSince(modDate) > maxCacheAge {
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
        }

        // Load from disk and add to memory cache
        if let data = try? Data(contentsOf: fileURL) {
            await addToMemoryCache(key: key, data: data)
            return data
        }

        return nil
    }

    /// Cache audio data
    func cache(data: Data, text: String, voiceId: String) async {
        let key = cacheKey(for: text, voiceId: voiceId)
        let fileURL = cacheDirectory.appendingPathComponent(key + ".mp3")

        // Save to disk
        do {
            try data.write(to: fileURL)
        } catch {
            print("Failed to cache audio: \(error)")
        }

        // Add to memory cache
        await addToMemoryCache(key: key, data: data)
    }

    /// Check if audio is cached
    func isCached(text: String, voiceId: String) async -> Bool {
        let key = cacheKey(for: text, voiceId: voiceId)

        if memoryCache[key] != nil {
            return true
        }

        let fileURL = cacheDirectory.appendingPathComponent(key + ".mp3")
        return fileManager.fileExists(atPath: fileURL.path)
    }

    // MARK: - Memory Cache Management

    private func addToMemoryCache(key: String, data: Data) async {
        // Evict oldest items if at capacity
        if memoryCache.count >= maxMemoryCacheSize {
            // Remove ~25% of items
            let keysToRemove = Array(memoryCache.keys.prefix(maxMemoryCacheSize / 4))
            for k in keysToRemove {
                memoryCache.removeValue(forKey: k)
            }
        }

        memoryCache[key] = data
    }

    /// Clear memory cache (called on memory warning)
    func clearMemoryCache() async {
        memoryCache.removeAll()
    }

    // MARK: - Cache Maintenance

    /// Clear all cached audio
    func clearAllCache() async {
        memoryCache.removeAll()

        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            for file in files {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    /// Clear expired cache entries
    func clearExpiredCache() async {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }

        let now = Date()

        for fileURL in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let modDate = attributes[.modificationDate] as? Date {
                if now.timeIntervalSince(modDate) > maxCacheAge {
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        }
    }

    /// Get total cache size in bytes
    func getCacheSize() async -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        var totalSize: Int64 = 0

        for fileURL in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }

        return totalSize
    }

    /// Get number of cached items
    func getCacheCount() async -> Int {
        let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        return files?.count ?? 0
    }

    // MARK: - Preloading

    /// Common phrases to preload for instant playback
    static let commonPhrases: [String] = {
        var phrases: [String] = []

        // Numbers 1-20
        for i in 1...20 {
            phrases.append(String(i))
        }

        // Letter names A-Z
        for letter in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            phrases.append(String(letter))
        }

        // Common encouragement (without names - those are dynamic)
        phrases.append(contentsOf: [
            "Great job!",
            "Excellent!",
            "You did it!",
            "Keep going!",
            "Try again!",
            "Almost there!",
            "That's right!",
            "Well done!",
            "Perfect!",
            "Wonderful!",
            "Let's try another one!",
            "You're doing great!"
        ])

        // Common instructions
        phrases.append(contentsOf: [
            "Tap the correct answer",
            "How many do you see?",
            "Which number is this?",
            "What letter is this?",
            "Listen carefully",
            "Count with me"
        ])

        return phrases
    }()

    /// Preload common phrases in background
    func preloadCommonPhrases(voiceId: String, generator: (String) async throws -> Data) async {
        for phrase in Self.commonPhrases {
            // Skip if already cached
            if await isCached(text: phrase, voiceId: voiceId) {
                continue
            }

            // Generate and cache
            do {
                let data = try await generator(phrase)
                await cache(data: data, text: phrase, voiceId: voiceId)
            } catch {
                // Log but don't fail - preloading is best-effort
                print("Failed to preload '\(phrase)': \(error)")
            }

            // Small delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 100_000_000)  // 100ms
        }
    }
}
