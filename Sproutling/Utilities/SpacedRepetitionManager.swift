//
//  SpacedRepetitionManager.swift
//  Sproutling
//
//  Manages spaced repetition scheduling using a child-friendly SM-2 adaptation
//  Research shows spaced repetition improves retention significantly in young learners
//

import Foundation
import SwiftData
import SwiftUI

/// Manages spaced repetition for learning items
/// Uses a simplified SM-2 algorithm adapted for preschool learners:
/// - Shorter initial intervals (1-3 days vs 1-6 days)
/// - Gentler ease factor adjustments
/// - Capped maximum intervals (30 days vs unlimited)
/// - Extra support for struggling items
@MainActor
class SpacedRepetitionManager {
    static let shared = SpacedRepetitionManager()

    // MARK: - Constants (Child-Friendly SM-2 Adaptation)

    /// Minimum ease factor (prevents items from becoming impossibly hard)
    private let minEaseFactor: Double = 1.3

    /// Maximum ease factor
    private let maxEaseFactor: Double = 2.5

    /// Starting ease factor (lower than SM-2's 2.5 for more initial reviews)
    private let initialEaseFactor: Double = 2.0

    /// Maximum interval in days (capped for young learners)
    private let maxInterval: Int = 30

    /// Minimum quality score to consider a response "correct"
    private let passingQuality: Int = 3

    /// Target percentage of review items in a lesson (20%)
    private let reviewRatio: Double = 0.2

    private init() {}

    // MARK: - Quality Score Mapping

    /// Converts a simple correct/incorrect response to an SM-2 quality score
    /// - Parameters:
    ///   - isCorrect: Whether the answer was correct
    ///   - attempts: Number of attempts before correct (1 = first try)
    ///   - responseTime: Time taken to respond in seconds
    /// - Returns: Quality score 0-5
    func calculateQuality(
        isCorrect: Bool,
        attempts: Int = 1,
        responseTime: Double = 0
    ) -> Int {
        if !isCorrect {
            // Incorrect answers
            if attempts >= 3 {
                return 0  // Complete failure after multiple tries
            } else {
                return 1  // Incorrect but still trying
            }
        }

        // Correct answers - grade by attempts and speed
        switch attempts {
        case 1:
            // First try correct
            if responseTime > 0 && responseTime < 3 {
                return 5  // Perfect - quick and correct
            } else if responseTime > 0 && responseTime < 6 {
                return 4  // Good - correct with some thought
            } else {
                return 4  // Correct first try (no timing data)
            }
        case 2:
            return 3  // Correct on second try
        default:
            return 2  // Eventually correct after multiple attempts
        }
    }

    // MARK: - SM-2 Algorithm

    /// Updates mastery metrics after a review using the SM-2 algorithm
    /// - Parameters:
    ///   - mastery: The ItemMastery record to update
    ///   - quality: Quality score 0-5
    func updateMastery(_ mastery: ItemMastery, quality: Int) {
        let q = min(5, max(0, quality))

        // Update attempt counters
        mastery.totalAttempts += 1
        if q >= passingQuality {
            mastery.correctAttempts += 1
        }

        // SM-2 Algorithm
        if q >= passingQuality {
            // Correct response - increase interval
            switch mastery.repetitions {
            case 0:
                mastery.interval = 1  // First success: review tomorrow
            case 1:
                mastery.interval = 3  // Second success: 3 days (gentler than SM-2's 6)
            default:
                // Subsequent: multiply by ease factor
                let newInterval = Double(mastery.interval) * mastery.easeFactor
                mastery.interval = min(maxInterval, Int(newInterval.rounded()))
            }
            mastery.repetitions += 1
        } else {
            // Incorrect response - reset interval
            mastery.repetitions = 0
            mastery.interval = 1  // Review tomorrow
        }

        // Update ease factor using SM-2 formula (with gentler adjustments for kids)
        // EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
        // We use a dampened version: multiply adjustment by 0.7
        let efAdjustment = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        let dampenedAdjustment = efAdjustment * 0.7  // Gentler for young learners
        mastery.easeFactor = max(minEaseFactor, min(maxEaseFactor, mastery.easeFactor + dampenedAdjustment))

        // Update scheduling
        mastery.lastQuality = q
        mastery.lastReviewDate = Date()
        mastery.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: mastery.interval,
            to: Date()
        )
        mastery.updatedAt = Date()
    }

    // MARK: - Lesson Generation

    /// Gets cards for a lesson, mixing review items with new content
    /// - Parameters:
    ///   - subject: The subject (math or reading)
    ///   - level: The lesson level
    ///   - profileId: The current profile's ID
    ///   - modelContext: SwiftData model context
    /// - Returns: Array of activity cards with review items interspersed
    func getCardsWithReview(
        for subject: Subject,
        level: Int,
        profileId: UUID,
        modelContext: ModelContext
    ) -> [ActivityCard] {
        // Get base cards from curriculum
        let allCards = CurriculumLoader.shared.getCards(for: subject, level: level)

        // Fetch due review items for this profile and subject
        let subjectString = subject == .math ? "math" : "reading"
        let dueItems = fetchDueItems(
            profileId: profileId,
            subject: subjectString,
            modelContext: modelContext
        )

        // If no due items, return original cards
        guard !dueItems.isEmpty else {
            return allCards
        }

        // Find matching cards for due items
        var reviewCards: [ActivityCard] = []
        for item in dueItems {
            // Try to find a matching card in the curriculum
            if let matchingCard = findCard(for: item, in: allCards) {
                reviewCards.append(matchingCard)
            }
        }

        // Calculate how many review cards to include (target 20% of lesson)
        let totalCards = allCards.count
        let maxReviewCards = max(1, Int(Double(totalCards) * reviewRatio))
        let reviewToInclude = min(reviewCards.count, maxReviewCards)

        // Sort review cards by priority (struggling items first, then by due date)
        let prioritizedReviews = reviewCards
            .sorted { item1, item2 in
                let mastery1 = dueItems.first { ItemMastery.generateItemId(from: item1) == $0.itemId }
                let mastery2 = dueItems.first { ItemMastery.generateItemId(from: item2) == $0.itemId }

                // Struggling items first
                if mastery1?.isStruggling == true && mastery2?.isStruggling != true {
                    return true
                }
                if mastery2?.isStruggling == true && mastery1?.isStruggling != true {
                    return false
                }

                // Then by due date (most overdue first)
                let date1 = mastery1?.nextReviewDate ?? Date.distantFuture
                let date2 = mastery2?.nextReviewDate ?? Date.distantFuture
                return date1 < date2
            }
            .prefix(reviewToInclude)

        // Interleave review cards throughout the lesson
        return interleaveCards(
            newCards: allCards,
            reviewCards: Array(prioritizedReviews)
        )
    }

    /// Interleaves review cards throughout a lesson
    /// Places review cards at regular intervals to space them out
    private func interleaveCards(
        newCards: [ActivityCard],
        reviewCards: [ActivityCard]
    ) -> [ActivityCard] {
        guard !reviewCards.isEmpty else { return newCards }

        var result = newCards
        let totalCards = newCards.count + reviewCards.count

        // Calculate positions for review cards (spread evenly)
        let spacing = totalCards / (reviewCards.count + 1)

        for (index, reviewCard) in reviewCards.enumerated() {
            let position = min((index + 1) * spacing, result.count)
            result.insert(reviewCard, at: position)
        }

        return result
    }

    // MARK: - Data Access

    /// Fetches all due review items for a profile
    func fetchDueItems(
        profileId: UUID,
        subject: String,
        modelContext: ModelContext
    ) -> [ItemMastery] {
        let now = Date()

        let predicate = #Predicate<ItemMastery> { item in
            item.profileId == profileId &&
            item.subject == subject
        }

        var descriptor = FetchDescriptor<ItemMastery>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.nextReviewDate)]

        do {
            let allItems = try modelContext.fetch(descriptor)
            // Filter for due items (nextReviewDate <= now)
            return allItems.filter { item in
                guard let nextReview = item.nextReviewDate else { return true }
                return nextReview <= now
            }
        } catch {
            print("SpacedRepetitionManager: Error fetching due items - \(error)")
            return []
        }
    }

    /// Fetches or creates a mastery record for a specific item
    func getOrCreateMastery(
        profileId: UUID,
        card: ActivityCard,
        subject: Subject,
        level: Int,
        modelContext: ModelContext
    ) -> ItemMastery {
        let itemId = ItemMastery.generateItemId(from: card)
        let subjectString = subject == .math ? "math" : "reading"
        let activityType = card.type.stringValue

        // Try to find existing record
        let predicate = #Predicate<ItemMastery> { item in
            item.profileId == profileId &&
            item.itemId == itemId
        }

        var descriptor = FetchDescriptor<ItemMastery>(predicate: predicate)
        descriptor.fetchLimit = 1

        do {
            if let existing = try modelContext.fetch(descriptor).first {
                return existing
            }
        } catch {
            print("SpacedRepetitionManager: Error fetching mastery - \(error)")
        }

        // Create new record
        let newMastery = ItemMastery(
            profileId: profileId,
            subject: subjectString,
            levelId: level,
            itemId: itemId,
            activityType: activityType
        )
        modelContext.insert(newMastery)
        return newMastery
    }

    /// Finds a card in the curriculum that matches a mastery record
    private func findCard(for mastery: ItemMastery, in cards: [ActivityCard]) -> ActivityCard? {
        cards.first { card in
            ItemMastery.generateItemId(from: card) == mastery.itemId
        }
    }

    // MARK: - Analytics

    /// Gets mastery statistics for a profile
    func getMasteryStats(
        profileId: UUID,
        subject: String,
        modelContext: ModelContext
    ) -> MasteryStats {
        let predicate = #Predicate<ItemMastery> { item in
            item.profileId == profileId &&
            item.subject == subject
        }

        let descriptor = FetchDescriptor<ItemMastery>(predicate: predicate)

        do {
            let items = try modelContext.fetch(descriptor)

            let mastered = items.filter { $0.isMastered }.count
            let struggling = items.filter { $0.isStruggling }.count
            let dueNow = items.filter { $0.isDue }.count
            let totalAccuracy = items.isEmpty ? 0 :
                items.map { $0.accuracy }.reduce(0, +) / Double(items.count)

            return MasteryStats(
                totalItems: items.count,
                masteredItems: mastered,
                strugglingItems: struggling,
                dueForReview: dueNow,
                overallAccuracy: totalAccuracy
            )
        } catch {
            print("SpacedRepetitionManager: Error fetching stats - \(error)")
            return MasteryStats(
                totalItems: 0,
                masteredItems: 0,
                strugglingItems: 0,
                dueForReview: 0,
                overallAccuracy: 0
            )
        }
    }
}

// MARK: - Supporting Types

/// Statistics about mastery progress
struct MasteryStats {
    let totalItems: Int
    let masteredItems: Int
    let strugglingItems: Int
    let dueForReview: Int
    let overallAccuracy: Double

    var masteryPercentage: Double {
        guard totalItems > 0 else { return 0 }
        return Double(masteredItems) / Double(totalItems) * 100
    }
}
