//
//  ProgressScreen.swift
//  Sproutling
//
//  Progress tracking and statistics screen
//

import SwiftUI

struct ProgressScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.green.opacity(0.2), Color.teal.opacity(0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                SproutlingNavBar(
                    title: "My Progress",
                    onBack: { appState.goHome() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Overview card
                        overviewCard

                        // Subject progress
                        subjectProgressSection

                        // Achievements
                        achievementsSection

                        // Areas to practice
                        areasToImproveSection

                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
        }
    }

    // MARK: - Overview Card
    private var overviewCard: some View {
        VStack(spacing: 16) {
            Text("Great Progress!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 24) {
                // Total seeds
                VStack(spacing: 4) {
                    Text("\(appState.childProfile.totalStars)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("Seeds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(appState.childProfile.totalStars) total seeds")

                Divider()
                    .frame(height: 50)

                // Streak
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Text("\(appState.childProfile.streakDays)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .accessibilityHidden(true)
                    }
                    Text("Day Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(appState.childProfile.streakDays) day streak")

                Divider()
                    .frame(height: 50)

                // Levels completed
                VStack(spacing: 4) {
                    Text("\(completedLevelsCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("Levels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(completedLevelsCount) levels completed")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 12, y: 6)
        )
    }

    private var completedLevelsCount: Int {
        let mathCompleted = appState.childProfile.mathProgress.filter { $0.value > 0 }.count
        let readingCompleted = appState.childProfile.readingProgress.filter { $0.value > 0 }.count
        return mathCompleted + readingCompleted
    }

    // MARK: - Subject Progress Section
    private var subjectProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subject Progress")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            ForEach(Subject.allCases) { subject in
                SubjectProgressCard(
                    subject: subject,
                    levels: appState.levels(for: subject)
                )
            }
        }
    }

    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AchievementBadge(
                    iconName: "leaf.circle.fill",
                    iconColors: [.green, .mint],
                    title: "First Seed",
                    description: "Earn your first seed",
                    isEarned: appState.childProfile.totalStars >= 1
                )

                AchievementBadge(
                    iconName: "flame.fill",
                    iconColors: [.orange, .red],
                    title: "On Fire",
                    description: "3 day streak",
                    isEarned: appState.childProfile.streakDays >= 3
                )

                AchievementBadge(
                    iconName: "trophy.fill",
                    iconColors: [.green, .teal],
                    title: "Seed Collector",
                    description: "Earn 10 seeds",
                    isEarned: appState.childProfile.totalStars >= 10
                )

                AchievementBadge(
                    iconName: "number.circle.fill",
                    iconColors: [.blue, .purple],
                    title: "Number Pro",
                    description: "Complete all math levels",
                    isEarned: appState.childProfile.mathProgress.filter { $0.value > 0 }.count >= 3
                )

                AchievementBadge(
                    iconName: "book.fill",
                    iconColors: [.pink, .orange],
                    title: "Word Wizard",
                    description: "Complete all reading levels",
                    isEarned: appState.childProfile.readingProgress.filter { $0.value > 0 }.count >= 3
                )

                AchievementBadge(
                    iconName: "leaf.fill",
                    iconColors: [.green, .mint],
                    title: "Full Bloom!",
                    description: "Get 3 seeds on any level",
                    isEarned: hasThreeStarsOnAnyLevel
                )
            }
        }
    }

    private var hasThreeStarsOnAnyLevel: Bool {
        appState.childProfile.mathProgress.values.contains(3) ||
        appState.childProfile.readingProgress.values.contains(3)
    }

    // MARK: - Areas to Improve Section
    private var areasToImproveSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Areas to Practice")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            let recommendations = getRecommendations()

            if recommendations.isEmpty {
                Text("Keep up the great work! Complete more lessons to see recommendations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.8))
                    )
            } else {
                ForEach(recommendations, id: \.self) { recommendation in
                    RecommendationCard(text: recommendation)
                }
            }
        }
    }

    private func getRecommendations() -> [String] {
        var recommendations: [String] = []

        // Check math progress
        let mathLevels = appState.levels(for: .math)
        for level in mathLevels where level.isUnlocked && level.starsEarned < 3 && level.starsEarned > 0 {
            recommendations.append("Practice '\(level.title)' to earn more seeds!")
        }

        // Check reading progress
        let readingLevels = appState.levels(for: .reading)
        for level in readingLevels where level.isUnlocked && level.starsEarned < 3 && level.starsEarned > 0 {
            recommendations.append("Practice '\(level.title)' to earn more seeds!")
        }

        // Check for locked levels
        if mathLevels.filter({ !$0.isUnlocked }).count > 0 {
            recommendations.append("Complete Numbers lessons to unlock more!")
        }

        if readingLevels.filter({ !$0.isUnlocked }).count > 0 {
            recommendations.append("Complete Letters lessons to unlock more!")
        }

        return Array(recommendations.prefix(3))
    }
}

// MARK: - Subject Progress Card
struct SubjectProgressCard: View {
    let subject: Subject
    let levels: [LessonLevel]

    private var totalStars: Int {
        levels.reduce(0) { $0 + $1.starsEarned }
    }

    private var maxStars: Int {
        levels.count * 3
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                // SF Symbol icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: subject.lightGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Image(systemName: subject.iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: subject.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(subject.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("\(totalStars) of \(maxStars) seeds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Seed progress indicators
                HStack(spacing: 4) {
                    ForEach(0..<levels.count, id: \.self) { index in
                        Image(systemName: levels[index].starsEarned > 0 ? "leaf.fill" : "leaf")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(
                                levels[index].starsEarned > 0
                                ? LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                            )
                            .accessibilityHidden(true)
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: subject.gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: maxStars > 0 ? geometry.size.width * CGFloat(totalStars) / CGFloat(maxStars) : 0)
                        .animation(.easeOut(duration: 0.5), value: totalStars)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(subject.rawValue): \(totalStars) of \(maxStars) seeds earned")
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let iconName: String
    let iconColors: [Color]
    let title: String
    let description: String
    let isEarned: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Glow for earned badges
                if isEarned {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: iconColors + [iconColors.last?.opacity(0.1) ?? .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 24
                            )
                        )
                        .frame(width: 48, height: 48)
                        .blur(radius: 6)
                }

                Image(systemName: iconName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        isEarned
                        ? LinearGradient(colors: iconColors, startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [.gray.opacity(0.4), .gray.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                    )
            }
            .accessibilityHidden(true)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isEarned ? .primary : .gray)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEarned ? iconColors.first?.opacity(0.15) ?? Color.yellow.opacity(0.15) : Color.gray.opacity(0.1))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) achievement: \(description). \(isEarned ? "Earned" : "Not yet earned")")
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(.yellow)
                .accessibilityHidden(true)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.1))
        )
        .accessibilityLabel("Tip: \(text)")
    }
}

#Preview {
    ProgressScreen()
        .environmentObject(AppState())
}
