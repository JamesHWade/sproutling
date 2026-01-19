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

            // Only show content once cards are loaded to prevent flash
            if lessonState.isReady {
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
            }

            // Confetti overlay
            if lessonState.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            lessonState.setupLesson(for: subject, level: level, childName: appState.currentProfile?.name)
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
                    lessonState: lessonState,
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .numberMatching:
                NumberMatchingActivity(
                    targetNumber: card.number ?? 1,
                    options: card.numberOptions ?? [1, 2, 3],
                    lessonState: lessonState,
                    onCorrect: { lessonState.markCorrect() },
                    onIncorrect: { lessonState.markIncorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .countingTouch:
                CountingTouchActivity(
                    targetNumber: card.number ?? 5,
                    lessonState: lessonState,
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
                    lessonState: lessonState,
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .letterMatching:
                LetterMatchingActivity(
                    targetLetter: card.letter ?? "A",
                    options: card.letterOptions ?? ["A", "B", "C"],
                    word: card.word ?? "Apple",
                    emoji: card.emoji ?? "🍎",
                    lessonState: lessonState,
                    onCorrect: { lessonState.markCorrect() },
                    onIncorrect: { lessonState.markIncorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .phonicsBlending:
                PhonicsBlendingActivity(
                    letters: card.letters ?? ["C", "A", "T"],
                    word: card.word ?? "CAT",
                    emoji: card.emoji ?? "🐱",
                    lessonState: lessonState,
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .subitizing:
                SubitizingActivity(
                    number: card.number ?? 3,
                    objectName: card.objects ?? "stars",
                    lessonState: lessonState,
                    onCorrect: { lessonState.markCorrect() },
                    onIncorrect: { lessonState.markIncorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .comparison:
                ComparisonActivity(
                    leftCount: card.leftCount ?? 3,
                    rightCount: card.rightCount ?? 5,
                    leftObjects: card.leftObjects ?? "stars",
                    rightObjects: card.rightObjects ?? "hearts",
                    lessonState: lessonState,
                    onCorrect: { lessonState.markCorrect() },
                    onIncorrect: { lessonState.markIncorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )

            case .vocabularyCard:
                VocabularyCardActivity(
                    word: card.word ?? "Apple",
                    emoji: card.emoji ?? "🍎",
                    category: card.category,
                    lessonState: lessonState,
                    onCorrect: { lessonState.markCorrect() },
                    onNext: { lessonState.nextCard(appState: appState, subject: subject, level: level) }
                )
            }
        }
    }
}

// MARK: - Lesson State
@MainActor
class LessonState: ObservableObject {
    @Published var cards: [ActivityCard] = []
    @Published var currentIndex = 0
    @Published var starsEarned = 0
    @Published var correctAnswers = 0
    @Published var showConfetti = false
    @Published var isReady = false

    // Streak tracking for mascot personality
    @Published var correctStreak = 0
    @Published var incorrectStreak = 0
    @Published var lastReaction: MascotReaction?

    // Child's name for personalized TTS
    var childName: String = "Friend"

    private var currentSubject: Subject?
    private var hasSetup = false

    func setupLesson(for subject: Subject, level: Int, childName: String? = nil) {
        // Only setup once to prevent re-shuffling options
        guard !hasSetup else { return }
        hasSetup = true

        cards = CurriculumLoader.shared.getCards(for: subject, level: level)
        currentSubject = subject
        correctStreak = 0
        incorrectStreak = 0
        self.childName = childName ?? "Friend"
        isReady = true
    }

    func markCorrect() {
        correctAnswers += 1
        correctStreak += 1
        incorrectStreak = 0

        // Get mascot reaction for correct answer
        let context = buildContext()
        lastReaction = MascotPersonality.shared.correctAnswer(context: context)

        // Award stars based on progress
        let progress = Double(correctAnswers) / Double(cards.count)
        let newStars = min(3, Int(progress * 3) + 1)

        if newStars > starsEarned {
            starsEarned = newStars
            triggerConfetti()
        }
    }

    func markIncorrect() {
        incorrectStreak += 1
        correctStreak = 0

        // Get mascot reaction for incorrect answer
        let context = buildContext()
        lastReaction = MascotPersonality.shared.incorrectAnswer(context: context)
    }

    func nextCard(appState: AppState, subject: Subject, level: Int) {
        if currentIndex < cards.count - 1 {
            withAnimation {
                currentIndex += 1
            }
            // Reset reaction for next card
            lastReaction = nil
        } else {
            // Lesson complete
            appState.completeLesson(subject: subject, level: level, stars: starsEarned)
        }
    }

    /// Build mascot context from current lesson state
    func buildContext(activityType: ActivityType? = nil) -> MascotContext {
        MascotContext(
            correctStreak: correctStreak,
            incorrectStreak: incorrectStreak,
            activitiesCompletedToday: correctAnswers,
            totalSeeds: 0, // Will be filled by view if needed
            streakDays: 0, // Will be filled by view if needed
            isFirstActivityOfSession: currentIndex == 0,
            isReturningUser: true,
            timeOfDay: .current,
            subject: currentSubject,
            activityType: activityType ?? cards[safe: currentIndex]?.type
        )
    }

    /// Get the current mascot reaction (for display in activities)
    func getReaction() -> MascotReaction? {
        return lastReaction
    }

    // MARK: - TTS Response Helpers

    /// Handle a correct answer with sound, haptics, and TTS celebration
    func handleCorrectWithTTS() {
        SoundManager.shared.playSound(.correct)
        HapticFeedback.success()
        let celebration = PromptTemplates.celebration(streak: correctStreak, name: childName)
        SoundManager.shared.speakWithElevenLabs(celebration, settings: .encouraging)
    }

    /// Handle an incorrect answer with sound, haptics, and TTS encouragement
    func handleIncorrectWithTTS() {
        SoundManager.shared.playSound(.incorrect)
        HapticFeedback.error()
        let tryAgain = PromptTemplates.tryAgain(attempts: incorrectStreak, name: childName)
        SoundManager.shared.speakWithElevenLabs(tryAgain, settings: .childFriendly)
    }

    private func triggerConfetti() {
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showConfetti = false
        }
    }
}

// Safe array access extension
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    LessonView(subject: .math, level: 1)
        .environmentObject(AppState())
}
