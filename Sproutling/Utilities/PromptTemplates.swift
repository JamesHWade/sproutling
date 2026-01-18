//
//  PromptTemplates.swift
//  Sproutling
//
//  Personalized prompt templates for TTS with child name support
//

import Foundation

/// Manages personalized prompt templates for TTS
/// Use {name} as placeholder for child's name
struct PromptTemplates {

    // MARK: - Activity Instructions

    /// Instructions for math counting activities
    static let mathCountingInstructions = [
        "Let's count together, {name}!",
        "How many do you see, {name}?",
        "Can you count these, {name}?",
        "Count with me, {name}!",
        "Let's see how many there are, {name}!"
    ]

    /// Instructions for number matching activities
    static let mathMatchingInstructions = [
        "Which number shows this many, {name}?",
        "Find the right number, {name}!",
        "Tap the matching number, {name}!",
        "What number is this, {name}?",
        "Can you match the number, {name}?"
    ]

    /// Instructions for comparison activities
    static let mathComparisonInstructions = [
        "Which group has more, {name}?",
        "Which side has fewer, {name}?",
        "Are they the same, {name}?",
        "Compare these groups, {name}!",
        "Which has more objects, {name}?"
    ]

    /// Instructions for letter card activities
    static let readingLetterInstructions = [
        "This is the letter...",
        "Let's learn this letter, {name}!",
        "Look at this letter, {name}!",
        "Here's a new letter for you, {name}!",
        "Time for a letter, {name}!"
    ]

    /// Instructions for letter matching activities
    static let readingMatchingInstructions = [
        "Can you find the right letter, {name}?",
        "Which letter starts this word, {name}?",
        "Tap the matching letter, {name}!",
        "Find the letter that makes this sound, {name}!",
        "What letter starts this word, {name}?"
    ]

    /// Instructions for phonics activities
    static let readingPhonicsInstructions = [
        "Tap each letter to hear its sound, {name}!",
        "Let's blend the sounds, {name}!",
        "Listen to each sound, {name}!",
        "Sound it out, {name}!",
        "Blend these sounds together, {name}!"
    ]

    // MARK: - Encouragement (Correct)

    /// Short celebration for correct answers
    static let correctShort = [
        "Yes!",
        "Right!",
        "Correct!",
        "Perfect!",
        "Exactly!"
    ]

    /// Personalized celebration for correct answers
    static let correctPersonalized = [
        "Great job, {name}!",
        "You're amazing, {name}!",
        "Wonderful, {name}!",
        "That's right, {name}!",
        "Excellent, {name}!",
        "Way to go, {name}!",
        "Super work, {name}!",
        "You got it, {name}!",
        "Fantastic, {name}!",
        "Brilliant, {name}!"
    ]

    /// Extra enthusiastic celebrations (for streaks or milestones)
    static let correctEnthusiastic = [
        "Wow, {name}! You're on fire!",
        "Amazing, {name}! Keep it up!",
        "You're a superstar, {name}!",
        "Incredible, {name}!",
        "You're doing so well, {name}!"
    ]

    // MARK: - Gentle Correction

    /// Short encouragement to try again
    static let tryAgainShort = [
        "Try again!",
        "Almost!",
        "Not quite!",
        "Let's try again!",
        "One more try!"
    ]

    /// Personalized gentle correction
    static let tryAgainPersonalized = [
        "Let's try again, {name}!",
        "Almost, {name}! Try once more!",
        "Good try, {name}! Let's try again!",
        "Not quite, {name}. You can do it!",
        "Close, {name}! Try again!"
    ]

    /// Hints and help prompts
    static let hintPrompts = [
        "Listen carefully, {name}!",
        "Look closely, {name}!",
        "Take your time, {name}!",
        "Think about it, {name}!",
        "Let me help you, {name}!"
    ]

    // MARK: - Progress Updates

    /// Mid-lesson encouragement
    static let progressMidLesson = [
        "You're doing great, {name}!",
        "Keep going, {name}!",
        "Halfway there, {name}!",
        "Great progress, {name}!",
        "You're learning so much, {name}!"
    ]

    /// Almost done prompts
    static let progressAlmostDone = [
        "One more to go, {name}!",
        "Almost done, {name}!",
        "Just one more, {name}!",
        "Last one, {name}!",
        "You're almost finished, {name}!"
    ]

    /// Lesson complete celebrations
    static let lessonComplete = [
        "Lesson complete! Amazing work, {name}!",
        "You did it, {name}! Great job!",
        "Wonderful, {name}! You finished the lesson!",
        "Congratulations, {name}! You're a star!",
        "All done, {name}! You learned so much!"
    ]

    // MARK: - Content-Specific

    /// Letter sound with word example
    static func letterSoundWithWord(_ letter: String, word: String, emoji: String) -> String {
        return "\(letter.uppercased()) is for \(word)"
    }

    // MARK: - Helper Functions

    /// Get a random prompt from a category
    static func random(from prompts: [String]) -> String {
        prompts.randomElement() ?? prompts[0]
    }

    /// Get a personalized prompt with the child's name
    static func personalized(_ template: String, name: String) -> String {
        template.replacingOccurrences(of: "{name}", with: name)
    }

    /// Get a random personalized prompt from a category
    static func randomPersonalized(from prompts: [String], name: String) -> String {
        personalized(random(from: prompts), name: name)
    }
}

// MARK: - Convenience Extensions

extension PromptTemplates {

    /// Get appropriate instruction for activity type
    static func instruction(for activityType: ActivityType, name: String) -> String {
        let templates: [String]
        switch activityType {
        case .numberWithObjects, .countingTouch, .subitizing:
            templates = mathCountingInstructions
        case .numberMatching:
            templates = mathMatchingInstructions
        case .comparison:
            templates = mathComparisonInstructions
        case .letterCard, .vocabularyCard:
            templates = readingLetterInstructions
        case .letterMatching:
            templates = readingMatchingInstructions
        case .phonicsBlending:
            templates = readingPhonicsInstructions
        }
        return randomPersonalized(from: templates, name: name)
    }

    /// Get correct answer celebration
    static func celebration(streak: Int = 0, name: String) -> String {
        if streak >= 3 {
            return randomPersonalized(from: correctEnthusiastic, name: name)
        } else if Bool.random() {
            return random(from: correctShort)
        } else {
            return randomPersonalized(from: correctPersonalized, name: name)
        }
    }

    /// Get try again prompt
    static func tryAgain(attempts: Int = 0, name: String) -> String {
        if attempts >= 2 {
            return randomPersonalized(from: hintPrompts, name: name)
        } else if Bool.random() {
            return random(from: tryAgainShort)
        } else {
            return randomPersonalized(from: tryAgainPersonalized, name: name)
        }
    }

    /// Get progress update based on position in lesson
    static func progressUpdate(current: Int, total: Int, name: String) -> String? {
        let remaining = total - current

        if remaining == 1 {
            return randomPersonalized(from: progressAlmostDone, name: name)
        } else if current == total / 2 {
            return randomPersonalized(from: progressMidLesson, name: name)
        } else if remaining == 0 {
            return randomPersonalized(from: lessonComplete, name: name)
        }

        return nil
    }
}
