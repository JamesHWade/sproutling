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
    // MARK: - Multi-Profile Support
    // Note: CloudKit doesn't support unique constraints, using UUID for identification
    var profileId: UUID = UUID()
    var avatarIndex: Int = 0
    var backgroundIndex: Int = 0
    var createdAt: Date = Date()
    var lastModifiedAt: Date = Date()
    var isActive: Bool = false
    var sortOrder: Int = 0

    // MARK: - Profile Data
    var name: String = "Little Learner"
    var totalStars: Int = 0
    var streakDays: Int = 0
    var lastSessionDate: Date?

    // Store progress as JSON-encoded data since SwiftData doesn't support [Int: Int] directly
    var mathProgressData: Data?
    var readingProgressData: Data?

    init(
        name: String = "Little Learner",
        totalStars: Int = 0,
        streakDays: Int = 0,
        avatarIndex: Int = 0,
        backgroundIndex: Int = 0,
        isActive: Bool = false,
        sortOrder: Int = 0
    ) {
        self.profileId = UUID()
        self.avatarIndex = avatarIndex
        self.backgroundIndex = backgroundIndex
        self.createdAt = Date()
        self.lastModifiedAt = Date()
        self.isActive = isActive
        self.sortOrder = sortOrder
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
            id: profileId,
            name: name,
            avatarIndex: avatarIndex,
            backgroundIndex: backgroundIndex,
            totalStars: totalStars,
            streakDays: streakDays,
            mathProgress: mathProgress,
            readingProgress: readingProgress,
            isActive: isActive
        )
    }

    // MARK: - Update from ChildProfile

    func update(from profile: ChildProfile) {
        name = profile.name
        avatarIndex = profile.avatarIndex
        backgroundIndex = profile.backgroundIndex
        totalStars = profile.totalStars
        streakDays = profile.streakDays
        mathProgress = profile.mathProgress
        readingProgress = profile.readingProgress
        isActive = profile.isActive
        lastModifiedAt = Date()
    }

    // MARK: - Conflict Resolution (for CloudKit sync)

    func mergeWith(_ other: PersistedProfile) {
        // Take maximum stars (never lose progress)
        totalStars = max(totalStars, other.totalStars)
        streakDays = max(streakDays, other.streakDays)

        // Merge progress dictionaries, taking max stars per level
        var mergedMath = mathProgress
        for (level, stars) in other.mathProgress {
            mergedMath[level] = max(mergedMath[level] ?? 0, stars)
        }
        mathProgress = mergedMath

        var mergedReading = readingProgress
        for (level, stars) in other.readingProgress {
            mergedReading[level] = max(mergedReading[level] ?? 0, stars)
        }
        readingProgress = mergedReading

        // Name/avatar/background: last-write-wins based on lastModifiedAt
        if other.lastModifiedAt > lastModifiedAt {
            name = other.name
            avatarIndex = other.avatarIndex
            backgroundIndex = other.backgroundIndex
        }

        lastModifiedAt = Date()
    }
}
