//
//  MathActivities.swift
//  Sproutling
//
//  Math learning activities
//

import SwiftUI

// MARK: - Number With Objects Activity
/// Shows objects to count, then reveals the number
struct NumberWithObjectsActivity: View {
    let number: Int
    let objectName: String
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var showAnswer = false
    @State private var isCorrect = false

    private var emoji: String {
        CountingObjects.emoji(for: objectName)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            Text("How many \(objectName)? Count with me!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Objects to count
            objectsGrid
                .padding(.vertical)

            // Number reveal or tap button
            if showAnswer {
                numberReveal
            } else {
                revealButton
            }

            Spacer()

            // Next button
            if isCorrect {
                nextButton
            }
        }
        .padding()
    }

    // MARK: - Objects Grid
    private var objectsGrid: some View {
        let columns = number <= 3 ? number : (number <= 6 ? 3 : 4)

        return LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: columns),
            spacing: 16
        ) {
            ForEach(0..<number, id: \.self) { index in
                Text(emoji)
                    .font(.system(size: 50))
                    .modifier(DelayedPulseModifier(delay: Double(index) * 0.1))
            }
        }
        .padding()
    }

    // MARK: - Reveal Button
    private var revealButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                showAnswer = true
            }

            // Sound and haptic feedback
            SoundManager.shared.playSound(.pop)
            HapticFeedback.medium()

            // Mark as correct after delay and speak number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    isCorrect = true
                }
                SoundManager.shared.playSound(.correct)
                SoundManager.shared.speakNumber(number)
                onCorrect()
            }
        }) {
            Text("Tap to see the number!")
                .font(.title2)
                .fontWeight(.bold)
        }
        .buttonStyle(PrimaryButtonStyle(colors: [.purple, .pink]))
    }

    // MARK: - Number Reveal
    private var numberReveal: some View {
        VStack(spacing: 16) {
            Text("\(number)")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .foregroundColor(.purple)
                .modifier(BounceModifier())

            VStack(spacing: 8) {
                Text("There are \(number) \(objectName)! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Text("The last number tells us how many!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Next Button
    private var nextButton: some View {
        Button(action: onNext) {
            Text("Next →")
                .font(.title2)
                .fontWeight(.bold)
        }
        .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
        .modifier(DelayedPulseModifier(delay: 0))
    }
}

// MARK: - Number Matching Activity
/// Match the correct number to a quantity of objects
struct NumberMatchingActivity: View {
    let targetNumber: Int
    let options: [Int]
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var selectedNumber: Int?
    @State private var showResult = false
    @State private var isCorrect = false

    private var emoji: String {
        ["🍎", "🌟", "🐟", "🦋", "🌸"][targetNumber % 5]
    }

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            Text("Which number shows this many?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            // Objects to count
            objectsDisplay
                .padding(.vertical)

            // Number options
            optionsRow

            Spacer()

            // Result and next
            if showResult {
                resultSection
            }
        }
        .padding()
    }

    // MARK: - Objects Display
    private var objectsDisplay: some View {
        HStack(spacing: 12) {
            ForEach(0..<targetNumber, id: \.self) { _ in
                Text(emoji)
                    .font(.system(size: 44))
            }
        }
        .padding()
    }

    // MARK: - Options Row
    private var optionsRow: some View {
        HStack(spacing: 16) {
            ForEach(options, id: \.self) { num in
                NumberOptionButton(
                    number: num,
                    isSelected: selectedNumber == num,
                    isCorrect: showResult ? (num == targetNumber ? true : (num == selectedNumber ? false : nil)) : nil,
                    isDisabled: showResult
                ) {
                    selectNumber(num)
                }
            }
        }
    }

    // MARK: - Result Section
    private var resultSection: some View {
        VStack(spacing: 16) {
            if isCorrect {
                MascotView(emotion: .excited, message: "You figured it out!")

                Button(action: onNext) {
                    Text("Next →")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
            } else {
                Text("Let's try again! Count carefully 🧡")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)

                Button(action: reset) {
                    Text("Try Again")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.orange, .yellow]))
            }
        }
    }

    // MARK: - Actions
    private func selectNumber(_ num: Int) {
        SoundManager.shared.playSound(.tap)
        HapticFeedback.medium()

        selectedNumber = num
        showResult = true
        isCorrect = num == targetNumber

        if isCorrect {
            onCorrect()
            SoundManager.shared.playSound(.correct)
            HapticFeedback.success()
        } else {
            SoundManager.shared.playSound(.incorrect)
            HapticFeedback.error()
        }
    }

    private func reset() {
        withAnimation {
            selectedNumber = nil
            showResult = false
            isCorrect = false
        }
    }
}

// MARK: - Counting Touch Activity
/// Tap to count up to a target number
struct CountingTouchActivity: View {
    let targetNumber: Int
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var count = 0
    @State private var completed = false

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            VStack(spacing: 8) {
                Text("Tap \(targetNumber) times!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Count out loud as you tap!")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Tap circle
            TapCircle(count: count, target: targetNumber) {
                count += 1
                SoundManager.shared.playSound(.tap)
                SoundManager.shared.speakNumber(count)

                if count == targetNumber {
                    completed = true
                    onCorrect()
                    SoundManager.shared.playSound(.celebration)
                    HapticFeedback.success()
                }
            }

            // Progress dots
            progressDots

            Spacer()

            // Completion
            if completed {
                completionSection
            }
        }
        .padding()
    }

    // MARK: - Progress Dots
    private var progressDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<targetNumber, id: \.self) { index in
                Circle()
                    .fill(index < count ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .scaleEffect(index < count ? 1.1 : 1.0)
                    .animation(.spring(), value: count)
            }
        }
        .padding(.top)
    }

    // MARK: - Completion Section
    private var completionSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("You did it! 🌟")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Text("How many taps was that?")
                    .font(.title3)
                    .foregroundColor(.primary)

                Text("\(targetNumber)!")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
            }
            .multilineTextAlignment(.center)

            Button(action: onNext) {
                Text("Next →")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
        }
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Subitizing Activity
/// Flash objects briefly, ask "how many?" - builds instant number recognition
struct SubitizingActivity: View {
    let number: Int
    let objectName: String
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var showObjects = true
    @State private var showOptions = false
    @State private var selectedAnswer: Int?
    @State private var isCorrect: Bool?
    @State private var attempts = 0

    private var emoji: String {
        CountingObjects.emoji(for: objectName)
    }

    private var options: [Int] {
        // Generate 3 options including the correct answer
        var opts = Set<Int>()
        opts.insert(number)
        while opts.count < 3 {
            let offset = Int.random(in: 1...2) * (Bool.random() ? 1 : -1)
            let option = max(1, number + offset)
            if option != number && option <= 10 {
                opts.insert(option)
            }
        }
        return Array(opts).sorted()
    }

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            Text(showOptions ? "How many did you see?" : "Look carefully!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .animation(.easeInOut, value: showOptions)

            Spacer()

            if showObjects {
                // Flash the objects briefly
                objectsDisplay
                    .transition(.scale.combined(with: .opacity))
            } else if showOptions {
                // Show answer options
                optionsDisplay
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            // Result section
            if let isCorrect = isCorrect {
                resultSection(isCorrect: isCorrect)
            }
        }
        .padding()
        .onAppear {
            startFlashSequence()
        }
    }

    private var objectsDisplay: some View {
        let columns = number <= 3 ? number : (number <= 4 ? 2 : 3)

        return VStack {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: columns),
                spacing: 20
            ) {
                ForEach(0..<number, id: \.self) { _ in
                    Text(emoji)
                        .font(.system(size: 60))
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.purple.opacity(0.1))
            )
        }
    }

    private var optionsDisplay: some View {
        VStack(spacing: 24) {
            // Question mark indicator
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .symbolEffect(.pulse)

            // Answer buttons
            HStack(spacing: 20) {
                ForEach(options, id: \.self) { option in
                    NumberOptionButton(
                        number: option,
                        isSelected: selectedAnswer == option,
                        isCorrect: selectedAnswer == option ? isCorrect : nil,
                        isDisabled: isCorrect == true,
                        action: { selectAnswer(option) }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func resultSection(isCorrect: Bool) -> some View {
        VStack(spacing: 16) {
            if isCorrect {
                MascotView(emotion: .excited, message: "You saw it quickly!")

                Button(action: onNext) {
                    Text("Next →")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
            } else {
                Text("Try again! Look carefully.")
                    .font(.title3)
                    .foregroundColor(.orange)

                Button(action: retry) {
                    Text("Show me again")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.orange, .pink]))
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private func startFlashSequence() {
        showObjects = true
        showOptions = false
        selectedAnswer = nil
        isCorrect = nil

        // Flash objects for 1.5-2 seconds based on number size
        let flashDuration = number <= 3 ? 1.5 : 2.0

        DispatchQueue.main.asyncAfter(deadline: .now() + flashDuration) {
            withAnimation(.easeInOut(duration: 0.3)) {
                showObjects = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring()) {
                    showOptions = true
                }
            }
        }
    }

    private func selectAnswer(_ answer: Int) {
        SoundManager.shared.playSound(.tap)
        HapticFeedback.medium()

        selectedAnswer = answer
        attempts += 1

        withAnimation {
            isCorrect = (answer == number)
        }

        if answer == number {
            SoundManager.shared.playSound(.correct)
            HapticFeedback.success()
            onCorrect()
        } else {
            SoundManager.shared.playSound(.incorrect)
            HapticFeedback.error()
        }
    }

    private func retry() {
        withAnimation {
            showOptions = false
            selectedAnswer = nil
            isCorrect = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            startFlashSequence()
        }
    }
}

// MARK: - Comparison Activity
/// Compare two groups: which has more, less, or are they the same?
struct ComparisonActivity: View {
    let leftCount: Int
    let rightCount: Int
    let leftObjects: String
    let rightObjects: String
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var selectedSide: Side?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var questionType: QuestionType = .more

    enum Side {
        case left, right, same
    }

    enum QuestionType: CaseIterable {
        case more, less

        var question: String {
            switch self {
            case .more: return "Which group has MORE?"
            case .less: return "Which group has LESS?"
            }
        }
    }

    private var leftEmoji: String {
        CountingObjects.emoji(for: leftObjects)
    }

    private var rightEmoji: String {
        CountingObjects.emoji(for: rightObjects)
    }

    private var correctAnswer: Side {
        switch questionType {
        case .more:
            if leftCount > rightCount { return .left }
            else if rightCount > leftCount { return .right }
            else { return .same }
        case .less:
            if leftCount < rightCount { return .left }
            else if rightCount < leftCount { return .right }
            else { return .same }
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Question
            Text(questionType.question)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Spacer()

            // Two groups side by side
            HStack(spacing: 24) {
                // Left group
                groupView(
                    count: leftCount,
                    emoji: leftEmoji,
                    side: .left,
                    isSelected: selectedSide == .left,
                    isCorrectChoice: showResult && correctAnswer == .left
                )

                // VS divider
                Text("or")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                // Right group
                groupView(
                    count: rightCount,
                    emoji: rightEmoji,
                    side: .right,
                    isSelected: selectedSide == .right,
                    isCorrectChoice: showResult && correctAnswer == .right
                )
            }
            .padding(.horizontal)

            // Same button (only show if counts are equal)
            if leftCount == rightCount {
                Button(action: { selectAnswer(.same) }) {
                    Text("They're the same!")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: selectedSide == .same ? [.green, .teal] : [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                }
                .disabled(showResult)
            }

            Spacer()

            // Result section
            if showResult {
                resultSection
            }
        }
        .padding()
        .onAppear {
            // Randomly choose question type
            questionType = QuestionType.allCases.randomElement() ?? .more
        }
    }

    @ViewBuilder
    private func groupView(count: Int, emoji: String, side: Side, isSelected: Bool, isCorrectChoice: Bool) -> some View {
        let columns = count <= 3 ? count : (count <= 4 ? 2 : 3)

        VStack(spacing: 8) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, columns)),
                spacing: 8
            ) {
                ForEach(0..<count, id: \.self) { _ in
                    Text(emoji)
                        .font(.system(size: 36))
                }
            }
            .padding(16)
            .frame(minWidth: 120, minHeight: 100)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(backgroundColor(isSelected: isSelected, isCorrectChoice: isCorrectChoice))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor(isSelected: isSelected, isCorrectChoice: isCorrectChoice), lineWidth: 4)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)

            // Count label (shown after selection)
            if showResult {
                Text("\(count)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(isCorrectChoice ? .green : .primary)
            }
        }
        .onTapGesture {
            if !showResult {
                selectAnswer(side)
            }
        }
    }

    private func backgroundColor(isSelected: Bool, isCorrectChoice: Bool) -> Color {
        if showResult {
            return isCorrectChoice ? Color.green.opacity(0.2) : Color.gray.opacity(0.1)
        }
        return isSelected ? Color.purple.opacity(0.2) : Color.white
    }

    private func borderColor(isSelected: Bool, isCorrectChoice: Bool) -> Color {
        if showResult {
            return isCorrectChoice ? .green : .clear
        }
        return isSelected ? .purple : .gray.opacity(0.3)
    }

    private var resultSection: some View {
        VStack(spacing: 16) {
            if isCorrect {
                MascotView(emotion: .proud, message: correctMessage)

                Button(action: onNext) {
                    Text("Next →")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
            } else {
                Text("Look again! Count each group.")
                    .font(.title3)
                    .foregroundColor(.orange)

                Button(action: reset) {
                    Text("Try Again")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.orange, .pink]))
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var correctMessage: String {
        if leftCount == rightCount {
            return "They both have \(leftCount)!"
        } else {
            let more = leftCount > rightCount ? leftCount : rightCount
            let less = leftCount < rightCount ? leftCount : rightCount
            switch questionType {
            case .more:
                return "\(more) is more than \(less)!"
            case .less:
                return "\(less) is less than \(more)!"
            }
        }
    }

    private func selectAnswer(_ side: Side) {
        SoundManager.shared.playSound(.tap)
        HapticFeedback.medium()

        selectedSide = side
        showResult = true
        isCorrect = (side == correctAnswer)

        if isCorrect {
            SoundManager.shared.playSound(.correct)
            HapticFeedback.success()
            onCorrect()
        } else {
            SoundManager.shared.playSound(.incorrect)
            HapticFeedback.error()
        }
    }

    private func reset() {
        withAnimation {
            selectedSide = nil
            showResult = false
            isCorrect = false
        }
    }
}

// MARK: - Delayed Pulse Animation Modifier
struct DelayedPulseModifier: ViewModifier {
    let delay: Double
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(pulse ? 1.0 : 0.9)
            .opacity(pulse ? 1.0 : 0.7)
            .animation(
                .easeInOut(duration: 0.6)
                .delay(delay)
                .repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear { pulse = true }
    }
}

// MARK: - Previews
#Preview("Number With Objects") {
    NumberWithObjectsActivity(
        number: 3,
        objectName: "apples",
        onCorrect: {},
        onNext: {}
    )
}

#Preview("Number Matching") {
    NumberMatchingActivity(
        targetNumber: 4,
        options: [2, 4, 6],
        onCorrect: {},
        onNext: {}
    )
}

#Preview("Counting Touch") {
    CountingTouchActivity(
        targetNumber: 5,
        onCorrect: {},
        onNext: {}
    )
}

#Preview("Comparison") {
    ComparisonActivity(
        leftCount: 3,
        rightCount: 5,
        leftObjects: "apples",
        rightObjects: "apples",
        onCorrect: {},
        onNext: {}
    )
}
