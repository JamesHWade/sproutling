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

            case .subitizing:
                SubitizingActivity(
                    number: card.number ?? 3,
                    objectName: card.objects ?? "stars",
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .comparison:
                ComparisonActivity(
                    leftCount: card.leftCount ?? 3,
                    rightCount: card.rightCount ?? 5,
                    leftObjects: card.leftObjects ?? "stars",
                    rightObjects: card.rightObjects ?? "hearts",
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .vocabularyCard:
                VocabularyCardActivity(
                    word: card.word ?? "Apple",
                    emoji: card.emoji ?? "🍎",
                    category: card.category,
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
        cards = CurriculumLoader.shared.getCards(for: subject, level: level)
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
}

#Preview {
    LessonView(subject: .math, level: 1)
        .environmentObject(AppState())
}
