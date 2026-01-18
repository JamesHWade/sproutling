//
//  SubjectScreen.swift
//  Sproutling
//
//  Subject selection and level picker screen
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
                    title: subject.title,
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

            ForEach(appState.levels(for: subject)) { level in
                LevelCard(level: level, subject: subject) {
                    appState.startLesson(subject: subject, level: level.id)
                }
            }
        }
    }
}

#Preview {
    SubjectScreen(subject: .math)
        .environmentObject(AppState())
}
