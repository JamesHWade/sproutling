//
//  CurriculumLoader.swift
//  Sproutling
//
//  Loads curriculum content from JSON data files
//

import Foundation

// MARK: - Curriculum Data Structures

/// Represents the full curriculum for a subject
struct CurriculumData: Codable {
    let subject: String
    let levels: [LevelData]
}

/// Represents a single level within a curriculum
struct LevelData: Codable {
    let id: Int
    let title: String
    let subtitle: String
    let cards: [CardData]
}

/// JSON-decodable representation of an activity card
struct CardData: Codable {
    let type: String

    // Math activity fields
    let number: Int?
    let objects: String?
    let numberOptions: [Int]?

    // Reading activity fields
    let letter: String?
    let word: String?
    let emoji: String?
    let sound: String?
    let letterOptions: [String]?
    let letters: [String]?

    // Vocabulary activity fields
    let category: String?

    // Comparison activity fields
    let leftCount: Int?
    let rightCount: Int?
    let leftObjects: String?
    let rightObjects: String?

    /// Converts the JSON card data to an ActivityCard model
    /// Options are shuffled to prevent predictable answer positions
    func toActivityCard() -> ActivityCard? {
        guard let activityType = ActivityType.from(string: type) else {
            return nil
        }

        // Shuffle options so correct answer isn't always in the same position
        let shuffledNumberOptions = numberOptions?.shuffled()
        let shuffledLetterOptions = letterOptions?.shuffled()

        return ActivityCard(
            type: activityType,
            number: number,
            objects: objects,
            numberOptions: shuffledNumberOptions,
            leftCount: leftCount,
            rightCount: rightCount,
            leftObjects: leftObjects,
            rightObjects: rightObjects,
            letter: letter,
            word: word,
            emoji: emoji,
            sound: sound,
            letterOptions: shuffledLetterOptions,
            letters: letters,
            category: category
        )
    }
}

// MARK: - ActivityType Extension for String Parsing

extension ActivityType {
    /// Creates an ActivityType from its string representation
    static func from(string: String) -> ActivityType? {
        switch string {
        case "numberWithObjects": return .numberWithObjects
        case "numberMatching": return .numberMatching
        case "countingTouch": return .countingTouch
        case "subitizing": return .subitizing
        case "comparison": return .comparison
        case "letterCard": return .letterCard
        case "letterMatching": return .letterMatching
        case "phonicsBlending": return .phonicsBlending
        case "vocabularyCard": return .vocabularyCard
        default: return nil
        }
    }

    /// String representation for JSON encoding
    var stringValue: String {
        switch self {
        case .numberWithObjects: return "numberWithObjects"
        case .numberMatching: return "numberMatching"
        case .countingTouch: return "countingTouch"
        case .subitizing: return "subitizing"
        case .comparison: return "comparison"
        case .letterCard: return "letterCard"
        case .letterMatching: return "letterMatching"
        case .phonicsBlending: return "phonicsBlending"
        case .vocabularyCard: return "vocabularyCard"
        }
    }
}

// MARK: - Curriculum Loader

/// Loads and caches curriculum data from JSON files
class CurriculumLoader {
    static let shared = CurriculumLoader()

    private var mathCurriculum: CurriculumData?
    private var readingCurriculum: CurriculumData?

    private init() {
        loadCurriculums()
    }

    /// Loads all curriculum JSON files
    private func loadCurriculums() {
        mathCurriculum = loadCurriculum(named: "MathCurriculum")
        readingCurriculum = loadCurriculum(named: "ReadingCurriculum")
    }

    /// Loads a single curriculum JSON file
    private func loadCurriculum(named name: String) -> CurriculumData? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            print("CurriculumLoader: Could not find \(name).json")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let curriculum = try JSONDecoder().decode(CurriculumData.self, from: data)
            return curriculum
        } catch {
            print("CurriculumLoader: Error loading \(name).json - \(error)")
            return nil
        }
    }

    /// Gets activity cards for a specific subject and level
    func getCards(for subject: Subject, level: Int) -> [ActivityCard] {
        let curriculum: CurriculumData?

        switch subject {
        case .math:
            curriculum = mathCurriculum
        case .reading:
            curriculum = readingCurriculum
        }

        guard let curriculum = curriculum,
              let levelData = curriculum.levels.first(where: { $0.id == level }) else {
            print("CurriculumLoader: No data found for \(subject.rawValue) level \(level)")
            return getFallbackCards(for: subject, level: level)
        }

        return levelData.cards.compactMap { $0.toActivityCard() }
    }

    /// Gets level metadata for a subject
    func getLevels(for subject: Subject) -> [LevelData] {
        switch subject {
        case .math:
            return mathCurriculum?.levels ?? []
        case .reading:
            return readingCurriculum?.levels ?? []
        }
    }

    /// Fallback cards if JSON loading fails (maintains backwards compatibility)
    private func getFallbackCards(for subject: Subject, level: Int) -> [ActivityCard] {
        switch subject {
        case .math:
            return [
                ActivityCard(type: .numberWithObjects, number: 1, objects: "apples"),
                ActivityCard(type: .numberWithObjects, number: 2, objects: "stars"),
                ActivityCard(type: .countingTouch, number: 3)
            ]
        case .reading:
            return [
                ActivityCard(type: .letterCard, letter: "A", word: "Apple", emoji: "🍎", sound: "ah"),
                ActivityCard(type: .letterCard, letter: "B", word: "Ball", emoji: "⚽", sound: "buh"),
                ActivityCard(type: .letterCard, letter: "C", word: "Cat", emoji: "🐱", sound: "kuh")
            ]
        }
    }

    /// Reloads curriculum data (useful for testing or hot-reloading)
    func reload() {
        loadCurriculums()
    }
}
