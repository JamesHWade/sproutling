//
//  ProfileComponents.swift
//  Sproutling
//
//  Reusable components for profile management UI
//

import SwiftUI

// MARK: - Profile Avatar View
struct ProfileAvatarView: View {
    let avatarIndex: Int
    var backgroundIndex: Int = 0
    var size: CGFloat = 60
    var showBorder: Bool = true

    private var avatar: ProfileAvatar {
        ProfileAvatar.from(index: avatarIndex)
    }

    private var background: ProfileBackground {
        ProfileBackground.from(index: backgroundIndex)
    }

    var body: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: background.colors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            // Avatar emoji
            Text(avatar.emoji)
                .font(.system(size: size * 0.5))

            // Border
            if showBorder {
                Circle()
                    .stroke(Color.white, lineWidth: size * 0.05)
                    .frame(width: size, height: size)
            }
        }
        .shadow(color: background.colors.first?.opacity(0.4) ?? .clear, radius: 8, y: 4)
        .accessibilityLabel("\(avatar.name) avatar with \(background.name) background")
    }
}

// MARK: - Profile Card View (for selection grid)
struct ProfileCardView: View {
    let profile: ChildProfile
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var avatar: ProfileAvatar {
        ProfileAvatar.from(index: profile.avatarIndex)
    }

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            VStack(spacing: 12) {
                // Avatar
                ProfileAvatarView(avatarIndex: profile.avatarIndex, backgroundIndex: profile.backgroundIndex, size: 80)
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? Color.green : Color.clear,
                                lineWidth: 4
                            )
                            .frame(width: 88, height: 88)
                    )

                // Name
                Text(profile.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Seeds
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.caption)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    Text("\(profile.totalStars)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)
            .frame(width: 140, height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(
                        color: isSelected ? .green.opacity(0.3) : .black.opacity(0.1),
                        radius: isSelected ? 12 : 8,
                        y: 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.green : Color.clear,
                        lineWidth: 3
                    )
            )
        }
        .buttonStyle(ProfileCardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(profile.name)'s profile, \(profile.totalStars) seeds")
        .accessibilityHint(isSelected ? "Currently selected" : "Double tap to switch to this profile")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Profile Card Button Style
struct ProfileCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Add Profile Card
struct AddProfileCardView: View {
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 80, height: 80)

                    Circle()
                        .strokeBorder(
                            style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                        )
                        .foregroundColor(.gray.opacity(0.4))
                        .frame(width: 80, height: 80)

                    Image(systemName: "plus")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.gray)
                }

                Text("Add Profile")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()
                    .frame(height: 20)
            }
            .padding(16)
            .frame(width: 140, height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.5))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                    )
                    .foregroundColor(.gray.opacity(0.3))
            )
        }
        .buttonStyle(ProfileCardButtonStyle())
        .accessibilityLabel("Add new profile")
        .accessibilityHint("Double tap to create a new child profile")
    }
}

// MARK: - Avatar Picker (Horizontal Scrolling Categories)
struct AvatarPickerView: View {
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose an Avatar")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            ForEach(ProfileAvatar.AvatarCategory.allCases, id: \.self) { category in
                AvatarCategorySection(
                    category: category,
                    selectedIndex: $selectedIndex
                )
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Avatar Category Section
struct AvatarCategorySection: View {
    let category: ProfileAvatar.AvatarCategory
    @Binding var selectedIndex: Int

    private var avatarsInCategory: [ProfileAvatar] {
        ProfileAvatar.avatars(for: category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category header
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Horizontal scroll of avatars
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(avatarsInCategory, id: \.emoji) { avatar in
                        let index = ProfileAvatar.index(of: avatar)
                        AvatarOptionButton(
                            avatar: avatar,
                            isSelected: selectedIndex == index
                        ) {
                            HapticFeedback.light()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Background Picker (Horizontal Scrolling Categories)
struct BackgroundPickerView: View {
    @Binding var selectedIndex: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose a Background")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            ForEach(ProfileBackground.BackgroundFamily.allCases, id: \.self) { family in
                BackgroundFamilySection(
                    family: family,
                    selectedIndex: $selectedIndex
                )
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Background Family Section
struct BackgroundFamilySection: View {
    let family: ProfileBackground.BackgroundFamily
    @Binding var selectedIndex: Int

    private var backgroundsInFamily: [ProfileBackground] {
        ProfileBackground.backgrounds(for: family)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Family header
            Text(family.rawValue)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Horizontal scroll of backgrounds
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(backgroundsInFamily, id: \.name) { background in
                        let index = ProfileBackground.index(of: background)
                        BackgroundOptionButton(
                            background: background,
                            isSelected: selectedIndex == index
                        ) {
                            HapticFeedback.light()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedIndex = index
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Background Option Button
struct BackgroundOptionButton: View {
    let background: ProfileBackground
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Background preview circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: background.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)

                    // Selection indicator (inside the circle)
                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 56, height: 56)

                        // Inner checkmark
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white, .green)
                    }
                }
                .frame(width: 60, height: 60)

                // Background name
                Text(background.name)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .accessibilityLabel("\(background.name) background")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Avatar Option Button
struct AvatarOptionButton: View {
    let avatar: ProfileAvatar
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(isSelected ? Color.green.opacity(0.15) : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)

                    // Emoji
                    Text(avatar.emoji)
                        .font(.system(size: 32))

                    // Selection indicator (inside the circle)
                    if isSelected {
                        Circle()
                            .stroke(Color.green, lineWidth: 3)
                            .frame(width: 60, height: 60)
                    }
                }
                .frame(width: 64, height: 64)

                // Avatar name
                Text(avatar.name)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .green : .secondary)
                    .lineLimit(1)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .accessibilityLabel("\(avatar.name) avatar")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Sync Status Indicator
struct SyncStatusIndicator: View {
    let status: SyncStatus

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: status.iconName)
                .font(.subheadline)
                .foregroundColor(statusColor)
                .rotationEffect(.degrees(status == .syncing && isAnimating ? 360 : 0))
                .animation(
                    status == .syncing
                        ? .linear(duration: 1.5).repeatForever(autoreverses: false)
                        : .default,
                    value: isAnimating
                )

            Text(status.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .onAppear {
            if case .syncing = status {
                isAnimating = true
            }
        }
        .onChange(of: status) { _, newValue in
            if case .syncing = newValue {
                isAnimating = true
            } else {
                isAnimating = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Sync status: \(status.description)")
    }

    private var statusColor: Color {
        switch status {
        case .idle: return .gray
        case .syncing: return .blue
        case .synced: return .green
        case .error: return .red
        }
    }
}

// MARK: - Profile List Row (for management)
struct ProfileListRow: View {
    let profile: ChildProfile
    let isActive: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var avatar: ProfileAvatar {
        ProfileAvatar.from(index: profile.avatarIndex)
    }

    var body: some View {
        HStack(spacing: 16) {
            ProfileAvatarView(avatarIndex: profile.avatarIndex, backgroundIndex: profile.backgroundIndex, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if isActive {
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "leaf.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text("\(profile.totalStars)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("\(profile.streakDays) day streak")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(profile.name)")
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Profile Switcher Sheet
struct ProfileSwitcherSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.cyan.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header message
                        Text("Who's learning now?")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.top, 20)

                        // Profile grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(appState.profiles) { profile in
                                ProfileCardView(
                                    profile: profile,
                                    isSelected: appState.currentProfile?.id == profile.id
                                ) {
                                    appState.selectProfile(profile)
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Switch Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Note: HapticFeedback is defined in SoundManager.swift

// MARK: - Previews

#Preview("Profile Avatar") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            ForEach(0..<4) { index in
                ProfileAvatarView(avatarIndex: index, backgroundIndex: index, size: 60)
            }
        }
        HStack(spacing: 20) {
            ForEach(4..<8) { index in
                ProfileAvatarView(avatarIndex: index, backgroundIndex: index, size: 60)
            }
        }
    }
    .padding()
}

#Preview("Profile Card") {
    HStack {
        ProfileCardView(
            profile: .sample,
            isSelected: true
        ) {}

        ProfileCardView(
            profile: ChildProfile(name: "Max", avatarIndex: 3, totalStars: 15),
            isSelected: false
        ) {}

        AddProfileCardView {}
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Avatar Picker") {
    AvatarPickerView(selectedIndex: .constant(2))
        .padding()
}

#Preview("Background Picker") {
    BackgroundPickerView(selectedIndex: .constant(3))
        .padding()
}
