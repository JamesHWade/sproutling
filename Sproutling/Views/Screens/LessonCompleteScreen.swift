//
//  LessonCompleteScreen.swift
//  Sproutling
//
//  Celebration screen shown after completing a lesson
//

import SwiftUI

struct LessonCompleteScreen: View {
    let subject: Subject
    let stars: Int

    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var showContent = false
    @State private var animateStars = false

    // Dynamic mascot reaction based on stars earned
    private var mascotReaction: MascotReaction {
        let context = MascotContext(
            correctStreak: 0,
            incorrectStreak: 0,
            activitiesCompletedToday: 0,
            totalSeeds: appState.childProfile.totalStars,
            streakDays: appState.childProfile.streakDays,
            isFirstActivityOfSession: false,
            isReturningUser: true,
            timeOfDay: .current,
            subject: subject,
            activityType: nil
        )
        return MascotPersonality.shared.lessonComplete(stars: stars, context: context)
    }

    var message: String {
        switch stars {
        case 1: return "You kept trying! Practice makes progress!"
        case 2: return "You worked hard on that!"
        default: return "You finished the whole lesson!"
        }
    }

    var body: some View {
        ZStack {
            // Background (plant-themed celebration)
            LinearGradient(
                colors: [Color.green.opacity(0.25), Color.mint.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Confetti
            ConfettiView()
                .ignoresSafeArea()

            // Content
            VStack(spacing: 24) {
                Spacer()

                // Celebration icon
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.pink.opacity(0.5), .purple.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)
                        .blur(radius: 10)
                        .scaleEffect(showContent ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showContent)

                    // Main celebration icon
                    Image(systemName: "hands.clap.fill")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.bounce, options: .speed(0.5), value: showContent)
                }
                .scaleEffect(reduceMotion || showContent ? 1 : 0)
                .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: showContent)
                .accessibilityHidden(true)

                // Title
                Text("Lesson Complete!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                    .scaleEffect(reduceMotion || showContent ? 1 : 0)
                    .animation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.6).delay(0.4), value: showContent)
                    .accessibilityAddTraits(.isHeader)

                // Seeds with SF Symbols (plant-themed rewards)
                HStack(spacing: 16) {
                    ForEach(1...3, id: \.self) { seed in
                        ZStack {
                            // Glow for earned seeds
                            if seed <= stars {
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [.green.opacity(0.6), .mint.opacity(0.3), .clear],
                                            center: .center,
                                            startRadius: 0,
                                            endRadius: 35
                                        )
                                    )
                                    .frame(width: 70, height: 70)
                                    .blur(radius: 6)
                            }

                            Image(systemName: seed <= stars ? "leaf.fill" : "leaf")
                                .font(.system(size: 50, weight: .bold))
                                .foregroundStyle(
                                    seed <= stars
                                    ? LinearGradient(colors: [.green, .mint], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                                )
                        }
                        .scaleEffect(!reduceMotion && animateStars && seed <= stars ? 1.2 : 1.0)
                        .animation(
                            reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.5)
                                .delay(0.6 + Double(seed) * 0.2),
                            value: animateStars
                        )
                        .accessibilityHidden(true)
                    }
                }
                .padding(.vertical)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("You earned \(stars) out of 3 seeds")

                // Message
                Text(message)
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(reduceMotion || showContent ? 1 : 0)
                    .offset(y: reduceMotion || showContent ? 0 : 20)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.5).delay(1.2), value: showContent)

                // Mascot with dynamic reaction
                MascotView(emotion: mascotReaction.emotion, message: mascotReaction.message, size: 50)
                    .opacity(reduceMotion || showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.5).delay(1.4), value: showContent)

                Spacer()

                // Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        appState.startLesson(subject: subject, level: 1)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .font(.title2)
                                .accessibilityHidden(true)
                            Text("Play Again")
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                    }
                    .buttonStyle(PrimaryButtonStyle(colors: [.purple, .pink]))
                    .accessibilityLabel("Play again")
                    .accessibilityHint("Double tap to replay this lesson")

                    Button(action: {
                        appState.goHome()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "house.fill")
                                .font(.title2)
                                .accessibilityHidden(true)
                            Text("Home")
                        }
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.purple.opacity(0.3), lineWidth: 3)
                        )
                    }
                    .accessibilityLabel("Go home")
                    .accessibilityHint("Double tap to return to the home screen")
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                .animation(.easeOut(duration: 0.5).delay(1.6), value: showContent)

                Spacer().frame(height: 40)
            }
            .padding()
        }
        .onAppear {
            // Play celebration sound
            SoundManager.shared.playSound(.celebration)
            HapticFeedback.success()

            // Trigger animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showContent = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                animateStars = true
            }
        }
    }
}

#Preview {
    LessonCompleteScreen(subject: .math, stars: 3)
        .environmentObject(AppState())
}
