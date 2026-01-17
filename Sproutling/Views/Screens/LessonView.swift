//
//  LessonView.swift
//  Sproutling
//
//  Main lesson flow that coordinates activities
//

import SwiftUI

struct LessonView: View {
    let subject: Subject
    let level: Int

    @EnvironmentObject var appState: AppState
    @StateObject private var lessonState = LessonState()

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: subject.lightGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar with progress
                navBar

                // Progress bar
                ProgressBar(
                    current: lessonState.currentIndex + 1,
                    total: lessonState.cards.count,
                    color: subject == .math ? .purple : .pink
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // Card count
                Text("\(lessonState.currentIndex + 1) of \(lessonState.cards.count)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)

                // Current activity
                currentActivity
                    .id(lessonState.currentIndex) // Force refresh on index change
            }

            // Confetti overlay
            if lessonState.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            lessonState.setupLesson(for: subject, level: level)
        }
    }

    // MARK: - Navigation Bar
    private var navBar: some View {
        SproutlingNavBar(
            title: subject == .math ? "Counting Fun!" : "Letter Time!",
            onBack: {
                appState.navigateTo(.subjectSelection(subject))
            },
            rightContent: AnyView(
                StarReward(count: lessonState.starsEarned, animated: lessonState.showConfetti, size: 24)
            )
        )
    }

    // MARK: - Current Activity
    @ViewBuilder
    private var currentActivity: some View {
        if lessonState.currentIndex < lessonState.cards.count {
            let card = lessonState.cards[lessonState.currentIndex]

            switch card.type {
            // Math activities
            case .numberWithObjects:
                NumberWithObjectsActivity(
                    number: card.number ?? 1,
                    objectName: card.objects ?? "stars",
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .numberMatching:
                NumberMatchingActivity(
                    targetNumber: card.number ?? 1,
                    options: card.numberOptions ?? [1, 2, 3],
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .countingTouch:
                CountingTouchActivity(
                    targetNumber: card.number ?? 5,
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            // Reading activities
            case .letterCard:
                LetterCardActivity(
                    letter: card.letter ?? "A",
                    word: card.word ?? "Apple",
                    emoji: card.emoji ?? "🍎",
                    sound: card.sound ?? "ah",
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .letterMatching:
                LetterMatchingActivity(
                    targetLetter: card.letter ?? "A",
                    options: card.letterOptions ?? ["A", "B", "C"],
                    word: card.word ?? "Apple",
                    emoji: card.emoji ?? "🍎",
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .phonicsBlending:
                PhonicsBlendingActivity(
                    letters: card.letters ?? ["C", "A", "T"],
                    word: card.word ?? "CAT",
                    emoji: card.emoji ?? "🐱",
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )
            }
        }
    }
}

// MARK: - Lesson State
class LessonState: ObservableObject {
    @Published var cards: [ActivityCard] = []
    @Published var currentIndex = 0
    @Published var starsEarned = 0
    @Published var correctAnswers = 0
    @Published var showConfetti = false

    func setupLesson(for subject: Subject, level: Int) {
        switch subject {
        case .math:
            cards = createMathCards(level: level)
        case .reading:
            cards = createReadingCards(level: level)
        }
    }

    func markCorrect() {
        correctAnswers += 1

        // Award stars based on progress
        let progress = Double(correctAnswers) / Double(cards.count)
        let newStars = min(3, Int(progress * 3) + 1)

        if newStars > starsEarned {
            starsEarned = newStars
            triggerConfetti()
        }
    }

    func nextCard(appState: AppState, subject: Subject, level: Int) {
        if currentIndex < cards.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            // Lesson complete
            appState.completeLesson(subject: subject, level: level, stars: starsEarned)
        }
    }

    private func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showConfetti = false
        }
    }

    // MARK: - Card Creation
    private func createMathCards(level: Int) -> [ActivityCard] {
        let objects = ["apples", "stars", "butterflies", "flowers", "hearts", "fish", "birds", "cookies"]

        switch level {
        case 1:
            // Level 1: Numbers 1-3
            return [
                ActivityCard(type: .numberWithObjects, number: 1, objects: objects[0]),
                ActivityCard(type: .numberWithObjects, number: 2, objects: objects[1]),
                ActivityCard(type: .numberMatching, number: 2, numberOptions: [1, 2, 3]),
                ActivityCard(type: .numberWithObjects, number: 3, objects: objects[2]),
                ActivityCard(type: .countingTouch, number: 3),
                ActivityCard(type: .numberMatching, number: 3, numberOptions: [1, 3, 5])
            ]
        case 2:
            // Level 2: Numbers 4-6
            return [
                ActivityCard(type: .numberWithObjects, number: 4, objects: objects[3]),
                ActivityCard(type: .numberWithObjects, number: 5, objects: objects[4]),
                ActivityCard(type: .numberMatching, number: 4, numberOptions: [2, 4, 6]),
                ActivityCard(type: .numberWithObjects, number: 6, objects: objects[5]),
                ActivityCard(type: .countingTouch, number: 5),
                ActivityCard(type: .numberMatching, number: 6, numberOptions: [4, 6, 8])
            ]
        case 3:
            // Level 3: Numbers 7-10
            return [
                ActivityCard(type: .numberWithObjects, number: 7, objects: objects[6]),
                ActivityCard(type: .numberWithObjects, number: 8, objects: objects[7]),
                ActivityCard(type: .numberMatching, number: 8, numberOptions: [6, 8, 10]),
                ActivityCard(type: .numberWithObjects, number: 9, objects: objects[0]),
                ActivityCard(type: .countingTouch, number: 10),
                ActivityCard(type: .numberMatching, number: 10, numberOptions: [7, 9, 10])
            ]
        default:
            return createMathCards(level: 1)
        }
    }

    private func createReadingCards(level: Int) -> [ActivityCard] {
        switch level {
        case 1:
            // Level 1: Letters A-C
            return [
                ActivityCard(type: .letterCard, letter: "A", word: "Apple", emoji: "🍎", sound: "ah"),
                ActivityCard(type: .letterCard, letter: "B", word: "Ball", emoji: "⚽", sound: "buh"),
                ActivityCard(type: .letterMatching, letter: "A", word: "Ant", emoji: "🐜", letterOptions: ["A", "B", "C"]),
                ActivityCard(type: .letterCard, letter: "C", word: "Cat", emoji: "🐱", sound: "kuh"),
                ActivityCard(type: .phonicsBlending, word: "CAB", emoji: "🚕", letters: ["C", "A", "B"]),
                ActivityCard(type: .letterMatching, letter: "B", word: "Bird", emoji: "🐦", letterOptions: ["A", "B", "D"])
            ]
        case 2:
            // Level 2: Letters D-F
            return [
                ActivityCard(type: .letterCard, letter: "D", word: "Dog", emoji: "🐕", sound: "duh"),
                ActivityCard(type: .letterCard, letter: "E", word: "Egg", emoji: "🥚", sound: "eh"),
                ActivityCard(type: .letterMatching, letter: "D", word: "Duck", emoji: "🦆", letterOptions: ["B", "D", "F"]),
                ActivityCard(type: .letterCard, letter: "F", word: "Fish", emoji: "🐟", sound: "fuh"),
                ActivityCard(type: .phonicsBlending, word: "FED", emoji: "🍽️", letters: ["F", "E", "D"]),
                ActivityCard(type: .letterMatching, letter: "E", word: "Elephant", emoji: "🐘", letterOptions: ["E", "F", "G"])
            ]
        case 3:
            // Level 3: Letters G-J
            return [
                ActivityCard(type: .letterCard, letter: "G", word: "Goat", emoji: "🐐", sound: "guh"),
                ActivityCard(type: .letterCard, letter: "H", word: "Hat", emoji: "🎩", sound: "huh"),
                ActivityCard(type: .letterMatching, letter: "G", word: "Grape", emoji: "🍇", letterOptions: ["F", "G", "H"]),
                ActivityCard(type: .letterCard, letter: "I", word: "Ice", emoji: "🧊", sound: "ih"),
                ActivityCard(type: .letterCard, letter: "J", word: "Jam", emoji: "🍯", sound: "juh"),
                ActivityCard(type: .phonicsBlending, word: "JIG", emoji: "💃", letters: ["J", "I", "G"])
            ]
        default:
            return createReadingCards(level: 1)
        }
    }
}

#Preview {
    LessonView(subject: .math, level: 1)
        .environmentObject(AppState())
}
