//
//  TimeForBreakScreen.swift
//  Sproutling
//
//  Friendly screen shown when daily time limit is reached
//

import SwiftUI

struct TimeForBreakScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var showParentPIN = false
    @State private var bounceAmount: CGFloat = 0
    @State private var cloudOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Calming gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.6, green: 0.8, blue: 1.0),
                    Color(red: 0.8, green: 0.9, blue: 1.0),
                    Color(red: 1.0, green: 0.95, blue: 0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Floating clouds
            FloatingClouds(offset: cloudOffset)

            VStack(spacing: 32) {
                Spacer()

                // Sleepy mascot
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow.opacity(0.3), .orange.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 180, height: 180)

                    Text("😴")
                        .font(.system(size: 100))
                        .offset(y: bounceAmount)
                }

                // Message
                VStack(spacing: 16) {
                    Text("Time for a Break!")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.indigo, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("You've been learning so well today!")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    Text("Let's rest our eyes and play outside! 🌳")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                // Suggestions
                VStack(spacing: 12) {
                    SuggestionBubble(emoji: "🎨", text: "Draw a picture")
                    SuggestionBubble(emoji: "🏃", text: "Run and play")
                    SuggestionBubble(emoji: "📚", text: "Read a book with family")
                }
                .padding(.horizontal, 40)

                Spacer()

                // Parent override button (subtle)
                Button {
                    showParentPIN = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14))
                        Text("Parent Options")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.secondary.opacity(0.7))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.5))
                    )
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showParentPIN) {
            ParentBreakOverrideSheet()
        }
        .onAppear {
            // Gentle breathing animation for mascot
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                bounceAmount = 8
            }

            // Slow cloud drift
            withAnimation(
                .linear(duration: 20)
                .repeatForever(autoreverses: false)
            ) {
                cloudOffset = 100
            }
        }
    }
}

// MARK: - Supporting Views

struct FloatingClouds: View {
    let offset: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Cloud 1
                CloudShape()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 120, height: 60)
                    .offset(x: offset - 50, y: geometry.size.height * 0.1)

                // Cloud 2
                CloudShape()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 100, height: 50)
                    .offset(x: geometry.size.width - offset, y: geometry.size.height * 0.2)

                // Cloud 3
                CloudShape()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 80, height: 40)
                    .offset(x: offset * 0.5, y: geometry.size.height * 0.15)
            }
        }
    }
}

struct CloudShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Simple cloud shape using circles
        let width = rect.width
        let height = rect.height

        path.addEllipse(in: CGRect(x: 0, y: height * 0.3, width: width * 0.4, height: height * 0.7))
        path.addEllipse(in: CGRect(x: width * 0.2, y: 0, width: width * 0.5, height: height))
        path.addEllipse(in: CGRect(x: width * 0.5, y: height * 0.2, width: width * 0.5, height: height * 0.8))

        return path
    }
}

struct SuggestionBubble: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 24))

            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary.opacity(0.8))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Parent Override Sheet

struct ParentBreakOverrideSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var enteredPIN = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                    .padding(.top, 40)

                Text("Parent Override")
                    .font(.system(size: 24, weight: .bold, design: .rounded))

                Text("Enter your PIN to extend today's screen time or go to settings.")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                if appState.hasPIN {
                    // PIN entry
                    SecureField("Enter PIN", text: $enteredPIN)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(maxWidth: 200)
                        .padding(.top, 16)

                    if showError {
                        Text("Incorrect PIN")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.red)
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            if appState.verifyPIN(enteredPIN) {
                                // Add 15 more minutes
                                appState.resetDailyUsage()
                                dismiss()
                                appState.goHome()
                            } else {
                                showError = true
                                enteredPIN = ""
                            }
                        } label: {
                            Label("Add 15 More Minutes", systemImage: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button {
                            if appState.verifyPIN(enteredPIN) {
                                dismiss()
                                appState.goToSettings()
                            } else {
                                showError = true
                                enteredPIN = ""
                            }
                        } label: {
                            Label("Go to Settings", systemImage: "gear")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.secondary.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                } else {
                    // No PIN set - allow direct access
                    Text("No PIN is set. Set one in Settings for added security.")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    VStack(spacing: 12) {
                        Button {
                            appState.resetDailyUsage()
                            dismiss()
                            appState.goHome()
                        } label: {
                            Label("Add 15 More Minutes", systemImage: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        Button {
                            dismiss()
                            appState.goToSettings()
                        } label: {
                            Label("Go to Settings", systemImage: "gear")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.secondary.opacity(0.1))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TimeForBreakScreen()
        .environmentObject(AppState())
}
