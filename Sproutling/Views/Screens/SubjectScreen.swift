//
//  SubjectScreen.swift
//  Sproutling
//
//  Subject selection and level picker screen with garden theme
//

import SwiftUI

struct SubjectScreen: View {
    let subject: Subject
    @EnvironmentObject var appState: AppState

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
                // Navigation bar
                SproutlingNavBar(
                    title: "\(subject == .math ? "Number" : "Letter") Garden",
                    onBack: { appState.goHome() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero card
                        heroCard

                        // Levels section
                        levelsSection
                    }
                    .padding(20)
                }
            }
        }
    }

    // MARK: - Hero Card
    private var heroCard: some View {
        VStack(spacing: 16) {
            Image(systemName: subject.iconName)
                .font(.system(size: 60, weight: .bold))
                .foregroundColor(.white)
                .accessibilityHidden(true)

            Text(subject.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("Master the basics step by step!")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: subject.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: subject.gradient.first?.opacity(0.4) ?? .clear, radius: 16, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(subject.title). Master the basics step by step!")
    }

    // MARK: - Levels Section
    private var levelsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a Lesson")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            ForEach(Array(appState.levels(for: subject).enumerated()), id: \.element.id) { index, level in
                EnhancedLevelCard(
                    level: level,
                    subject: subject,
                    isNextToUnlock: isNextLevelToUnlock(index: index),
                    onPractice: {
                        appState.startLesson(subject: subject, level: level.id)
                    },
                    onReadyCheck: {
                        appState.navigateTo(.readyCheck(subject, level.id))
                    }
                )
            }
        }
    }

    /// Determines if this level is the next one that could be unlocked via Ready Check
    private func isNextLevelToUnlock(index: Int) -> Bool {
        let levels = appState.levels(for: subject)
        guard index < levels.count else { return false }

        let level = levels[index]
        // Current level must be unlocked and have at least 1 star
        if !level.isUnlocked || level.starsEarned == 0 { return false }

        // Next level must exist and be locked
        if index + 1 < levels.count {
            return !levels[index + 1].isUnlocked
        }

        return false
    }
}

// MARK: - Enhanced Level Card with Ready Check

struct EnhancedLevelCard: View {
    let level: LessonLevel
    let subject: Subject
    var isNextToUnlock: Bool = false
    let onPractice: () -> Void
    var onReadyCheck: (() -> Void)?

    @Environment(\.colorScheme) var colorScheme

    private var circleGradient: LinearGradient {
        if level.isUnlocked {
            return LinearGradient(colors: subject.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main card content
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
                        .foregroundColor(level.isUnlocked ? .textPrimary : .gray)

                    Text(level.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                Spacer()

                // Stars/Seeds
                if level.isUnlocked {
                    StarReward(count: level.starsEarned, size: 20)
                }
            }
            .padding(16)

            // Action buttons for unlocked levels with progress
            if level.isUnlocked && level.starsEarned > 0 {
                Divider()
                    .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    // Practice button
                    Button(action: onPractice) {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                                .font(.caption)
                            Text("Practice")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(subject.gradient.first)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(subject.gradient.first?.opacity(0.1) ?? .clear)
                        )
                    }
                    .buttonStyle(.plain)

                    // Ready Check button (only show if this level could unlock the next)
                    if isNextToUnlock, let onReadyCheck = onReadyCheck {
                        Button(action: onReadyCheck) {
                            HStack(spacing: 4) {
                                Text("Ready Check")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Image(systemName: "sparkles")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: subject.gradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            } else if level.isUnlocked {
                // Simple tap to start for levels without progress
                Button(action: onPractice) {
                    Text("Tap to Start")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(level.isUnlocked ? Color.cardBackground : Color.gray.opacity(0.1))
        )
        .adaptiveShadow()
        .opacity(level.isUnlocked ? 1 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(level.isUnlocked ? "Double tap to start this lesson" : "This level is locked")
    }

    private var accessibilityLabel: String {
        if level.isUnlocked {
            var label = "Level \(level.id): \(level.title). \(level.subtitle)"
            if level.starsEarned > 0 {
                label += ". \(level.starsEarned) of 3 seeds earned"
            }
            if isNextToUnlock {
                label += ". Ready check available to unlock next level"
            }
            return label
        } else {
            return "Level \(level.id): \(level.title). Locked. Complete previous levels to unlock"
        }
    }
}

#Preview {
    SubjectScreen(subject: .math)
        .environmentObject(AppState())
}
