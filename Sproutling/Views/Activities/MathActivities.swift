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
                    .modifier(PulseModifier(delay: Double(index) * 0.1))
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

            Text("\(number) \(objectName)! Great counting! 🎉")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
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
        .modifier(PulseModifier(delay: 0))
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
                MascotView(emotion: .excited, message: "You got it! Amazing!")

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
            Text("Perfect! You counted to \(targetNumber)! 🌟")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
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

// MARK: - Pulse Animation Modifier
struct PulseModifier: ViewModifier {
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
