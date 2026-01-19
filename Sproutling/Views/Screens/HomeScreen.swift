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
                VStack(spacing: 20) {
                    // Header with greeting
                    headerSection

                    // Mascot with call-to-action - the hero moment
                    mascotHeroSection

                    // Subject cards - PRIMARY ACTION, visible without scrolling
                    subjectCards

                    // Garden snapshot - secondary, compact
                    gardenCompactWidget

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

    // MARK: - Mascot Hero Section
    /// Compact mascot with streak badge - motivates kids to start learning
    private var mascotHeroSection: some View {
        let reaction = mascotReaction ?? MascotReaction(.happy, "Let's learn something fun!")

        return HStack(spacing: 12) {
            // Mascot image (no message bubble here)
            Image("SproutlingMascot")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                // Greeting message
                Text(reaction.message)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Streak badge inline
                if appState.childProfile.streakDays > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("\(appState.childProfile.streakDays) day streak!")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBackground)
        )
        .adaptiveShadow()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reaction.message). \(appState.childProfile.streakDays) day learning streak.")
    }

    // MARK: - Garden Compact Widget
    /// Compact garden preview - tappable to see full garden
    private var gardenCompactWidget: some View {
        let allItems = cachedMathItems + cachedReadingItems
        let plantsNeedingWater = cachedPlantsNeedingWater

        return Button(action: {
            appState.goToProgress()
        }) {
            HStack(spacing: 12) {
                // Garden icon or plant preview
                if allItems.isEmpty {
                    Text("🌱")
                        .font(.system(size: 32))
                } else {
                    // Show first few plants
                    HStack(spacing: 2) {
                        ForEach(allItems.prefix(5)) { item in
                            Text(item.stage.emoji)
                                .font(.system(size: 20))
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Your Garden")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.textPrimary)

                    if allItems.isEmpty {
                        Text("Start learning to plant seeds!")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    } else if plantsNeedingWater > 0 {
                        HStack(spacing: 4) {
                            Text("🥀")
                                .font(.caption)
                            Text("\(plantsNeedingWater) need water")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else {
                        Text("\(allItems.count) plants growing")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cardBackground)
            )
            .adaptiveShadow()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Your garden. \(allItems.count) plants. \(plantsNeedingWater) need water. Double tap to view.")
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
