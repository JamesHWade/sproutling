//
//  ReadingActivities.swift
//  Sproutling
//
//  Reading and phonics learning activities
//

import SwiftUI

// MARK: - Letter Card Activity
/// Shows a letter with its sound and example word
struct LetterCardActivity: View {
    let letter: String
    let word: String
    let emoji: String
    let sound: String
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var step = 0 // 0: letter, 1: sound, 2: word
    @State private var completed = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Tappable content area
            VStack(spacing: 24) {
                // Large letter card
                LargeLetterCard(letter: letter)
                    .onTapGesture {
                        advanceStep()
                    }

                // Progressive reveal
                if step >= 1 {
                    soundReveal
                        .transition(.scale.combined(with: .opacity))
                }

                if step >= 2 {
                    wordReveal
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4), value: step)

            Spacer()

            // Instructions or next button
            if step < 2 {
                Text("Tap to continue...")
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else if completed {
                Button(action: onNext) {
                    Text("Next Letter →")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
            }

            Spacer().frame(height: 40)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            advanceStep()
        }
    }

    // MARK: - Sound Reveal
    private var soundReveal: some View {
        VStack(spacing: 8) {
            Text("\"\(letter)\" says")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            Text("\"\(sound)\"")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.pink)
        }
    }

    // MARK: - Word Reveal
    private var wordReveal: some View {
        VStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 70))

            HStack(spacing: 0) {
                Text(letter)
                    .foregroundColor(.pink)
                Text(" is for \(word)!")
                    .foregroundColor(.primary)
            }
            .font(.title)
            .fontWeight(.bold)
        }
    }

    // MARK: - Advance Step
    private func advanceStep() {
        SoundManager.shared.playSound(.tap)
        HapticFeedback.light()

        if step < 2 {
            withAnimation {
                step += 1
            }
            // Speak the letter sound when revealing step 1
            if step == 1 {
                SoundManager.shared.speakLetterSound(letter)
            }
            // Speak the word when revealing step 2
            if step == 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    SoundManager.shared.speak(word)
                }
            }
        } else if !completed {
            completed = true
            onCorrect()
            SoundManager.shared.playSound(.correct)
            HapticFeedback.success()
        }
    }
}

// MARK: - Letter Matching Activity
/// Match a letter to its word/picture
struct LetterMatchingActivity: View {
    let targetLetter: String
    let options: [String]
    let word: String
    let emoji: String
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var selectedLetter: String?
    @State private var showResult = false
    @State private var isCorrect = false

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            Text("Find the letter for...")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // Word with emoji
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 70))

                Text(word)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
            }
            .padding(.vertical)

            // Letter options
            optionsRow

            Spacer()

            // Result section
            if showResult {
                resultSection
            }
        }
        .padding()
    }

    // MARK: - Options Row
    private var optionsRow: some View {
        HStack(spacing: 16) {
            ForEach(options, id: \.self) { letter in
                LetterOptionButton(
                    letter: letter,
                    isSelected: selectedLetter == letter,
                    isCorrect: showResult ? (letter == targetLetter ? true : (letter == selectedLetter ? false : nil)) : nil,
                    isDisabled: showResult
                ) {
                    selectLetter(letter)
                }
            }
        }
    }

    // MARK: - Result Section
    private var resultSection: some View {
        VStack(spacing: 16) {
            if isCorrect {
                MascotView(emotion: .proud, message: "Yes! \(targetLetter) is for \(word)!")

                Button(action: onNext) {
                    Text("Next →")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
            } else {
                VStack(spacing: 12) {
                    Text("Oops!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)

                    Text("Listen: \(word) starts with \"\(targetLetter)\"")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Button(action: reset) {
                    Text("Try Again")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.orange, .yellow]))
            }
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Actions
    private func selectLetter(_ letter: String) {
        SoundManager.shared.playSound(.tap)
        HapticFeedback.medium()

        selectedLetter = letter
        showResult = true
        isCorrect = letter == targetLetter

        if isCorrect {
            onCorrect()
            SoundManager.shared.playSound(.correct)
            SoundManager.shared.speak(word)
            HapticFeedback.success()
        } else {
            SoundManager.shared.playSound(.incorrect)
            HapticFeedback.error()
        }
    }

    private func reset() {
        withAnimation {
            selectedLetter = nil
            showResult = false
            isCorrect = false
        }
    }
}

// MARK: - Phonics Blending Activity
/// Blend letter sounds to form a word
struct PhonicsBlendingActivity: View {
    let letters: [String]
    let word: String
    let emoji: String
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var revealedIndex = -1
    @State private var showWord = false
    @State private var completed = false

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            Text("Tap each letter to hear its sound!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Spacer()

            // Letters to blend
            lettersRow

            // Sound indicators
            soundIndicators

            Spacer()

            // Word reveal
            if showWord {
                wordReveal
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Letters Row
    private var lettersRow: some View {
        HStack(spacing: 16) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                PhonicsLetterButton(
                    letter: letter,
                    isRevealed: index <= revealedIndex,
                    isNext: index == revealedIndex + 1
                ) {
                    tapLetter(at: index)
                }
            }
        }
    }

    // MARK: - Sound Indicators
    private var soundIndicators: some View {
        HStack(spacing: 32) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                Text("/\(letter.lowercased())/")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(index <= revealedIndex ? .purple : .gray.opacity(0.4))
                    .animation(.easeInOut, value: revealedIndex)
            }
        }
        .padding(.top)
    }

    // MARK: - Word Reveal
    private var wordReveal: some View {
        VStack(spacing: 16) {
            Text(emoji)
                .font(.system(size: 70))

            Text(word + "!")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.green)

            Text("\(letters.joined(separator: "-")) makes \"\(word)\"!")
                .font(.title3)
                .foregroundColor(.secondary)

            if !completed {
                Button(action: {
                    completed = true
                    onCorrect()
                    SoundManager.shared.playSound(.celebration)
                    SoundManager.shared.speak(word)
                    HapticFeedback.success()
                }) {
                    Text("I can read it! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.purple, .pink]))
                .padding(.top)
            } else {
                Button(action: onNext) {
                    Text("Next Word →")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
                .padding(.top)
            }
        }
    }

    // MARK: - Tap Letter
    private func tapLetter(at index: Int) {
        guard index == revealedIndex + 1 else { return }

        SoundManager.shared.playSound(.tap)
        HapticFeedback.medium()

        // Speak the letter sound
        SoundManager.shared.speakLetterSound(letters[index])

        withAnimation(.spring()) {
            revealedIndex = index
        }

        // Show word after all letters revealed
        if index == letters.count - 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring()) {
                    showWord = true
                }
                SoundManager.shared.playSound(.whoosh)
            }
        }
    }
}

// MARK: - Previews
#Preview("Letter Card") {
    LetterCardActivity(
        letter: "A",
        word: "Apple",
        emoji: "🍎",
        sound: "ah",
        onCorrect: {},
        onNext: {}
    )
}

#Preview("Letter Matching") {
    LetterMatchingActivity(
        targetLetter: "C",
        options: ["A", "C", "D"],
        word: "Cat",
        emoji: "🐱",
        onCorrect: {},
        onNext: {}
    )
}

#Preview("Phonics Blending") {
    PhonicsBlendingActivity(
        letters: ["C", "A", "T"],
        word: "CAT",
        emoji: "🐱",
        onCorrect: {},
        onNext: {}
    )
}
