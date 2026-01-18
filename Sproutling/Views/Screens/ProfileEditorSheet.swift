//
//  ProfileEditorSheet.swift
//  Sproutling
//
//  Sheet for creating or editing a child profile
//

import SwiftUI

enum ProfileEditorMode {
    case create
    case edit(ChildProfile)
}

struct ProfileEditorSheet: View {
    let mode: ProfileEditorMode
    let onSave: (String, Int, Int) -> Void  // name, avatarIndex, backgroundIndex
    let onCancel: () -> Void
    var onDelete: (() -> Void)?

    @State private var name: String = ""
    @State private var avatarIndex: Int = 0
    @State private var backgroundIndex: Int = 0
    @State private var showDeleteConfirmation = false
    @FocusState private var nameFieldFocused: Bool

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var title: String {
        isEditing ? "Edit Profile" : "New Profile"
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar preview
                        avatarPreviewSection

                        // Name field
                        nameSection

                        // Avatar picker
                        AvatarPickerView(selectedIndex: $avatarIndex)

                        // Background picker
                        BackgroundPickerView(selectedIndex: $backgroundIndex)

                        // Delete button (only in edit mode)
                        if isEditing, let onDelete = onDelete {
                            deleteSection(onDelete: onDelete)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(trimmedName, avatarIndex, backgroundIndex)
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?()
            }
        } message: {
            Text("This will permanently delete this profile and all their progress. This cannot be undone.")
        }
    }

    // MARK: - Avatar Preview
    private var avatarPreviewSection: some View {
        VStack(spacing: 12) {
            ProfileAvatarView(avatarIndex: avatarIndex, backgroundIndex: backgroundIndex, size: 100)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: avatarIndex)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: backgroundIndex)

            Text(name.isEmpty ? "New Learner" : name)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.top, 20)
    }

    // MARK: - Name Section
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.headline)
                .foregroundColor(.primary)

            TextField("Enter name", text: $name)
                .font(.title3)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                .focused($nameFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    nameFieldFocused = false
                }
        }
    }

    // MARK: - Delete Section
    private func deleteSection(onDelete: @escaping () -> Void) -> some View {
        Button(action: {
            showDeleteConfirmation = true
        }) {
            HStack {
                Image(systemName: "trash.fill")
                    .foregroundColor(.red)
                Text("Delete Profile")
                    .foregroundColor(.red)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
            )
        }
        .padding(.top, 20)
        .accessibilityLabel("Delete profile")
        .accessibilityHint("Double tap to delete this profile permanently")
    }

    // MARK: - Setup
    private func setupInitialValues() {
        switch mode {
        case .create:
            name = ""
            avatarIndex = Int.random(in: 0..<ProfileAvatar.allAvatars.count)
            backgroundIndex = Int.random(in: 0..<ProfileBackground.allBackgrounds.count)
        case .edit(let profile):
            name = profile.name
            avatarIndex = profile.avatarIndex
            backgroundIndex = profile.backgroundIndex
        }

        // Focus name field after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            nameFieldFocused = true
        }
    }
}

#Preview("Create Mode") {
    ProfileEditorSheet(
        mode: .create,
        onSave: { _, _, _ in },
        onCancel: {}
    )
}

#Preview("Edit Mode") {
    ProfileEditorSheet(
        mode: .edit(.sample),
        onSave: { _, _, _ in },
        onCancel: {},
        onDelete: {}
    )
}
