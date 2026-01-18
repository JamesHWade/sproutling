//
//  Components.swift
//  Sproutling
//
//  Reusable UI components
//

import SwiftUI

// MARK: - Custom Navigation Bar
struct SproutlingNavBar: View {
    let title: String
    var onBack: (() -> Void)?
    var rightContent: AnyView?

    var body: some View {
        HStack {
            // Back button
            if let onBack = onBack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
                }
                .frame(width: 80, alignment: .leading)
                .accessibilityLabel("Go back")
                .accessibilityHint("Returns to the previous screen")
            } else {
                Spacer().frame(width: 80)
            }

            Spacer()

            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            // Right content
            if let rightContent = rightContent {
                rightContent
                    .frame(width: 80, alignment: .trailing)
            } else {
                Spacer().frame(width: 80)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let current: Int
    let total: Int
    var color: Color = .green

    private var progress: Double {
        total > 0 ? Double(current) / Double(total) : 0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))

                RoundedRectangle(cornerRadius: 6)
                    .fill(color)
                    .frame(width: geometry.size.width * progress)
                    .animation(.easeOut(duration: 0.5), value: current)
            }
        }
        .frame(height: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress: \(current) of \(total)")
        .accessibilityValue("\(Int(progress * 100)) percent complete")
    }
}

// MARK: - Star Reward Display
struct StarReward: View {
    let count: Int
    var animated: Bool = false
    var size: CGFloat = 30

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var animatedStars: Set<Int> = []

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...3, id: \.self) { star in
                Image(systemName: star <= count ? "star.fill" : "star")
                    .font(.system(size: size, weight: .bold))
                    .foregroundStyle(
                        star <= count
                        ? LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    )
                    .scaleEffect(animatedStars.contains(star) ? 1.3 : 1.0)
                    .symbolEffect(.bounce, options: .speed(0.5), value: animatedStars.contains(star))
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) of 3 stars earned")
        .onAppear {
            if animated && !reduceMotion {
                animateStars()
            }
        }
        .onChange(of: count) { _, newCount in
            if !reduceMotion && newCount > 0 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    _ = animatedStars.insert(newCount)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        _ = animatedStars.remove(newCount)
                    }
                }
            }
        }
    }

    private func animateStars() {
        for star in 1...count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(star) * 0.2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    _ = animatedStars.insert(star)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation {
                        _ = animatedStars.remove(star)
                    }
                }
            }
        }
    }
}

// MARK: - Mascot View
struct MascotView: View {
    let emotion: MascotEmotion
    var message: String?
    var size: CGFloat = 120

    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var emotionDescription: String {
        switch emotion {
        case .happy: return "Happy Sproutling mascot"
        case .excited: return "Excited Sproutling celebration"
        case .thinking: return "Thinking Sproutling mascot"
        case .proud: return "Proud Sproutling mascot"
        case .encouraging: return "Encouraging Sproutling mascot"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Sproutling mascot image
            Image("SproutlingMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .modifier(BounceModifier())
                .accessibilityHidden(true)

            // Speech bubble with message
            if let message = message {
                HStack(spacing: 0) {
                    Text(message)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 2
                        )
                )
            }
        }
        .onAppear {
            isAnimating = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message != nil ? "\(emotionDescription) says: \(message!)" : emotionDescription)
    }
}

// MARK: - Bounce Animation Modifier
struct BounceModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var bounce = false

    func body(content: Content) -> some View {
        content
            .offset(y: reduceMotion ? 0 : (bounce ? -5 : 0))
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                value: bounce
            )
            .onAppear {
                if !reduceMotion {
                    bounce = true
                }
            }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var confettiPieces: [ConfettiPiece] = []

    enum ConfettiShape: CaseIterable {
        case circle, rectangle, star
    }

    struct ConfettiPiece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var scale: CGFloat
        var opacity: Double
        let color: Color
        let shape: ConfettiShape
        let emoji: String?
        let delay: Double
        let swayAmount: CGFloat
    }

    private let celebrationEmojis = ["🎉", "⭐", "🌟", "✨", "💫"]
    private let colors: [Color] = [
        .red, .blue, .green, .yellow, .pink, .purple, .orange, .cyan, .mint
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if reduceMotion {
                    staticCelebration
                } else {
                    ForEach(confettiPieces) { piece in
                        confettiPieceView(piece)
                    }
                }
            }
            .onAppear {
                if !reduceMotion {
                    createConfetti(in: geometry.size)
                    animateConfetti(in: geometry.size)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Static Celebration (Reduced Motion)
    private var staticCelebration: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                ForEach(celebrationEmojis, id: \.self) { emoji in
                    Text(emoji)
                        .font(.system(size: 32))
                }
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Confetti Piece View
    @ViewBuilder
    private func confettiPieceView(_ piece: ConfettiPiece) -> some View {
        Group {
            if let emoji = piece.emoji {
                Text(emoji)
                    .font(.system(size: 24))
            } else {
                switch piece.shape {
                case .circle:
                    Circle()
                        .fill(piece.color)
                        .frame(width: 12, height: 12)
                case .rectangle:
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: 16, height: 8)
                case .star:
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(piece.color)
                }
            }
        }
        .scaleEffect(piece.scale)
        .opacity(piece.opacity)
        .rotationEffect(.degrees(piece.rotation))
        .rotation3DEffect(.degrees(piece.rotation * 0.5), axis: (x: 1, y: 0, z: 0))
        .position(x: piece.x, y: piece.y)
    }

    // MARK: - Create Confetti
    private func createConfetti(in size: CGSize) {
        let count = 45
        let centerX = size.width / 2
        let centerY = size.height * 0.35

        for i in 0..<count {
            // Start from center for burst effect
            let angle = Double.random(in: 0...2 * .pi)
            let burstRadius = CGFloat.random(in: 20...60)
            let startX = centerX + cos(angle) * burstRadius
            let startY = centerY + sin(angle) * burstRadius * 0.3

            // Determine if this is an emoji or shape
            let isEmoji = i < 8 // First 8 are emojis
            let emoji: String? = isEmoji ? celebrationEmojis.randomElement() : nil
            let shape = ConfettiShape.allCases.randomElement()!

            let piece = ConfettiPiece(
                x: startX,
                y: startY,
                rotation: Double.random(in: 0...360),
                scale: 0.1,
                opacity: 0,
                color: colors.randomElement()!,
                shape: shape,
                emoji: emoji,
                delay: Double(i) * 0.012,
                swayAmount: CGFloat.random(in: 20...50)
            )
            confettiPieces.append(piece)
        }
    }

    // MARK: - Animate Confetti
    private func animateConfetti(in size: CGSize) {
        // Phase 1: Burst outward and appear
        for i in confettiPieces.indices {
            let angle = Double.random(in: 0...2 * .pi)
            let burstDistance = CGFloat.random(in: 60...120)
            let upwardBias: CGFloat = -40

            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.65)
                .delay(confettiPieces[i].delay)
            ) {
                confettiPieces[i].x += cos(angle) * burstDistance
                confettiPieces[i].y += sin(angle) * burstDistance * 0.4 + upwardBias
                confettiPieces[i].scale = CGFloat.random(in: 0.8...1.3)
                confettiPieces[i].opacity = 1.0
                confettiPieces[i].rotation += Double.random(in: 180...360)
            }
        }

        // Phase 2: Fall with sway
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            for i in confettiPieces.indices {
                let fallDuration = Double.random(in: 2.2...3.5)
                let horizontalDrift = confettiPieces[i].swayAmount * (Bool.random() ? 1 : -1)

                withAnimation(
                    .easeIn(duration: fallDuration)
                    .delay(confettiPieces[i].delay * 0.5)
                ) {
                    confettiPieces[i].y = size.height + 80
                    confettiPieces[i].x += horizontalDrift
                    confettiPieces[i].rotation += Double.random(in: 540...1080)
                }

                // Fade out near the end
                withAnimation(
                    .easeIn(duration: 0.8)
                    .delay(fallDuration - 0.5 + confettiPieces[i].delay * 0.5)
                ) {
                    confettiPieces[i].opacity = 0
                }
            }
        }
    }
}

#Preview("Confetti") {
    ZStack {
        Color.white.ignoresSafeArea()
        ConfettiView()
    }
}

// MARK: - Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    let colors: [Color]
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: colors.first?.opacity(0.4) ?? .clear, radius: 8, y: 4)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1.0)
            .opacity(configuration.isPressed && reduceMotion ? 0.7 : 1.0)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Subject Card
struct SubjectCard: View {
    let subject: Subject
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            HStack(spacing: 16) {
                // SF Symbol icon with animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: subject.iconName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, options: .speed(0.5), value: isHovered)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(subject.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(subject.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    HStack {
                        Image(systemName: "play.fill")
                            .font(.caption2)
                        Text("Start Learning")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.3))
                    .clipShape(Capsule())
                    .padding(.top, 4)
                }

                Spacer()

                Image(systemName: "chevron.right.circle.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
                    .accessibilityHidden(true)
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: subject.gradient,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: subject.gradient.first?.opacity(0.4) ?? .clear, radius: 12, y: 6)
        }
        .buttonStyle(SubjectCardButtonStyle())
        .onAppear { isHovered = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(subject.rawValue): \(subject.subtitle)")
        .accessibilityHint("Double tap to start learning \(subject.rawValue.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Subject Card Button Style
struct SubjectCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Level Card
struct LevelCard: View {
    let level: LessonLevel
    let subject: Subject
    let action: () -> Void

    private var circleGradient: LinearGradient {
        if level.isUnlocked {
            return LinearGradient(colors: subject.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var accessibilityLabelText: String {
        if level.isUnlocked {
            var label = "Level \(level.id): \(level.title). \(level.subtitle)"
            if level.starsEarned > 0 {
                label += ". \(level.starsEarned) of 3 stars earned"
            }
            return label
        } else {
            return "Level \(level.id): \(level.title). Locked. Complete previous levels to unlock"
        }
    }

    var body: some View {
        Button(action: {
            if level.isUnlocked {
                action()
            }
        }) {
            HStack(spacing: 16) {
                // Level number or lock
                ZStack {
                    Circle()
                        .fill(circleGradient)
                        .frame(width: 56, height: 56)

                    if level.isUnlocked {
                        Text("\(level.id)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }

                // Level info
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.headline)
                        .foregroundColor(level.isUnlocked ? .primary : .gray)

                    Text(level.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Stars
                if level.isUnlocked {
                    StarReward(count: level.starsEarned, size: 20)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(level.isUnlocked ? Color.white : Color.gray.opacity(0.1))
                    .shadow(color: .black.opacity(level.isUnlocked ? 0.1 : 0), radius: 8, y: 4)
            )
        }
        .buttonStyle(.plain)
        .opacity(level.isUnlocked ? 1 : 0.6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(level.isUnlocked ? "Double tap to start this lesson" : "This level is locked")
        .accessibilityAddTraits(level.isUnlocked ? .isButton : [])
    }
}

// MARK: - Tap Circle (for counting)
struct TapCircle: View {
    let count: Int
    let target: Int
    let onTap: () -> Void

    @State private var ripples: [UUID] = []

    var isComplete: Bool { count >= target }

    private var circleGradient: LinearGradient {
        if isComplete {
            return LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        ZStack {
            // Ripple effects
            ForEach(ripples, id: \.self) { id in
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 3)
                    .frame(width: 250, height: 250)
                    .scaleEffect(1.5)
                    .opacity(0)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            ripples.removeAll { $0 == id }
                        }
                    }
            }

            // Main circle
            Circle()
                .fill(circleGradient)
                .frame(width: 200, height: 200)
                .shadow(color: .purple.opacity(0.4), radius: 20, y: 10)

            // Count display
            Text("\(count)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .scaleEffect(isComplete ? 1.05 : 1.0)
        .animation(.spring(), value: isComplete)
        .onTapGesture {
            if !isComplete {
                // Add haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()

                // Add ripple
                ripples.append(UUID())

                onTap()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isComplete ? "Counting complete! You counted to \(target)" : "Count: \(count). Tap to count to \(target)")
        .accessibilityHint(isComplete ? "Well done!" : "Double tap to add one")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            if !isComplete {
                onTap()
            }
        }
    }
}

// MARK: - Number Option Button
struct NumberOptionButton: View {
    let number: Int
    let isSelected: Bool
    let isCorrect: Bool?
    let isDisabled: Bool
    let action: () -> Void

    @State private var shakeCount: CGFloat = 0

    var backgroundColor: Color {
        guard let isCorrect = isCorrect else {
            return .white
        }
        return isCorrect ? .green : .red.opacity(0.8)
    }

    var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : .red
        }
        return isSelected ? .purple : .purple.opacity(0.3)
    }

    private var accessibilityLabelText: String {
        if let isCorrect = isCorrect {
            return isCorrect ? "Number \(number), correct!" : "Number \(number), incorrect"
        }
        return "Number \(number)"
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow effect for correct answer
                if isCorrect == true {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.green.opacity(0.3))
                        .frame(width: 88, height: 88)
                        .blur(radius: 8)
                }

                Text("\(number)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(isCorrect != nil ? .white : .purple)
                    .frame(width: 80, height: 80)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 4)
                    )
                    .shadow(color: isCorrect == true ? .green.opacity(0.5) : .black.opacity(0.1), radius: 8, y: 4)
            }
        }
        .scaleEffect(isCorrect == true ? 1.1 : 1.0)
        .offset(x: sin(shakeCount * .pi * 3) * 10)
        .disabled(isDisabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCorrect)
        .animation(.default, value: shakeCount)
        .onChange(of: isCorrect) { _, newValue in
            if newValue == false {
                shakeCount = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    shakeCount = 0
                }
            }
        }
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(isDisabled ? "" : "Double tap to select this number")
    }
}

// MARK: - Letter Option Button
struct LetterOptionButton: View {
    let letter: String
    let isSelected: Bool
    let isCorrect: Bool?
    let isDisabled: Bool
    let action: () -> Void

    @State private var shakeCount: CGFloat = 0

    var backgroundColor: Color {
        guard let isCorrect = isCorrect else {
            return .white
        }
        return isCorrect ? .green : .red.opacity(0.8)
    }

    var borderColor: Color {
        if let isCorrect = isCorrect {
            return isCorrect ? .green : .red
        }
        return isSelected ? .pink : .pink.opacity(0.3)
    }

    private var accessibilityLabelText: String {
        if let isCorrect = isCorrect {
            return isCorrect ? "Letter \(letter), correct!" : "Letter \(letter), incorrect"
        }
        return "Letter \(letter)"
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                // Glow effect for correct answer
                if isCorrect == true {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.green.opacity(0.3))
                        .frame(width: 88, height: 88)
                        .blur(radius: 8)
                }

                Text(letter)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(isCorrect != nil ? .white : .pink)
                    .frame(width: 80, height: 80)
                    .background(backgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 4)
                    )
                    .shadow(color: isCorrect == true ? .green.opacity(0.5) : .black.opacity(0.1), radius: 8, y: 4)
            }
        }
        .scaleEffect(isCorrect == true ? 1.1 : 1.0)
        .offset(x: sin(shakeCount * .pi * 3) * 10)
        .disabled(isDisabled)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCorrect)
        .animation(.default, value: shakeCount)
        .onChange(of: isCorrect) { _, newValue in
            if newValue == false {
                shakeCount = 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    shakeCount = 0
                }
            }
        }
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(isDisabled ? "" : "Double tap to select this letter")
    }
}

// MARK: - Large Letter Card
struct LargeLetterCard: View {
    let letter: String

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Glow background
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [.pink.opacity(0.4), .purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 200, height: 200)
                .blur(radius: 15)
                .scaleEffect(isAnimating ? 1.1 : 1.0)

            // Main card
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [.pink, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 180, height: 180)
                .shadow(color: .purple.opacity(0.4), radius: 16, y: 8)

            // Letter with subtle pulse
            Text(letter)
                .font(.system(size: 120, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 4, y: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Letter \(letter)")
    }
}

// MARK: - Phonics Letter Button
struct PhonicsLetterButton: View {
    let letter: String
    let isRevealed: Bool
    let isNext: Bool
    let action: () -> Void

    private var accessibilityLabelText: String {
        if isRevealed {
            return "Letter \(letter), revealed"
        } else if isNext {
            return "Letter \(letter), tap to hear sound"
        } else {
            return "Letter \(letter), not yet available"
        }
    }

    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 80, height: 96)
                .background(
                    LinearGradient(
                        colors: isRevealed ? [.green, .teal] : (isNext ? [.pink, .purple] : [.gray.opacity(0.3), .gray.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: isRevealed ? .green.opacity(0.4) : .purple.opacity(0.3), radius: 8, y: 4)
                .scaleEffect(isRevealed ? 1.05 : 1.0)
        }
        .disabled(!isNext)
        .opacity(isRevealed || isNext ? 1 : 0.5)
        .animation(.spring(), value: isRevealed)
        .accessibilityLabel(accessibilityLabelText)
        .accessibilityHint(isNext ? "Double tap to hear the sound of this letter" : "")
    }
}

// MARK: - Quick Practice Button
struct QuickPracticeButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: colors.first?.opacity(0.4) ?? .clear, radius: 6, y: 3)
        }
        .buttonStyle(QuickPracticeButtonStyle())
        .accessibilityLabel("Quick practice: \(title)")
        .accessibilityHint("Double tap to start practicing")
    }
}

// MARK: - Quick Practice Button Style
struct QuickPracticeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Color Extension for Amber
extension Color {
    static let amber = Color(red: 1.0, green: 0.75, blue: 0.0)
}

// MARK: - Shake Animation Modifier
struct ShakeModifier: ViewModifier {
    var shakeCount: CGFloat

    func body(content: Content) -> some View {
        content
            .offset(x: sin(shakeCount * .pi * 3) * 10)
    }
}

extension View {
    func shake(trigger: Bool) -> some View {
        modifier(ShakeModifier(shakeCount: trigger ? 1 : 0))
    }
}

// MARK: - Pulse Animation Modifier
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let duration: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

extension View {
    func pulse(duration: Double = 1.0) -> some View {
        modifier(PulseModifier(duration: duration))
    }
}

// MARK: - Slide In Animation Modifier
struct SlideInModifier: ViewModifier {
    @State private var appeared = false
    let from: Edge
    let delay: Double

    func body(content: Content) -> some View {
        content
            .offset(
                x: appeared ? 0 : (from == .leading ? -100 : (from == .trailing ? 100 : 0)),
                y: appeared ? 0 : (from == .top ? -50 : (from == .bottom ? 50 : 0))
            )
            .opacity(appeared ? 1 : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(delay),
                value: appeared
            )
            .onAppear {
                appeared = true
            }
    }
}

extension View {
    func slideIn(from edge: Edge = .bottom, delay: Double = 0) -> some View {
        modifier(SlideInModifier(from: edge, delay: delay))
    }
}

// MARK: - Pop In Animation Modifier
struct PopInModifier: ViewModifier {
    @State private var appeared = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.5)
            .opacity(appeared ? 1 : 0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.6)
                .delay(delay),
                value: appeared
            )
            .onAppear {
                appeared = true
            }
    }
}

extension View {
    func popIn(delay: Double = 0) -> some View {
        modifier(PopInModifier(delay: delay))
    }
}
