//
//  MascotPersonality.swift
//  Sproutling
//
//  Dynamic mascot personality system with contextual reactions
//

import Foundation

// MARK: - Mascot Reaction Context

/// Context for generating mascot reactions
struct MascotContext {
    let correctStreak: Int          // Current streak of correct answers
    let incorrectStreak: Int        // Current streak of incorrect answers
    let activitiesCompletedToday: Int
    let totalSeeds: Int
    let streakDays: Int
    let isFirstActivityOfSession: Bool
    let isReturningUser: Bool       // Has played before
    let timeOfDay: TimeOfDay
    let subject: Subject?
    let activityType: ActivityType?

    enum TimeOfDay {
        case morning    // 5am - 12pm
        case afternoon  // 12pm - 5pm
        case evening    // 5pm - 9pm
        case night      // 9pm - 5am

        static var current: TimeOfDay {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 5..<12: return .morning
            case 12..<17: return .afternoon
            case 17..<21: return .evening
            default: return .night
            }
        }
    }
}

// MARK: - Mascot Reaction

/// A mascot reaction with emotion, message, and optional special animation
struct MascotReaction {
    let emotion: MascotEmotion
    let message: String
    let isSpecial: Bool  // Triggers extra celebration animation

    init(_ emotion: MascotEmotion, _ message: String, special: Bool = false) {
        self.emotion = emotion
        self.message = message
        self.isSpecial = special
    }
}

// MARK: - Mascot Personality Service

class MascotPersonality {
    static let shared = MascotPersonality()

    private init() {}

    // MARK: - Greeting Messages

    /// Generate a greeting for the home screen
    func homeGreeting(context: MascotContext) -> MascotReaction {
        // Special greetings for milestones
        if context.totalSeeds == 0 && !context.isReturningUser {
            return MascotReaction(.excited, "Hi there! I'm Sproutling! Let's learn together!", special: true)
        }

        if context.streakDays >= 7 {
            return MascotReaction(.excited, "Wow! \(context.streakDays) days in a row! You're amazing!", special: true)
        }

        if context.streakDays == 3 {
            return MascotReaction(.proud, "3 days of learning! You're on fire!", special: true)
        }

        // Time-of-day greetings
        let greetings: [MascotReaction]
        switch context.timeOfDay {
        case .morning:
            greetings = [
                MascotReaction(.happy, "Good morning! Ready to grow your brain?"),
                MascotReaction(.excited, "Rise and shine! What should we learn?"),
                MascotReaction(.happy, "A new day to learn new things!"),
            ]
        case .afternoon:
            greetings = [
                MascotReaction(.happy, "Good afternoon! Let's learn something fun!"),
                MascotReaction(.thinking, "Hmm, what shall we explore today?"),
                MascotReaction(.happy, "Afternoon learning is the best!"),
            ]
        case .evening:
            greetings = [
                MascotReaction(.happy, "Evening learning time! What sounds fun?"),
                MascotReaction(.thinking, "Let's squeeze in some learning before bed!"),
                MascotReaction(.happy, "What shall we learn tonight?"),
            ]
        case .night:
            greetings = [
                MascotReaction(.happy, "A little late-night learning? I like it!"),
                MascotReaction(.thinking, "Can't sleep? Let's learn something!"),
            ]
        }

        return greetings.randomElement()!
    }

    // MARK: - Correct Answer Reactions

    /// Generate a reaction for a correct answer
    func correctAnswer(context: MascotContext) -> MascotReaction {
        // Streak celebrations
        switch context.correctStreak {
        case 3:
            return streakReactions3.randomElement()!
        case 5:
            return streakReactions5.randomElement()!
        case 10:
            return MascotReaction(.excited, "TEN in a row! You're unstoppable!", special: true)
        default:
            break
        }

        // Subject-specific praise
        if let subject = context.subject {
            switch subject {
            case .math:
                return mathCorrectReactions.randomElement()!
            case .reading:
                return readingCorrectReactions.randomElement()!
            }
        }

        // Generic praise
        return genericCorrectReactions.randomElement()!
    }

    // MARK: - Incorrect Answer Reactions

    /// Generate an encouraging reaction for an incorrect answer
    func incorrectAnswer(context: MascotContext) -> MascotReaction {
        // After multiple incorrect, be extra encouraging
        if context.incorrectStreak >= 3 {
            return MascotReaction(.encouraging, "You're doing great! Learning takes practice!")
        }

        if context.incorrectStreak == 2 {
            return MascotReaction(.encouraging, "Almost there! Take your time.")
        }

        // First incorrect - gentle encouragement
        return firstIncorrectReactions.randomElement()!
    }

    // MARK: - Lesson Complete Reactions

    /// Generate a reaction for completing a lesson
    func lessonComplete(stars: Int, context: MascotContext) -> MascotReaction {
        switch stars {
        case 3:
            return perfectLessonReactions.randomElement()!
        case 2:
            return goodLessonReactions.randomElement()!
        default:
            return completedLessonReactions.randomElement()!
        }
    }

    // MARK: - Milestone Reactions

    /// Check for and return any milestone reactions
    func checkMilestone(context: MascotContext) -> MascotReaction? {
        switch context.totalSeeds {
        case 10:
            return MascotReaction(.excited, "10 seeds! Your garden is starting to grow!", special: true)
        case 25:
            return MascotReaction(.proud, "25 seeds! Look at you bloom!", special: true)
        case 50:
            return MascotReaction(.excited, "50 seeds! You're a super learner!", special: true)
        case 100:
            return MascotReaction(.excited, "100 SEEDS! You're absolutely amazing!", special: true)
        default:
            return nil
        }
    }

    // MARK: - Activity Introduction Reactions

    /// Generate an introduction for starting an activity
    func activityIntro(activityType: ActivityType) -> MascotReaction {
        switch activityType {
        case .numberWithObjects:
            return MascotReaction(.thinking, "Let's count these together!")
        case .numberMatching:
            return MascotReaction(.happy, "Which number matches?")
        case .countingTouch:
            return MascotReaction(.excited, "Tap to count with me!")
        case .subitizing:
            return MascotReaction(.thinking, "Look fast! How many do you see?")
        case .comparison:
            return MascotReaction(.curious, "Which group has more?")
        case .letterCard:
            return MascotReaction(.happy, "Let's learn a new letter!")
        case .letterMatching:
            return MascotReaction(.thinking, "What letter does it start with?")
        case .phonicsBlending:
            return MascotReaction(.excited, "Sound it out with me!")
        case .vocabularyCard:
            return MascotReaction(.happy, "What's this? Let's find out!")
        }
    }

    // MARK: - Reaction Collections

    private let streakReactions3: [MascotReaction] = [
        MascotReaction(.excited, "3 in a row! You're on a roll!", special: true),
        MascotReaction(.proud, "Hat trick! Three correct!", special: true),
        MascotReaction(.excited, "Wow! That's three in a row!", special: true),
    ]

    private let streakReactions5: [MascotReaction] = [
        MascotReaction(.excited, "FIVE in a row! Amazing!", special: true),
        MascotReaction(.proud, "High five for five!", special: true),
        MascotReaction(.excited, "You're a learning machine!", special: true),
    ]

    private let mathCorrectReactions: [MascotReaction] = [
        MascotReaction(.excited, "You're a number ninja!"),
        MascotReaction(.proud, "That's right! Great counting!"),
        MascotReaction(.happy, "You figured it out!"),
        MascotReaction(.excited, "Math superstar!"),
        MascotReaction(.proud, "Your brain is growing!"),
    ]

    private let readingCorrectReactions: [MascotReaction] = [
        MascotReaction(.excited, "You're a reading rockstar!"),
        MascotReaction(.proud, "That's the one! Great job!"),
        MascotReaction(.happy, "You know your letters!"),
        MascotReaction(.excited, "Word wizard!"),
        MascotReaction(.proud, "Fantastic reading!"),
    ]

    private let genericCorrectReactions: [MascotReaction] = [
        MascotReaction(.excited, "Yes! You got it!"),
        MascotReaction(.proud, "That's right!"),
        MascotReaction(.happy, "Excellent!"),
        MascotReaction(.excited, "Amazing!"),
        MascotReaction(.proud, "You're so smart!"),
        MascotReaction(.happy, "Wonderful!"),
        MascotReaction(.excited, "Perfect!"),
    ]

    private let firstIncorrectReactions: [MascotReaction] = [
        MascotReaction(.encouraging, "Good try! Let's try again!"),
        MascotReaction(.thinking, "Hmm, not quite. Try again!"),
        MascotReaction(.encouraging, "Almost! Give it another go!"),
        MascotReaction(.happy, "Oops! That's okay, try again!"),
        MascotReaction(.encouraging, "So close! You can do it!"),
    ]

    private let perfectLessonReactions: [MascotReaction] = [
        MascotReaction(.excited, "THREE seeds! Perfect lesson!", special: true),
        MascotReaction(.proud, "You nailed it! All three seeds!", special: true),
        MascotReaction(.excited, "Incredible! A perfect score!", special: true),
    ]

    private let goodLessonReactions: [MascotReaction] = [
        MascotReaction(.proud, "Two seeds! Great job!"),
        MascotReaction(.happy, "You worked hard! Nice work!"),
        MascotReaction(.proud, "Awesome learning today!"),
    ]

    private let completedLessonReactions: [MascotReaction] = [
        MascotReaction(.encouraging, "You finished! Practice makes perfect!"),
        MascotReaction(.happy, "You kept trying! That's what matters!"),
        MascotReaction(.encouraging, "Great effort! Keep growing!"),
    ]
}

// MARK: - Extended Mascot Emotions

extension MascotEmotion {
    /// Additional emotions for richer personality
    static let curious: MascotEmotion = .thinking  // Alias for now
    static let cheering: MascotEmotion = .excited  // Alias for now
}
