//
//  Models.swift
//  Sproutling
//
//  Data models for the app
//

import Foundation
import SwiftUI

// MARK: - Screen Navigation
enum Screen: Equatable {
    case home
    case progress
    case settings
    case subjectSelection(Subject)
    case lesson(Subject, Int)
    case lessonComplete(Subject, Int)
}

// MARK: - Subjects
enum Subject: String, CaseIterable, Identifiable {
    case math = "Numbers"
    case reading = "Letters"

    var id: String { rawValue }

    /// SF Symbol icon name for the subject
    var iconName: String {
        switch self {
        case .math: return "number.circle.fill"
        case .reading: return "book.fill"
        }
    }

    /// Emoji icon (kept for backwards compatibility and counting objects)
    var icon: String {
        switch self {
        case .math: return "🔢"
        case .reading: return "📚"
        }
    }

    var title: String {
        switch self {
        case .math: return "Numbers & Counting"
        case .reading: return "Letters & Phonics"
        }
    }

    var subtitle: String {
        switch self {
        case .math: return "Count and learn 1-10"
        case .reading: return "ABCs and phonics"
        }
    }

    var gradient: [Color] {
        switch self {
        case .math: return [.blue, .purple]
        case .reading: return [.pink, .orange]
        }
    }

    var lightGradient: [Color] {
        switch self {
        case .math: return [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]
        case .reading: return [Color.pink.opacity(0.2), Color.orange.opacity(0.2)]
        }
    }
}

// MARK: - Lesson Level
struct LessonLevel: Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    var isUnlocked: Bool
    var starsEarned: Int

    static func mathLevels() -> [LessonLevel] {
        [
            LessonLevel(id: 1, title: "Numbers 1-5", subtitle: "Learn to count!", isUnlocked: true, starsEarned: 0),
            LessonLevel(id: 2, title: "Numbers 6-10", subtitle: "Count higher!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 3, title: "Counting Objects", subtitle: "Count real things", isUnlocked: false, starsEarned: 0)
        ]
    }

    static func readingLevels() -> [LessonLevel] {
        [
            LessonLevel(id: 1, title: "Letters A-D", subtitle: "First letters!", isUnlocked: true, starsEarned: 0),
            LessonLevel(id: 2, title: "Letters E-H", subtitle: "More letters!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 3, title: "First Words", subtitle: "Read simple words", isUnlocked: false, starsEarned: 0)
        ]
    }
}

// MARK: - Activity Types
enum ActivityType {
    case numberWithObjects
    case numberMatching
    case countingTouch
    case letterCard
    case letterMatching
    case phonicsBlending
}

// MARK: - Activity Card Data
struct ActivityCard: Identifiable {
    let id = UUID()
    let type: ActivityType

    // For number activities
    var number: Int?
    var objects: String?
    var numberOptions: [Int]?

    // For letter activities
    var letter: String?
    var word: String?
    var emoji: String?
    var sound: String?
    var letterOptions: [String]?
    var letters: [String]?
}

// MARK: - Mascot Emotions
enum MascotEmotion: String, CaseIterable {
    case happy
    case excited
    case thinking
    case proud
    case encouraging

    /// SF Symbol icon name for the emotion
    var iconName: String {
        switch self {
        case .happy: return "face.smiling.fill"
        case .excited: return "hands.clap.fill"
        case .thinking: return "bubble.left.and.text.bubble.right.fill"
        case .proud: return "star.circle.fill"
        case .encouraging: return "hand.thumbsup.fill"
        }
    }

    /// Gradient colors for the emotion
    var colors: [Color] {
        switch self {
        case .happy: return [.yellow, .orange]
        case .excited: return [.pink, .purple]
        case .thinking: return [.blue, .cyan]
        case .proud: return [.yellow, Color(red: 1.0, green: 0.75, blue: 0.0)]
        case .encouraging: return [.green, .teal]
        }
    }
}

// MARK: - Object Emojis for Counting
struct CountingObjects {
    static let items: [String: String] = [
        "apples": "🍎",
        "bananas": "🍌",
        "stars": "⭐",
        "hearts": "❤️",
        "fish": "🐟",
        "butterflies": "🦋",
        "flowers": "🌸",
        "birds": "🐦",
        "cookies": "🍪"
    ]

    static func emoji(for name: String) -> String {
        items[name] ?? "🔵"
    }
}

// MARK: - Child Profile
struct ChildProfile {
    var name: String
    var totalStars: Int
    var streakDays: Int
    var mathProgress: [Int: Int] // level: stars
    var readingProgress: [Int: Int]

    static var sample: ChildProfile {
        ChildProfile(
            name: "Emma",
            totalStars: 7,
            streakDays: 3,
            mathProgress: [:],
            readingProgress: [:]
        )
    }
}
