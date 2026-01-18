//
//  ProfileSelectionScreen.swift
//  Sproutling
//
//  Screen for selecting which child profile to use
//

import SwiftUI

struct ProfileSelectionScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var showAddProfile = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.cyan.opacity(0.2), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                headerSection

                // Profile grid
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Mascot greeting
                        MascotView(
                            emotion: .happy,
                            message: "Who's learning today?"
                        )
                        .padding(.vertical, 8)

                        // Profile cards grid
                        profileGrid

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .sheet(isPresented: $showAddProfile) {
            ProfileEditorSheet(
                mode: .create,
                onSave: { name, avatarIndex, backgroundIndex in
                    appState.createProfile(name: name, avatarIndex: avatarIndex, backgroundIndex: backgroundIndex, makeActive: true)
                    showAddProfile = false
                },
                onCancel: {
                    showAddProfile = false
                }
            )
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Choose Your Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Select a learner to continue")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - Profile Grid
    private var profileGrid: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(appState.profiles) { profile in
                ProfileCardView(
                    profile: profile,
                    isSelected: appState.currentProfile?.id == profile.id
                ) {
                    appState.selectProfile(profile)
                }
            }

            // Add profile button
            AddProfileCardView {
                showAddProfile = true
            }
        }
    }
}

#Preview {
    ProfileSelectionScreen()
        .environmentObject(AppState())
}
