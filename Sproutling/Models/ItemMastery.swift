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

// MARK: - Growth Stage Enum

/// Represents the visual growth stage of a learning item in the garden metaphor
/// Maps to mastery levels and provides visual feedback to children
enum GrowthStage: String, CaseIterable, Codable {
    case seed       // 🌰 Not started - no attempts
    case planted    // 🌱 Learning - < 50% accuracy
    case growing    // 🌿 Improving - 50-79% accuracy
    case budding    // 🌷 Almost there - 80-89% accuracy
    case bloomed    // 🌸 Mastered - 90%+ accuracy, retained over time
    case wilting    // 🥀 Needs review - was mastered but declining

    /// The emoji representation of this growth stage
    var emoji: String {
        switch self {
        case .seed: return "🌰"
        case .planted: return "🌱"
        case .growing: return "🌿"
        case .budding: return "🌷"
        case .bloomed: return "🌸"
        case .wilting: return "🥀"
        }
    }

    /// Display name for the growth stage
    var displayName: String {
        switch self {
        case .seed: return "Seed"
        case .planted: return "Planted"
        case .growing: return "Growing"
        case .budding: return "Budding"
        case .bloomed: return "Bloomed"
        case .wilting: return "Needs Water"
        }
    }

    /// Color associated with this growth stage
    var color: Color {
        switch self {
        case .seed: return .brown
        case .planted: return .green.opacity(0.6)
        case .growing: return .green
        case .budding: return .pink.opacity(0.8)
        case .bloomed: return .pink
        case .wilting: return .orange
        }
    }

    /// Whether this stage represents mastery
    var isMastered: Bool {
        self == .bloomed
    }

    /// Whether this stage needs attention/review
    var needsAttention: Bool {
        self == .wilting || self == .seed
    }

    /// Order for sorting (lower = earlier stage)
    var sortOrder: Int {
        switch self {
        case .seed: return 0
        case .planted: return 1
        case .growing: return 2
        case .budding: return 3
        case .bloomed: return 4
        case .wilting: return 5  // Sort last so they stand out
        }
    }

    /// Short label for compact displays (no emoji needed when shown with emoji)
    var shortLabel: String {
        switch self {
        case .seed: return "new"
        case .planted: return "planted"
        case .growing: return "growing"
        case .budding: return "budding"
        case .bloomed: return "bloomed"
        case .wilting: return "thirsty"
        }
    }
}

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

    /// Unique identifier for the card content
    /// Format varies by activity type:
    /// - Numbers: "num_3_stars", "match_5", "count_10", "subit_3", "cmp_3_5"
    /// - Letters: "letter_A_apple", "letmatch_B", "blend_cat", "vocab_dog"
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
    /// Mastery = at least 2 successful reviews with good accuracy
    /// More achievable for young learners while still requiring demonstrated retention
    var isMastered: Bool {
        repetitions >= 2 && accuracy >= 90 && lastQuality >= 3
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

    /// Growth stage for the garden visualization
    /// Derived from accuracy and retention metrics
    /// Stages progress naturally as children practice and improve
    var growthStage: GrowthStage {
        // Check for wilting first - was previously mastered but now overdue
        if let lastReview = lastReviewDate,
           let nextReview = nextReviewDate,
           isMastered || (repetitions >= 2 && accuracy >= 80) {
            // Item was doing well but is now significantly overdue
            let daysSinceReview = Calendar.current.dateComponents([.day], from: lastReview, to: Date()).day ?? 0
            let daysOverdue = Calendar.current.dateComponents([.day], from: nextReview, to: Date()).day ?? 0

            // Wilting if overdue by more than 3 days and was previously doing well
            if daysOverdue > 3 && daysSinceReview > 7 {
                return .wilting
            }
        }

        // No attempts yet = seed
        guard totalAttempts > 0 else { return .seed }

        // Check accuracy thresholds
        let acc = accuracy

        // Bloomed: 90%+ accuracy with good retention
        // More achievable for young learners: 2+ reps is enough
        if acc >= 90 && repetitions >= 2 {
            return .bloomed
        }

        // Budding: 80-89% accuracy OR 90%+ with only 1 rep
        if acc >= 80 || (acc >= 90 && repetitions == 1) {
            return .budding
        }

        // Growing: 50-79% accuracy
        if acc >= 50 {
            return .growing
        }

        // Planted: < 50% accuracy but has attempts
        return .planted
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
