//
//  HomeScreen.swift
//  Sproutling
//
//  Main home screen with subject selection
//

import SwiftUI

struct HomeScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var showProfileSwitcher = false
    @State private var mascotReaction: MascotReaction?

    // Cached garden data to prevent multiple DB fetches per render
    @State private var cachedMathItems: [GardenItem] = []
    @State private var cachedReadingItems: [GardenItem] = []
    @State private var cachedPlantsNeedingWater: Int = 0

    // Generate context for mascot personality
    private var mascotContext: MascotContext {
        MascotContext(
            correctStreak: 0,
            incorrectStreak: 0,
            activitiesCompletedToday: 0,
            totalSeeds: appState.childProfile.totalStars,
            streakDays: appState.childProfile.streakDays,
            isFirstActivityOfSession: true,
            isReturningUser: appState.childProfile.totalStars > 0,
            timeOfDay: .current,
            subject: nil,
            activityType: nil
        )
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.cyan.opacity(0.3), Color.indigo.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Garden snapshot widget
                    gardenSnapshotWidget

                    // Streak indicator
                    streakCard

                    // Mascot greeting (dynamic based on context)
                    dynamicMascotGreeting
                        .padding(.vertical, 8)

                    // Subject cards
                    subjectCards

                    // Quick practice
                    quickPracticeSection

                    // Bottom padding for tab bar
                    Spacer().frame(height: 80)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            // Tab bar
            VStack {
                Spacer()
                tabBar
            }
        }
        .onAppear {
            // Set mascot greeting once on appear to avoid flickering
            if mascotReaction == nil {
                mascotReaction = MascotPersonality.shared.homeGreeting(context: mascotContext)
            }
            // Load garden data once on appear
            refreshGardenCache()
        }
        .onChange(of: appState.currentProfile?.id) { _, _ in
            // Refresh cache when profile changes
            refreshGardenCache()
        }
    }

    /// Refreshes the cached garden data from the database
    private func refreshGardenCache() {
        cachedMathItems = appState.getGardenItems(for: .math)
        cachedReadingItems = appState.getGardenItems(for: .reading)
        cachedPlantsNeedingWater = cachedMathItems.filter { $0.stage == .wilting }.count +
                                   cachedReadingItems.filter { $0.stage == .wilting }.count
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            // Profile avatar (tappable to switch profiles)
            if appState.profiles.count > 1 {
                Button(action: {
                    showProfileSwitcher = true
                }) {
                    ProfileAvatarView(
                        avatarIndex: appState.childProfile.avatarIndex,
                        backgroundIndex: appState.childProfile.backgroundIndex,
                        size: 50
                    )
                }
                .accessibilityLabel("Switch profile. Currently: \(appState.childProfile.name)")
                .accessibilityHint("Double tap to switch to a different profile")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.title3)
                    .foregroundColor(.secondary)

                Text(appState.childProfile.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(greetingText) \(appState.childProfile.name)")

            Spacer()

            // Total seeds badge - tappable to view progress
            Button(action: {
                appState.goToProgress()
            }) {
                VStack(spacing: 4) {
                    Text("Seeds")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 6) {
                        Image(systemName: "leaf.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .accessibilityHidden(true)
                        Text("\(appState.childProfile.totalStars)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                )
                .adaptiveShadow()
            }
            .accessibilityLabel("Seeds: \(appState.childProfile.totalStars). Double tap to view progress")
        }
        .sheet(isPresented: $showProfileSwitcher) {
            ProfileSwitcherSheet()
        }
    }

    // MARK: - Greeting based on time
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning!"
        case 12..<17: return "Good afternoon!"
        default: return "Good evening!"
        }
    }

    // MARK: - Dynamic Mascot Greeting
    private var dynamicMascotGreeting: some View {
        // Use stored reaction to avoid flickering (set in onAppear)
        let reaction = mascotReaction ?? MascotReaction(.happy, "Let's learn something fun!")
        return MascotView(emotion: reaction.emotion, message: reaction.message)
    }

    // MARK: - Garden Snapshot Widget
    private var gardenSnapshotWidget: some View {
        // Use cached data to avoid multiple DB fetches per render
        let allItems = cachedMathItems + cachedReadingItems
        let plantsNeedingWater = cachedPlantsNeedingWater

        return VStack(spacing: 12) {
            HStack {
                Text("🌻 Your Garden Today")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button(action: {
                    appState.goToProgress()
                }) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if allItems.isEmpty {
                // Empty state - encourage first lesson
                VStack(spacing: 8) {
                    Text("🌱")
                        .font(.system(size: 40))
                    Text("Start learning to grow your garden!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                // Garden summary with plant emojis
                HStack(spacing: 4) {
                    ForEach(allItems.prefix(12)) { item in
                        Text(item.stage.emoji)
                            .font(.system(size: 20))
                    }
                    if allItems.count > 12 {
                        Text("...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Summary text
                GardenSummaryView(items: allItems)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Plants needing water alert
                if plantsNeedingWater > 0 {
                    Button(action: {
                        // Navigate to progress to see which plants need water
                        appState.goToProgress()
                    }) {
                        HStack(spacing: 8) {
                            Text("🥀")
                                .font(.subheadline)
                            Text("\(plantsNeedingWater) plant\(plantsNeedingWater == 1 ? "" : "s") need\(plantsNeedingWater == 1 ? "s" : "") water!")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            Spacer()
                            Text("Water Now")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.orange))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
        .adaptiveShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your garden today. \(allItems.count) plants total. \(plantsNeedingWater) plants need water.")
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        HStack(spacing: 16) {
            // Animated flame icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.3), .red.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "flame.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(appState.childProfile.streakDays) Day Streak!")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("Keep learning every day!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground.opacity(0.9))
        )
        .adaptiveShadow()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Learning streak: \(appState.childProfile.streakDays) days in a row! Keep learning every day!")
    }

    // MARK: - Subject Cards
    private var subjectCards: some View {
        VStack(spacing: 16) {
            ForEach(Subject.allCases) { subject in
                SubjectCard(subject: subject) {
                    appState.selectSubject(subject)
                }
            }
        }
    }

    // MARK: - Quick Practice Section
    private var quickPracticeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Practice")
                .font(.headline)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    QuickPracticeButton(
                        title: "Count to 5",
                        icon: "number.circle.fill",
                        colors: [.blue, .purple]
                    ) {
                        appState.startLesson(subject: .math, level: 1)
                    }

                    QuickPracticeButton(
                        title: "Letter A",
                        icon: "textformat.abc",
                        colors: [.pink, .orange]
                    ) {
                        appState.startLesson(subject: .reading, level: 1)
                    }

                    QuickPracticeButton(
                        title: "Count Higher",
                        icon: "plus.circle.fill",
                        colors: [.green, .teal]
                    ) {
                        appState.startLesson(subject: .math, level: 2)
                    }
                }
            }
        }
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            tabBarButton(icon: "house.fill", label: "Home", isSelected: true) {
                // Already on home
            }
            tabBarButton(icon: "chart.bar.fill", label: "Progress", isSelected: false) {
                appState.goToProgress()
            }
            tabBarButton(icon: "gamecontroller.fill", label: "Games", isSelected: false) {
                // Games coming soon
            }
            tabBarButton(icon: "gearshape.fill", label: "Settings", isSelected: false) {
                appState.goToSettings()
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Divider()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Navigation tabs")
    }

    private func tabBarButton(icon: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .fontWeight(isSelected ? .semibold : .regular)
                Text(label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .medium : .regular)
            }
            .foregroundColor(isSelected ? .purple : .gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label) tab")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to \(label)")
    }
}

#Preview {
    HomeScreen()
        .environmentObject(AppState())
}
