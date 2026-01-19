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
    case readyCheck(Subject, Int)
    case profileSelection
    case profileManagement
    case timeForBreak
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
            LessonLevel(id: 1, title: "Numbers 1-3", subtitle: "Learn to count!", isUnlocked: true, starsEarned: 0),
            LessonLevel(id: 2, title: "Numbers 4-5", subtitle: "Count higher!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 3, title: "Numbers 6-10", subtitle: "Count to ten!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 4, title: "Numbers 11-13", subtitle: "Teen numbers!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 5, title: "Numbers 14-17", subtitle: "Keep counting!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 6, title: "Numbers 18-20", subtitle: "Count to twenty!", isUnlocked: false, starsEarned: 0)
        ]
    }

    static func readingLevels() -> [LessonLevel] {
        [
            LessonLevel(id: 1, title: "Letters A-D", subtitle: "First letters!", isUnlocked: true, starsEarned: 0),
            LessonLevel(id: 2, title: "Letters E-H", subtitle: "More letters!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 3, title: "Letters I-L", subtitle: "Keep learning!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 4, title: "Letters M-P", subtitle: "Halfway there!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 5, title: "Letters Q-T", subtitle: "Almost done!", isUnlocked: false, starsEarned: 0),
            LessonLevel(id: 6, title: "Letters U-Z", subtitle: "Finish the alphabet!", isUnlocked: false, starsEarned: 0)
        ]
    }
}

// MARK: - Activity Types
enum ActivityType {
    // Math activities
    case numberWithObjects
    case numberMatching
    case countingTouch
    case subitizing          // Quick recognition of small quantities (1-5)
    case comparison          // Compare two groups (more/less/same)

    // Reading activities
    case letterCard
    case letterMatching
    case phonicsBlending
    case vocabularyCard      // Picture + word vocabulary building
}

// MARK: - Activity Card Data
struct ActivityCard: Identifiable {
    let id = UUID()
    let type: ActivityType

    // For number activities
    var number: Int?
    var objects: String?
    var numberOptions: [Int]?

    // For comparison activities
    var leftCount: Int?
    var rightCount: Int?
    var leftObjects: String?
    var rightObjects: String?

    // For letter activities
    var letter: String?
    var word: String?
    var emoji: String?
    var sound: String?
    var letterOptions: [String]?
    var letters: [String]?

    // For vocabulary activities
    var category: String?
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
struct ChildProfile: Identifiable, Equatable {
    var id: UUID
    var name: String
    var avatarIndex: Int
    var backgroundIndex: Int
    var totalStars: Int
    var streakDays: Int
    var mathProgress: [Int: Int] // level: stars
    var readingProgress: [Int: Int]
    var isActive: Bool

    init(
        id: UUID = UUID(),
        name: String = "Little Learner",
        avatarIndex: Int = 0,
        backgroundIndex: Int = 0,
        totalStars: Int = 0,
        streakDays: Int = 0,
        mathProgress: [Int: Int] = [:],
        readingProgress: [Int: Int] = [:],
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.avatarIndex = avatarIndex
        self.backgroundIndex = backgroundIndex
        self.totalStars = totalStars
        self.streakDays = streakDays
        self.mathProgress = mathProgress
        self.readingProgress = readingProgress
        self.isActive = isActive
    }

    static var sample: ChildProfile {
        ChildProfile(
            id: UUID(),
            name: "Emma",
            avatarIndex: 0,
            backgroundIndex: 0,
            totalStars: 7,
            streakDays: 3,
            mathProgress: [:],
            readingProgress: [:],
            isActive: true
        )
    }
}

// MARK: - Profile Backgrounds (organized by color family)
struct ProfileBackground: Equatable {
    let name: String
    let colors: [Color]
    let family: BackgroundFamily

    enum BackgroundFamily: String, CaseIterable {
        case warm = "Warm"
        case cool = "Cool"
        case vibrant = "Vibrant"
        case pastel = "Pastel"
        case dark = "Dark"
    }

    static let allBackgrounds: [ProfileBackground] = [
        // Warm
        ProfileBackground(name: "Sunset", colors: [.orange, .pink, .purple], family: .warm),
        ProfileBackground(name: "Peach", colors: [.orange, .pink], family: .warm),
        ProfileBackground(name: "Golden", colors: [.yellow, .orange], family: .warm),
        ProfileBackground(name: "Autumn", colors: [.red, .orange, .yellow], family: .warm),
        ProfileBackground(name: "Coral", colors: [Color(red: 1, green: 0.5, blue: 0.4), .pink], family: .warm),

        // Cool
        ProfileBackground(name: "Ocean", colors: [.cyan, .blue, .indigo], family: .cool),
        ProfileBackground(name: "Sky", colors: [.cyan, .blue], family: .cool),
        ProfileBackground(name: "Mint", colors: [.mint, .teal, .cyan], family: .cool),
        ProfileBackground(name: "Arctic", colors: [.white, .cyan, .blue], family: .cool),
        ProfileBackground(name: "Forest", colors: [.green, .teal], family: .cool),

        // Vibrant
        ProfileBackground(name: "Rainbow", colors: [.red, .orange, .yellow, .green, .blue, .purple], family: .vibrant),
        ProfileBackground(name: "Candy", colors: [.pink, .purple, .blue], family: .vibrant),
        ProfileBackground(name: "Neon", colors: [.green, .cyan, .blue], family: .vibrant),
        ProfileBackground(name: "Electric", colors: [.purple, .pink, .orange], family: .vibrant),
        ProfileBackground(name: "Tropical", colors: [.pink, .orange, .yellow], family: .vibrant),

        // Pastel
        ProfileBackground(name: "Cotton Candy", colors: [Color(red: 1, green: 0.8, blue: 0.9), Color(red: 0.8, green: 0.9, blue: 1)], family: .pastel),
        ProfileBackground(name: "Lavender", colors: [Color(red: 0.9, green: 0.8, blue: 1), Color(red: 0.8, green: 0.7, blue: 0.9)], family: .pastel),
        ProfileBackground(name: "Seafoam", colors: [Color(red: 0.8, green: 1, blue: 0.9), Color(red: 0.7, green: 0.9, blue: 0.9)], family: .pastel),
        ProfileBackground(name: "Buttercream", colors: [Color(red: 1, green: 1, blue: 0.8), Color(red: 1, green: 0.9, blue: 0.8)], family: .pastel),
        ProfileBackground(name: "Blush", colors: [Color(red: 1, green: 0.85, blue: 0.85), Color(red: 1, green: 0.8, blue: 0.9)], family: .pastel),

        // Dark
        ProfileBackground(name: "Galaxy", colors: [.purple, .indigo, Color(red: 0.1, green: 0.1, blue: 0.2)], family: .dark),
        ProfileBackground(name: "Midnight", colors: [.indigo, Color(red: 0.1, green: 0.1, blue: 0.3)], family: .dark),
        ProfileBackground(name: "Space", colors: [Color(red: 0.1, green: 0.1, blue: 0.2), .purple, .pink], family: .dark),
        ProfileBackground(name: "Deep Sea", colors: [.blue, Color(red: 0, green: 0.2, blue: 0.4)], family: .dark),
        ProfileBackground(name: "Twilight", colors: [.orange, .purple, .indigo], family: .dark),
    ]

    static func backgrounds(for family: BackgroundFamily) -> [ProfileBackground] {
        allBackgrounds.filter { $0.family == family }
    }

    static func from(index: Int) -> ProfileBackground {
        guard index >= 0 && index < allBackgrounds.count else {
            return allBackgrounds[0]
        }
        return allBackgrounds[index]
    }

    static func index(of background: ProfileBackground) -> Int {
        allBackgrounds.firstIndex(of: background) ?? 0
    }
}

// MARK: - Profile Avatars (Emoji-based with categories)
struct ProfileAvatar: Equatable {
    let emoji: String
    let name: String
    let category: AvatarCategory

    enum AvatarCategory: String, CaseIterable {
        case animals = "Animals"
        case fantasy = "Fantasy"
        case nature = "Nature"
        case food = "Yummy"
        case space = "Space"
    }

    // All avatars organized by category
    static let allAvatars: [ProfileAvatar] = [
        // Animals
        ProfileAvatar(emoji: "🐰", name: "Bunny", category: .animals),
        ProfileAvatar(emoji: "🐻", name: "Bear", category: .animals),
        ProfileAvatar(emoji: "🐱", name: "Cat", category: .animals),
        ProfileAvatar(emoji: "🐶", name: "Dog", category: .animals),
        ProfileAvatar(emoji: "🦊", name: "Fox", category: .animals),
        ProfileAvatar(emoji: "🐼", name: "Panda", category: .animals),
        ProfileAvatar(emoji: "🐨", name: "Koala", category: .animals),
        ProfileAvatar(emoji: "🦁", name: "Lion", category: .animals),
        ProfileAvatar(emoji: "🐸", name: "Frog", category: .animals),
        ProfileAvatar(emoji: "🐙", name: "Octopus", category: .animals),
        ProfileAvatar(emoji: "🦋", name: "Butterfly", category: .animals),
        ProfileAvatar(emoji: "🐢", name: "Turtle", category: .animals),

        // Fantasy
        ProfileAvatar(emoji: "🦄", name: "Unicorn", category: .fantasy),
        ProfileAvatar(emoji: "🐉", name: "Dragon", category: .fantasy),
        ProfileAvatar(emoji: "🧚", name: "Fairy", category: .fantasy),
        ProfileAvatar(emoji: "🧜‍♀️", name: "Mermaid", category: .fantasy),
        ProfileAvatar(emoji: "🧙", name: "Wizard", category: .fantasy),
        ProfileAvatar(emoji: "👸", name: "Princess", category: .fantasy),
        ProfileAvatar(emoji: "🤴", name: "Prince", category: .fantasy),
        ProfileAvatar(emoji: "🦸", name: "Superhero", category: .fantasy),
        ProfileAvatar(emoji: "🤖", name: "Robot", category: .fantasy),
        ProfileAvatar(emoji: "👽", name: "Alien", category: .fantasy),

        // Nature
        ProfileAvatar(emoji: "🌸", name: "Blossom", category: .nature),
        ProfileAvatar(emoji: "🌻", name: "Sunflower", category: .nature),
        ProfileAvatar(emoji: "🌈", name: "Rainbow", category: .nature),
        ProfileAvatar(emoji: "⭐", name: "Star", category: .nature),
        ProfileAvatar(emoji: "🌙", name: "Moon", category: .nature),
        ProfileAvatar(emoji: "☀️", name: "Sun", category: .nature),
        ProfileAvatar(emoji: "🍀", name: "Clover", category: .nature),
        ProfileAvatar(emoji: "🌺", name: "Hibiscus", category: .nature),

        // Food
        ProfileAvatar(emoji: "🍓", name: "Strawberry", category: .food),
        ProfileAvatar(emoji: "🍕", name: "Pizza", category: .food),
        ProfileAvatar(emoji: "🧁", name: "Cupcake", category: .food),
        ProfileAvatar(emoji: "🍩", name: "Donut", category: .food),
        ProfileAvatar(emoji: "🍦", name: "Ice Cream", category: .food),
        ProfileAvatar(emoji: "🍪", name: "Cookie", category: .food),
        ProfileAvatar(emoji: "🍉", name: "Watermelon", category: .food),
        ProfileAvatar(emoji: "🥑", name: "Avocado", category: .food),

        // Space
        ProfileAvatar(emoji: "🚀", name: "Rocket", category: .space),
        ProfileAvatar(emoji: "🛸", name: "UFO", category: .space),
        ProfileAvatar(emoji: "🌍", name: "Earth", category: .space),
        ProfileAvatar(emoji: "🪐", name: "Saturn", category: .space),
        ProfileAvatar(emoji: "👨‍🚀", name: "Astronaut", category: .space),
        ProfileAvatar(emoji: "🌟", name: "Glowing Star", category: .space),
    ]

    static func avatars(for category: AvatarCategory) -> [ProfileAvatar] {
        allAvatars.filter { $0.category == category }
    }

    static func from(index: Int) -> ProfileAvatar {
        guard index >= 0 && index < allAvatars.count else {
            return allAvatars[0]
        }
        return allAvatars[index]
    }

    static func index(of avatar: ProfileAvatar) -> Int {
        allAvatars.firstIndex(of: avatar) ?? 0
    }
}
