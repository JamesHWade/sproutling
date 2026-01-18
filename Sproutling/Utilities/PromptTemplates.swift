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
        "Let's count together!",
        "How many do you see?",
        "Can you count these?",
        "Count with me!",
        "Let's count, {name}!"  // Only one with name
    ]

    /// Instructions for number matching activities
    static let mathMatchingInstructions = [
        "Which number shows this many?",
        "Find the right number!",
        "Tap the matching number!",
        "What number is this?",
        "Which number, {name}?"  // Only one with name
    ]

    /// Instructions for comparison activities
    static let mathComparisonInstructions = [
        "Which group has more?",
        "Which side has fewer?",
        "Are they the same?",
        "Compare these groups!",
        "Which has more?"
    ]

    /// Instructions for letter card activities
    static let readingLetterInstructions = [
        "Here's a letter!",
        "Let's learn this letter!",
        "Look at this letter!",
        "Time for a letter!",
        "A new letter, {name}!"  // Only one with name
    ]

    /// Instructions for letter matching activities
    static let readingMatchingInstructions = [
        "Find the right letter!",
        "Which letter starts this word?",
        "Tap the matching letter!",
        "What letter starts this word?",
        "Can you find it, {name}?"  // Only one with name
    ]

    /// Instructions for phonics activities
    static let readingPhonicsInstructions = [
        "Tap each letter to hear its sound!",
        "Let's blend the sounds!",
        "Listen to each sound!",
        "Sound it out!",
        "Let's blend, {name}!"  // Only one with name
    ]

    /// Instructions for vocabulary card activities
    static let vocabularyInstructions = [
        "What's this?",
        "Can you say this word?",
        "Look at this picture!",
        "Let's learn a new word!",
        "What do you see, {name}?"  // Only one with name
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

    /// Celebration for correct answers (mostly without name)
    static let correctPersonalized = [
        "Great job!",
        "You're amazing!",
        "Wonderful!",
        "That's right!",
        "Excellent!",
        "Way to go!",
        "Super work!",
        "You got it!",
        "Great job, {name}!",  // Only 2 with name
        "Way to go, {name}!"
    ]

    /// Extra enthusiastic celebrations (for streaks or milestones)
    static let correctEnthusiastic = [
        "Wow! You're on fire!",
        "Amazing! Keep it up!",
        "You're a superstar!",
        "Incredible!",
        "You're doing so well, {name}!"  // Only one with name
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

    /// Gentle correction (mostly without name)
    static let tryAgainPersonalized = [
        "Let's try again!",
        "Almost! Try once more!",
        "Good try! Let's try again!",
        "Not quite. You can do it!",
        "Close, {name}! Try again!"  // Only one with name
    ]

    /// Hints and help prompts (mostly without name)
    static let hintPrompts = [
        "Listen carefully!",
        "Look closely!",
        "Take your time!",
        "Think about it!",
        "Let me help you, {name}!"  // Only one with name
    ]

    // MARK: - Progress Updates

    /// Mid-lesson encouragement (mostly without name)
    static let progressMidLesson = [
        "You're doing great!",
        "Keep going!",
        "Halfway there!",
        "Great progress!",
        "You're learning so much, {name}!"  // Only one with name
    ]

    /// Almost done prompts (mostly without name)
    static let progressAlmostDone = [
        "One more to go!",
        "Almost done!",
        "Just one more!",
        "Last one!",
        "You're almost finished, {name}!"  // Only one with name
    ]

    /// Lesson complete celebrations (name used sparingly)
    static let lessonComplete = [
        "Lesson complete! Amazing work!",
        "You did it! Great job!",
        "Wonderful! You finished the lesson!",
        "Congratulations! You're a star!",
        "All done, {name}! You learned so much!"  // Only one with name
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
        case .letterCard:
            templates = readingLetterInstructions
        case .vocabularyCard:
            templates = vocabularyInstructions
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
