//
//  PersistedProfile.swift
//  Sproutling
//
//  SwiftData model for persisting child profile
//

import Foundation
import SwiftData

@Model
final class PersistedProfile {
    var name: String
    var totalStars: Int
    var streakDays: Int
    var lastSessionDate: Date?

    // Store progress as JSON-encoded data since SwiftData doesn't support [Int: Int] directly
    var mathProgressData: Data?
    var readingProgressData: Data?

    init(name: String = "Little Learner", totalStars: Int = 0, streakDays: Int = 0) {
        self.name = name
        self.totalStars = totalStars
        self.streakDays = streakDays
        self.lastSessionDate = nil
        self.mathProgressData = nil
        self.readingProgressData = nil
    }

    // MARK: - Progress Encoding/Decoding

    var mathProgress: [Int: Int] {
        get {
            guard let data = mathProgressData else { return [:] }
            return (try? JSONDecoder().decode([Int: Int].self, from: data)) ?? [:]
        }
        set {
            mathProgressData = try? JSONEncoder().encode(newValue)
        }
    }

    var readingProgress: [Int: Int] {
        get {
            guard let data = readingProgressData else { return [:] }
            return (try? JSONDecoder().decode([Int: Int].self, from: data)) ?? [:]
        }
        set {
            readingProgressData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Streak Management

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastSession = lastSessionDate {
            let lastDay = calendar.startOfDay(for: lastSession)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 0 {
                // Same day, no change
            } else if daysDiff == 1 {
                // Consecutive day, increment streak
                streakDays += 1
            } else {
                // Streak broken, reset
                streakDays = 1
            }
        } else {
            // First session
            streakDays = 1
        }

        lastSessionDate = Date()
    }

    // MARK: - Convert to ChildProfile

    func toChildProfile() -> ChildProfile {
        ChildProfile(
            name: name,
            totalStars: totalStars,
            streakDays: streakDays,
            mathProgress: mathProgress,
            readingProgress: readingProgress
        )
    }

    // MARK: - Update from ChildProfile

    func update(from profile: ChildProfile) {
        name = profile.name
        totalStars = profile.totalStars
        streakDays = profile.streakDays
        mathProgress = profile.mathProgress
        readingProgress = profile.readingProgress
    }
}
