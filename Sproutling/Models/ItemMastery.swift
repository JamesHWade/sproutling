//
//  ItemMastery.swift
//  Sproutling
//
//  SwiftData model for tracking mastery of individual learning items
//  using a simplified SM-2 spaced repetition algorithm adapted for young learners
//

import Foundation
import SwiftData
import SwiftUI

/// Tracks mastery state for a single learning item (e.g., "number 3 with apples" or "letter A")
/// Uses a child-friendly adaptation of the SM-2 spaced repetition algorithm
@Model
final class ItemMastery {
    // MARK: - Identification

    /// Profile that owns this mastery record
    var profileId: UUID = UUID()

    /// Subject: "math" or "reading"
    var subject: String = ""

    /// Level where this item appears (1-6)
    var levelId: Int = 0

    /// Unique identifier for the card content (e.g., "num_3_apples", "letter_A_apple")
    var itemId: String = ""

    /// Activity type string (e.g., "numberWithObjects", "letterCard")
    var activityType: String = ""

    // MARK: - Spaced Repetition Metrics (SM-2 inspired)

    /// Number of days until next review (starts at 1)
    var interval: Int = 1

    /// Ease factor - how easily this item is remembered (1.3 to 2.5, starts at 2.0)
    /// Lower = harder to remember, reviewed more often
    /// Higher = easier, reviewed less frequently
    var easeFactor: Double = 2.0

    /// Number of successful consecutive reviews
    var repetitions: Int = 0

    /// Quality score from last review (0-5, SM-2 scale)
    /// 0 = complete failure, 3 = correct with difficulty, 5 = perfect recall
    var lastQuality: Int = 0

    // MARK: - Review Scheduling

    /// When this item was last reviewed
    var lastReviewDate: Date?

    /// When this item should next be reviewed
    var nextReviewDate: Date?

    /// When this mastery record was created
    var createdAt: Date = Date()

    /// When this record was last updated
    var updatedAt: Date = Date()

    // MARK: - Performance History

    /// Total number of times this item has been shown
    var totalAttempts: Int = 0

    /// Number of correct responses
    var correctAttempts: Int = 0

    /// Average response time in seconds (for future adaptive features)
    var averageResponseTime: Double = 0.0

    // MARK: - Initialization

    init(
        profileId: UUID,
        subject: String,
        levelId: Int,
        itemId: String,
        activityType: String
    ) {
        self.profileId = profileId
        self.subject = subject
        self.levelId = levelId
        self.itemId = itemId
        self.activityType = activityType
        self.interval = 1
        self.easeFactor = 2.0  // Child-friendly: start slightly lower than SM-2's 2.5
        self.repetitions = 0
        self.lastQuality = 0
        self.lastReviewDate = nil
        self.nextReviewDate = Date() // Due immediately for new items
        self.createdAt = Date()
        self.updatedAt = Date()
        self.totalAttempts = 0
        self.correctAttempts = 0
        self.averageResponseTime = 0.0
    }

    // MARK: - Computed Properties

    /// Accuracy as a percentage (0-100)
    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(totalAttempts) * 100
    }

    /// Whether this item is considered "mastered" (strong retention)
    /// Mastery = at least 3 successful reviews with ease factor >= 2.0
    var isMastered: Bool {
        repetitions >= 3 && easeFactor >= 2.0 && lastQuality >= 3
    }

    /// Whether this item is due for review
    var isDue: Bool {
        guard let nextReview = nextReviewDate else { return true }
        return nextReview <= Date()
    }

    /// Whether this item is struggling (needs extra practice)
    var isStruggling: Bool {
        easeFactor < 1.5 || (totalAttempts >= 3 && accuracy < 50)
    }

    /// Mastery level as a simple 0-3 scale for UI display
    var masteryLevel: Int {
        if isMastered { return 3 }
        if repetitions >= 2 && easeFactor >= 1.8 { return 2 }
        if repetitions >= 1 { return 1 }
        return 0
    }
}

// MARK: - Item ID Generation

extension ItemMastery {
    /// Generates a unique item ID from an ActivityCard
    /// Format varies by activity type to capture the essential learning concept
    static func generateItemId(from card: ActivityCard) -> String {
        switch card.type {
        case .numberWithObjects:
            let num = card.number ?? 0
            let obj = card.objects ?? "items"
            return "num_\(num)_\(obj)"

        case .numberMatching:
            let num = card.number ?? 0
            return "match_\(num)"

        case .countingTouch:
            let num = card.number ?? 0
            return "count_\(num)"

        case .subitizing:
            let num = card.number ?? 0
            return "subit_\(num)"

        case .comparison:
            let left = card.leftCount ?? 0
            let right = card.rightCount ?? 0
            return "cmp_\(left)_\(right)"

        case .letterCard:
            let letter = card.letter ?? "?"
            let word = card.word ?? ""
            return "letter_\(letter)_\(word.lowercased())"

        case .letterMatching:
            let letter = card.letter ?? "?"
            return "letmatch_\(letter)"

        case .phonicsBlending:
            let word = card.word ?? "word"
            return "blend_\(word.lowercased())"

        case .vocabularyCard:
            let word = card.word ?? "word"
            return "vocab_\(word.lowercased())"
        }
    }
}
