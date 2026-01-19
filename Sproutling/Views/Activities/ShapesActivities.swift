//
//  ShapesActivities.swift
//  Sproutling
//
//  Shapes and colors learning activities
//

import SwiftUI

// MARK: - Shape Data

/// Shape visual representations using SF Symbols and emoji
struct ShapeVisuals {
    static let shapes: [String: (symbol: String, emoji: String)] = [
        "circle": ("circle.fill", "🔵"),
        "square": ("square.fill", "🟥"),
        "triangle": ("triangle.fill", "🔺"),
        "rectangle": ("rectangle.fill", "📱"),
        "star": ("star.fill", "⭐"),
        "heart": ("heart.fill", "❤️")
    ]

    static func symbol(for shape: String) -> String {
        shapes[shape]?.symbol ?? "questionmark.circle.fill"
    }

    static func emoji(for shape: String) -> String {
        shapes[shape]?.emoji ?? "❓"
    }

    static func displayName(for shape: String) -> String {
        shape.capitalized
    }
}

/// Color visual representations
struct ColorVisuals {
    static let colors: [String: Color] = [
        "red": .red,
        "blue": .blue,
        "yellow": .yellow,
        "green": .green,
        "orange": .orange,
        "purple": .purple,
        "pink": .pink,
        "brown": .brown,
        "black": .black,
        "white": .white
    ]

    static func color(for name: String) -> Color {
        colors[name] ?? .gray
    }

    static func displayName(for color: String) -> String {
        color.capitalized
    }
}

// MARK: - Shape Card Activity
/// Shows a shape with its name - progressive reveal style
struct ShapeCardActivity: View {
    let shape: String
    let emoji: String
    @ObservedObject var lessonState: LessonState
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var showName = false
    @State private var completed = false
    @State private var hasSpokenInstruction = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Instructions
            Text(showName ? "This is a \(ShapeVisuals.displayName(for: shape))!" : "What shape is this?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .onAppear {
                    if !hasSpokenInstruction {
                        hasSpokenInstruction = true
                        SoundManager.shared.speakInstruction("What shape is this? Tap to find out!")
                    }
                }

            // Large shape display
            VStack(spacing: 20) {
                // SF Symbol shape
                Image(systemName: ShapeVisuals.symbol(for: shape))
                    .font(.system(size: 120))
                    .foregroundStyle(
                        LinearGradient(
                            colors: Subject.shapes.gradient,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(showName ? 1.1 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showName)

                // Emoji representation
                Text(emoji)
                    .font(.system(size: 60))

                // Shape name (revealed)
                if showName {
                    Text(ShapeVisuals.displayName(for: shape))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.teal)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardBackground)
            )
            .adaptiveShadow()
            .onTapGesture {
                revealShape()
            }

            Spacer()

            // Reveal or Next button
            if !showName {
                Button(action: revealShape) {
                    Text("Tap to see the name!")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: Subject.shapes.gradient))
            } else if completed {
                Button(action: onNext) {
                    Text("Next Shape →")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
            }

            Spacer().frame(height: 40)
        }
        .padding()
        .animation(.spring(response: 0.4), value: showName)
    }

    private func revealShape() {
        guard !showName else {
            // Already revealed, tapping again to proceed
            return
        }

        withAnimation(.spring()) {
            showName = true
        }

        SoundManager.shared.playSound(.pop)
        HapticFeedback.medium()

        // Speak the shape name
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            SoundManager.shared.speakWithElevenLabs(
                "This is a \(shape)!",
                settings: .childFriendly
            )
        }

        // Mark correct after delay (only call once)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard !completed else { return }
            completed = true
            onCorrect()
            SoundManager.shared.playSound(.correct)
        }
    }
}

// MARK: - Shape Matching Activity
/// Match the shape to its name
struct ShapeMatchingActivity: View {
    let targetShape: String
    let emoji: String
    let options: [String]
    @ObservedObject var lessonState: LessonState
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    let onNext: () -> Void

    @State private var selectedShape: String?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var hasSpokenInstruction = false

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            Text("Which shape is this?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .onAppear {
                    if !hasSpokenInstruction {
                        hasSpokenInstruction = true
                        SoundManager.shared.speakInstruction("Which shape is this? Tap to pick!")
                    }
                }

            // Shape display
            VStack(spacing: 16) {
                Image(systemName: ShapeVisuals.symbol(for: targetShape))
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: Subject.shapes.gradient,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                Text(emoji)
                    .font(.system(size: 50))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
            )
            .adaptiveShadow()

            // Answer options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(options, id: \.self) { shape in
                    ShapeOptionButton(
                        shape: shape,
                        isSelected: selectedShape == shape,
                        isCorrect: showResult && shape == targetShape,
                        isIncorrect: showResult && selectedShape == shape && shape != targetShape,
                        action: { selectShape(shape) }
                    )
                    .disabled(showResult)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Result and next
            if showResult {
                resultView
            }
        }
        .padding()
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            if isCorrect {
                Text("That's right! It's a \(ShapeVisuals.displayName(for: targetShape))! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            } else {
                Text("Not quite! This is a \(ShapeVisuals.displayName(for: targetShape))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }

            Button(action: onNext) {
                Text("Next →")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
        }
    }

    private func selectShape(_ shape: String) {
        selectedShape = shape
        isCorrect = shape == targetShape

        withAnimation(.spring()) {
            showResult = true
        }

        if isCorrect {
            SoundManager.shared.playSound(.correct)
            HapticFeedback.success()
            onCorrect()
            lessonState.handleCorrectWithTTS()
        } else {
            SoundManager.shared.playSound(.incorrect)
            HapticFeedback.error()
            onIncorrect()
            lessonState.handleIncorrectWithTTS()
        }
    }
}

// MARK: - Color Card Activity
/// Shows a color with examples
struct ColorCardActivity: View {
    let color: String
    let emoji: String
    @ObservedObject var lessonState: LessonState
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var showName = false
    @State private var completed = false
    @State private var hasSpokenInstruction = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Instructions
            Text(showName ? "This is \(ColorVisuals.displayName(for: color))!" : "What color is this?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .onAppear {
                    if !hasSpokenInstruction {
                        hasSpokenInstruction = true
                        SoundManager.shared.speakInstruction("What color is this? Tap to find out!")
                    }
                }

            // Large color display
            VStack(spacing: 20) {
                // Color circle
                Circle()
                    .fill(ColorVisuals.color(for: color))
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.2), lineWidth: 3)
                    )
                    .shadow(color: ColorVisuals.color(for: color).opacity(0.4), radius: 10, y: 5)

                // Emoji example
                Text(emoji)
                    .font(.system(size: 60))

                // Color name (revealed)
                if showName {
                    Text(ColorVisuals.displayName(for: color))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(ColorVisuals.color(for: color))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.cardBackground)
            )
            .adaptiveShadow()
            .onTapGesture {
                revealColor()
            }

            Spacer()

            // Reveal or Next button
            if !showName {
                Button(action: revealColor) {
                    Text("Tap to see the color!")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: Subject.shapes.gradient))
            } else if completed {
                Button(action: onNext) {
                    Text("Next Color →")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
            }

            Spacer().frame(height: 40)
        }
        .padding()
        .animation(.spring(response: 0.4), value: showName)
    }

    private func revealColor() {
        guard !showName else {
            // Already revealed, tapping again to proceed
            return
        }

        withAnimation(.spring()) {
            showName = true
        }

        SoundManager.shared.playSound(.pop)
        HapticFeedback.medium()

        // Speak the color name
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            SoundManager.shared.speakWithElevenLabs(
                "This is \(color)!",
                settings: .childFriendly
            )
        }

        // Mark correct after delay (only call once)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            guard !completed else { return }
            completed = true
            onCorrect()
            SoundManager.shared.playSound(.correct)
        }
    }
}

// MARK: - Color Matching Activity
/// Match the color to its name
struct ColorMatchingActivity: View {
    let targetColor: String
    let emoji: String
    let options: [String]
    @ObservedObject var lessonState: LessonState
    let onCorrect: () -> Void
    let onIncorrect: () -> Void
    let onNext: () -> Void

    @State private var selectedColor: String?
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var hasSpokenInstruction = false

    var body: some View {
        VStack(spacing: 24) {
            // Instructions
            Text("What color is this?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .onAppear {
                    if !hasSpokenInstruction {
                        hasSpokenInstruction = true
                        SoundManager.shared.speakInstruction("What color is this? Tap to pick!")
                    }
                }

            // Color display
            VStack(spacing: 16) {
                Circle()
                    .fill(ColorVisuals.color(for: targetColor))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                    )

                Text(emoji)
                    .font(.system(size: 50))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
            )
            .adaptiveShadow()

            // Answer options
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(options, id: \.self) { color in
                    ColorOptionButton(
                        color: color,
                        isSelected: selectedColor == color,
                        isCorrect: showResult && color == targetColor,
                        isIncorrect: showResult && selectedColor == color && color != targetColor,
                        action: { selectColor(color) }
                    )
                    .disabled(showResult)
                }
            }
            .padding(.horizontal)

            Spacer()

            // Result and next
            if showResult {
                resultView
            }
        }
        .padding()
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            if isCorrect {
                Text("That's right! It's \(ColorVisuals.displayName(for: targetColor))! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.center)
            } else {
                Text("Not quite! This is \(ColorVisuals.displayName(for: targetColor))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
            }

            Button(action: onNext) {
                Text("Next →")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))
        }
    }

    private func selectColor(_ color: String) {
        selectedColor = color
        isCorrect = color == targetColor

        withAnimation(.spring()) {
            showResult = true
        }

        if isCorrect {
            SoundManager.shared.playSound(.correct)
            HapticFeedback.success()
            onCorrect()
            lessonState.handleCorrectWithTTS()
        } else {
            SoundManager.shared.playSound(.incorrect)
            HapticFeedback.error()
            onIncorrect()
            lessonState.handleIncorrectWithTTS()
        }
    }
}

// MARK: - Shape Option Button
struct ShapeOptionButton: View {
    let shape: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: ShapeVisuals.symbol(for: shape))
                    .font(.system(size: 40))
                    .foregroundColor(buttonForeground)

                Text(ShapeVisuals.displayName(for: shape))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(buttonForeground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(buttonBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(buttonBorder, lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var buttonBackground: Color {
        if isCorrect { return Color.green.opacity(0.2) }
        if isIncorrect { return Color.red.opacity(0.2) }
        if isSelected { return Color.teal.opacity(0.2) }
        return Color.cardBackground
    }

    private var buttonBorder: Color {
        if isCorrect { return .green }
        if isIncorrect { return .red }
        if isSelected { return .teal }
        return Color.primary.opacity(0.2)
    }

    private var buttonForeground: Color {
        if isCorrect { return .green }
        if isIncorrect { return .red }
        return .primary
    }
}

// MARK: - Color Option Button
struct ColorOptionButton: View {
    let color: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(ColorVisuals.color(for: color))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )

                Text(ColorVisuals.displayName(for: color))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(buttonForeground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(buttonBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(buttonBorder, lineWidth: isSelected ? 3 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var buttonBackground: Color {
        if isCorrect { return Color.green.opacity(0.2) }
        if isIncorrect { return Color.red.opacity(0.2) }
        if isSelected { return ColorVisuals.color(for: color).opacity(0.2) }
        return Color.cardBackground
    }

    private var buttonBorder: Color {
        if isCorrect { return .green }
        if isIncorrect { return .red }
        if isSelected { return ColorVisuals.color(for: color) }
        return Color.primary.opacity(0.2)
    }

    private var buttonForeground: Color {
        if isCorrect { return .green }
        if isIncorrect { return .red }
        return .primary
    }
}

// MARK: - Shape Sorting Activity (Placeholder)
/// Sort items by shape or color - can be expanded later
struct ShapeSortingActivity: View {
    let coloredShapes: [String]
    let sortBy: String // "shape" or "color"
    @ObservedObject var lessonState: LessonState
    let onCorrect: () -> Void
    let onNext: () -> Void

    @State private var completed = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Sort by \(sortBy)!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Coming soon!")
                .font(.title3)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                completed = true
                onCorrect()
                onNext()
            }) {
                Text("Continue →")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .buttonStyle(PrimaryButtonStyle(colors: [.green, .teal]))

            Spacer().frame(height: 40)
        }
        .padding()
    }
}

// MARK: - Preview
#Preview("Shape Card") {
    ShapeCardActivity(
        shape: "circle",
        emoji: "🔵",
        lessonState: LessonState(),
        onCorrect: {},
        onNext: {}
    )
}

#Preview("Shape Matching") {
    ShapeMatchingActivity(
        targetShape: "circle",
        emoji: "🔵",
        options: ["circle", "square", "triangle"],
        lessonState: LessonState(),
        onCorrect: {},
        onIncorrect: {},
        onNext: {}
    )
}

#Preview("Color Card") {
    ColorCardActivity(
        color: "red",
        emoji: "🍎",
        lessonState: LessonState(),
        onCorrect: {},
        onNext: {}
    )
}

#Preview("Color Matching") {
    ColorMatchingActivity(
        targetColor: "blue",
        emoji: "🫐",
        options: ["red", "blue", "yellow"],
        lessonState: LessonState(),
        onCorrect: {},
        onIncorrect: {},
        onNext: {}
    )
}
