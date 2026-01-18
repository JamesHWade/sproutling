//
//  ProfileManagementScreen.swift
//  Sproutling
//
//  Screen for managing all child profiles (accessed from settings, PIN-gated)
//

import SwiftUI

struct ProfileManagementScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var editingProfile: ChildProfile?
    @State private var showAddProfile = false
    @State private var showDeleteConfirmation = false
    @State private var profileToDelete: ChildProfile?

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Navigation bar
                SproutlingNavBar(
                    title: "Manage Profiles",
                    onBack: { appState.goToSettings() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Info header
                        infoHeader

                        // Profile list
                        profileList

                        // Add profile button
                        addProfileButton

                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
        }
        .sheet(item: $editingProfile) { profile in
            ProfileEditorSheet(
                mode: .edit(profile),
                onSave: { name, avatarIndex, backgroundIndex in
                    var updatedProfile = profile
                    updatedProfile.name = name
                    updatedProfile.avatarIndex = avatarIndex
                    updatedProfile.backgroundIndex = backgroundIndex
                    appState.updateProfile(updatedProfile)
                    editingProfile = nil
                },
                onCancel: {
                    editingProfile = nil
                },
                onDelete: {
                    editingProfile = nil
                    profileToDelete = profile
                    showDeleteConfirmation = true
                }
            )
        }
        .sheet(isPresented: $showAddProfile) {
            ProfileEditorSheet(
                mode: .create,
                onSave: { name, avatarIndex, backgroundIndex in
                    appState.createProfile(name: name, avatarIndex: avatarIndex, backgroundIndex: backgroundIndex)
                    showAddProfile = false
                },
                onCancel: {
                    showAddProfile = false
                }
            )
        }
        .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                profileToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let profile = profileToDelete {
                    appState.deleteProfile(profile)
                }
                profileToDelete = nil
            }
        } message: {
            if let profile = profileToDelete {
                Text("Delete \(profile.name)'s profile? All their progress will be lost. This cannot be undone.")
            }
        }
    }

    // MARK: - Info Header
    private var infoHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.title2)
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("Child Profiles")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(appState.profiles.count) profile\(appState.profiles.count == 1 ? "" : "s") • Synced across devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            SyncStatusIndicator(status: appState.syncStatus)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }

    // MARK: - Profile List
    private var profileList: some View {
        VStack(spacing: 0) {
            ForEach(appState.profiles) { profile in
                VStack(spacing: 0) {
                    ProfileListRow(
                        profile: profile,
                        isActive: appState.currentProfile?.id == profile.id,
                        onEdit: {
                            editingProfile = profile
                        },
                        onDelete: {
                            if appState.profiles.count > 1 {
                                profileToDelete = profile
                                showDeleteConfirmation = true
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appState.selectProfile(profile)
                    }

                    if profile.id != appState.profiles.last?.id {
                        Divider()
                            .padding(.leading, 66)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        )
    }

    // MARK: - Add Profile Button
    private var addProfileButton: some View {
        Button(action: {
            showAddProfile = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)

                Text("Add New Profile")
                    .font(.headline)
                    .foregroundColor(.purple)

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
        .accessibilityLabel("Add new profile")
        .accessibilityHint("Double tap to create a new child profile")
    }
}

#Preview {
    ProfileManagementScreen()
        .environmentObject(AppState())
}
