//
//  ReadyCheckView.swift
//  Sproutling
//
//  Non-stressful mastery assessment disguised as helping the garden grow
//  Pass threshold: 5/6 correct (83%)
//

import SwiftUI
import SwiftData

struct ReadyCheckView: View {
    let subject: Subject
    let level: Int

    @EnvironmentObject var appState: AppState
    @StateObject private var checkState = ReadyCheckState()
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: subject.lightGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if checkState.isComplete {
                // Show results
                resultView
            } else if checkState.isReady {
                VStack(spacing: 0) {
                    // Header
                    header

                    // Progress bar
                    ProgressBar(
                        current: checkState.currentIndex + 1,
                        total: checkState.questions.count,
                        color: subject == .math ? .purple : .pink
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Question counter
                    Text("Question \(checkState.currentIndex + 1) of \(checkState.questions.count)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)

                    // Current question
                    if checkState.currentIndex < checkState.questions.count {
                        questionView(checkState.questions[checkState.currentIndex])
                            .id(checkState.currentIndex)
                    }

                    Spacer()
                }
            } else {
                // Loading
                ProgressView("Preparing your garden check...")
            }

            // Confetti for passing
            if checkState.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            checkState.setup(
                subject: subject,
                level: level,
                profileId: appState.currentProfile?.id,
                modelContext: appState.modelContext
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        SproutlingNavBar(
            title: "Garden Ready Check!",
            onBack: {
                appState.navigateTo(.subjectSelection(subject))
            },
            rightContent: AnyView(
                Text("\(checkState.correctAnswers)/\(checkState.questions.count)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            )
        )
    }

    // MARK: - Question View

    @ViewBuilder
    private func questionView(_ question: ReadyCheckQuestion) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Encouraging intro text
            Text("Let's see if your plants are ready to grow!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Question card
            VStack(spacing: 20) {
                // Visual prompt
                HStack(spacing: 8) {
                    ForEach(0..<question.visualCount, id: \.self) { _ in
                        Text(question.visualEmoji)
                            .font(.system(size: 44))
                    }
                }
                .padding()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(question.visualCount) \(question.visualDescription)")

                // Question text
                Text(question.questionText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .adaptiveShadow()
            .padding(.horizontal)

            // Answer options
            HStack(spacing: 16) {
                ForEach(question.options, id: \.self) { option in
                    answerButton(option, isCorrect: option == question.correctAnswer)
                }
            }
            .padding(.horizontal)

            Spacer()
            Spacer()
        }
    }

    private func answerButton(_ option: String, isCorrect: Bool) -> some View {
        Button {
            checkState.submitAnswer(option, isCorrect: isCorrect)
        } label: {
            Text(option)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 80, height: 80)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: subject.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .adaptiveShadow()
        }
        .buttonStyle(.plain)
        .disabled(checkState.isShowingFeedback)
        .accessibilityLabel("Answer: \(option)")
    }

    // MARK: - Result View

    private var resultView: some View {
        VStack(spacing: 24) {
            Spacer()

            if checkState.passed {
                passedView
            } else {
                notReadyView
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                if checkState.passed {
                    Button {
                        // Unlock next level and go back
                        appState.unlockNextLevel(subject: subject, level: level)
                        appState.navigateTo(.subjectSelection(subject))
                    } label: {
                        Text("Continue to Next Level")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: subject.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Button {
                        // Go practice the level
                        appState.startLesson(subject: subject, level: level)
                    } label: {
                        Text("Practice More")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: subject.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        appState.navigateTo(.subjectSelection(subject))
                    } label: {
                        Text("Back to Garden")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private var passedView: some View {
        VStack(spacing: 20) {
            // Celebration animation
            PlantGrowthAnimation(fromStage: .budding, toStage: .bloomed)

            Text("Your garden is ready!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("You got \(checkState.correctAnswers) out of \(checkState.questions.count) correct!")
                .font(.headline)
                .foregroundColor(.secondary)

            // Growth visualization
            HStack(spacing: 8) {
                Text("🌷")
                    .font(.system(size: 40))
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("🌸")
                    .font(.system(size: 40))
            }
            .padding()

            Text("Level \(level + 1) is now unlocked!")
                .font(.subheadline)
                .foregroundColor(.green)
                .fontWeight(.medium)
        }
        .padding()
    }

    private var notReadyView: some View {
        VStack(spacing: 20) {
            // Encouraging visual
            VStack(spacing: 8) {
                Text("🌱")
                    .font(.system(size: 80))

                Text("Your plants need more sun!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
            }

            Text("You got \(checkState.correctAnswers) out of \(checkState.questions.count) correct.")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Let's practice a bit more to help them grow stronger!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Show which items need work
            if !checkState.strugglingItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Focus on:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        ForEach(checkState.strugglingItems, id: \.self) { item in
                            Text(item)
                                .font(.headline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding()
                .background(Color.cardBackgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
}

// MARK: - Ready Check State

@MainActor
class ReadyCheckState: ObservableObject {
    @Published var questions: [ReadyCheckQuestion] = []
    @Published var currentIndex = 0
    @Published var correctAnswers = 0
    @Published var isReady = false
    @Published var isComplete = false
    @Published var isShowingFeedback = false
    @Published var showConfetti = false
    @Published var strugglingItems: [String] = []

    private var incorrectItems: [String] = []

    /// Pass threshold: 5/6 (83%)
    var passed: Bool {
        let threshold = Double(questions.count) * 0.83
        return Double(correctAnswers) >= threshold
    }

    func setup(
        subject: Subject,
        level: Int,
        profileId: UUID?,
        modelContext: ModelContext?
    ) {
        // Generate 6 questions from the level's content
        questions = generateQuestions(subject: subject, level: level)
        isReady = true
    }

    func submitAnswer(_ answer: String, isCorrect: Bool) {
        guard !isShowingFeedback else { return }

        isShowingFeedback = true

        if isCorrect {
            correctAnswers += 1
            SoundManager.shared.playSound(.correct)
            HapticFeedback.success()
        } else {
            // Track which items were missed
            if currentIndex < questions.count {
                let question = questions[currentIndex]
                incorrectItems.append(question.correctAnswer)
            }
            SoundManager.shared.playSound(.incorrect)
            HapticFeedback.error()
        }

        // Short delay then advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.advanceToNext()
        }
    }

    private func advanceToNext() {
        isShowingFeedback = false

        if currentIndex < questions.count - 1 {
            withAnimation {
                currentIndex += 1
            }
        } else {
            // Complete
            strugglingItems = Array(Set(incorrectItems)).prefix(3).map { $0 }
            withAnimation {
                isComplete = true
            }
            if passed {
                showConfetti = true
            }
        }
    }

    private func generateQuestions(subject: Subject, level: Int) -> [ReadyCheckQuestion] {
        var generatedQuestions: [ReadyCheckQuestion] = []

        if subject == .math {
            generatedQuestions = generateMathQuestions(level: level)
        } else {
            generatedQuestions = generateReadingQuestions(level: level)
        }

        // Shuffle and take 6
        return Array(generatedQuestions.shuffled().prefix(6))
    }

    private func generateMathQuestions(level: Int) -> [ReadyCheckQuestion] {
        var questions: [ReadyCheckQuestion] = []

        // Get number range for this level
        let numberRange: ClosedRange<Int>
        switch level {
        case 1: numberRange = 1...3
        case 2: numberRange = 4...5
        case 3: numberRange = 6...10
        case 4: numberRange = 11...15
        case 5: numberRange = 16...20
        default: numberRange = 1...5
        }

        let objects = ["🍎", "⭐️", "🌸", "🐟", "🎈"]

        for number in numberRange {
            let emoji = objects.randomElement()!
            let options = generateMathOptions(correct: number, range: numberRange)

            questions.append(ReadyCheckQuestion(
                questionText: "How many \(emojiName(emoji))?",
                visualEmoji: emoji,
                visualCount: number,
                visualDescription: "\(emojiName(emoji))",
                options: options.map { String($0) },
                correctAnswer: String(number)
            ))
        }

        return questions
    }

    private func generateReadingQuestions(level: Int) -> [ReadyCheckQuestion] {
        var questions: [ReadyCheckQuestion] = []

        // Letter data for each level
        let letterData: [(letter: String, word: String, emoji: String)]
        switch level {
        case 1: letterData = [("A", "Apple", "🍎"), ("B", "Ball", "⚽"), ("C", "Cat", "🐱")]
        case 2: letterData = [("D", "Dog", "🐕"), ("E", "Egg", "🥚"), ("F", "Fish", "🐟")]
        case 3: letterData = [("G", "Grapes", "🍇"), ("H", "Hat", "🎩"), ("I", "Ice cream", "🍦"), ("J", "Juice", "🧃"), ("K", "Kite", "🪁")]
        case 4: letterData = [("L", "Lion", "🦁"), ("M", "Moon", "🌙"), ("N", "Nest", "🪺"), ("O", "Orange", "🍊"), ("P", "Pig", "🐷")]
        case 5: letterData = [("Q", "Queen", "👸"), ("R", "Rainbow", "🌈"), ("S", "Sun", "☀️"), ("T", "Tree", "🌳"), ("U", "Umbrella", "☂️")]
        case 6: letterData = [("V", "Violin", "🎻"), ("W", "Whale", "🐋"), ("X", "Xylophone", "🎵"), ("Y", "Yarn", "🧶"), ("Z", "Zebra", "🦓")]
        default: letterData = [("A", "Apple", "🍎"), ("B", "Ball", "⚽"), ("C", "Cat", "🐱")]
        }

        let allLetters = letterData.map { $0.letter }

        for (letter, word, emoji) in letterData {
            let options = generateLetterOptions(correct: letter, allLetters: allLetters)

            questions.append(ReadyCheckQuestion(
                questionText: "What letter does \(word) start with?",
                visualEmoji: emoji,
                visualCount: 1,
                visualDescription: word,
                options: options,
                correctAnswer: letter
            ))
        }

        return questions
    }

    private func generateMathOptions(correct: Int, range: ClosedRange<Int>) -> [Int] {
        var options = Set<Int>([correct])

        // Add nearby numbers as distractors
        let nearby = [correct - 1, correct + 1, correct - 2, correct + 2]
            .filter { range.contains($0) && $0 != correct }
            .shuffled()

        for num in nearby {
            if options.count >= 3 { break }
            options.insert(num)
        }

        // Fill with random if needed
        while options.count < 3 {
            let random = Int.random(in: range)
            options.insert(random)
        }

        return Array(options).sorted()
    }

    private func generateLetterOptions(correct: String, allLetters: [String]) -> [String] {
        var options = Set<String>([correct])

        for letter in allLetters.shuffled() {
            if options.count >= 3 { break }
            options.insert(letter)
        }

        // Fill with random letters if needed
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map { String($0) }
        for letter in alphabet.shuffled() {
            if options.count >= 3 { break }
            options.insert(letter)
        }

        return Array(options).sorted()
    }

    private func emojiName(_ emoji: String) -> String {
        switch emoji {
        case "🍎": return "apples"
        case "⭐️": return "stars"
        case "🌸": return "flowers"
        case "🐟": return "fish"
        case "🎈": return "balloons"
        default: return "items"
        }
    }
}

// MARK: - Ready Check Question

struct ReadyCheckQuestion: Identifiable {
    let id = UUID()
    let questionText: String
    let visualEmoji: String
    let visualCount: Int
    let visualDescription: String
    let options: [String]
    let correctAnswer: String
}

// MARK: - AppState Extension for Level Unlocking

extension AppState {
    func unlockNextLevel(subject: Subject, level: Int) {
        switch subject {
        case .math:
            if level < mathLevels.count {
                mathLevels[level].isUnlocked = true
            }
        case .reading:
            if level < readingLevels.count {
                readingLevels[level].isUnlocked = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Ready Check - Math") {
    ReadyCheckView(subject: .math, level: 1)
        .environmentObject(AppState())
}

#Preview("Ready Check - Reading") {
    ReadyCheckView(subject: .reading, level: 1)
        .environmentObject(AppState())
}
