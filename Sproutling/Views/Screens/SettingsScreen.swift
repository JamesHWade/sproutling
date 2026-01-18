//
//  SettingsScreen.swift
//  Sproutling
//
//  Settings and preferences screen
//

import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var soundManager = SoundManager.shared
    @State private var showResetConfirmation: Bool = false
    @State private var editingName: Bool = false
    @State private var newName: String = ""
    @State private var showPINSheet: Bool = false
    @State private var pinSheetMode: PINSheetMode = .setup
    @State private var pendingAction: (() -> Void)?

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
                    title: "Settings",
                    onBack: { appState.goHome() }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Profile section
                        profileSection

                        // Profiles & Sync section
                        profilesSection

                        // Parent Controls section
                        parentControlsSection

                        // Sound & Haptics
                        soundHapticsSection

                        // App info
                        appInfoSection

                        // Reset section
                        resetSection

                        Spacer().frame(height: 40)
                    }
                    .padding(20)
                }
            }
        }
        .alert("Reset Progress?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetProgress()
            }
        } message: {
            Text("This will reset all your stars and progress. This cannot be undone.")
        }
        .sheet(isPresented: $showPINSheet) {
            ParentPINSheet(
                mode: pinSheetMode,
                onSuccess: {
                    showPINSheet = false
                    if let action = pendingAction {
                        action()
                        pendingAction = nil
                    }
                },
                onCancel: {
                    showPINSheet = false
                    pendingAction = nil
                }
            )
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                // Name row
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if editingName {
                            TextField("Enter name", text: $newName)
                                .font(.headline)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    saveName()
                                }
                        } else {
                            Text(appState.childProfile.name)
                                .font(.headline)
                        }
                    }

                    Spacer()

                    if editingName {
                        Button("Save") {
                            saveName()
                        }
                        .foregroundColor(.purple)
                        .accessibilityHint("Double tap to save the new name")
                    } else {
                        Button("Edit") {
                            newName = appState.childProfile.name
                            editingName = true
                        }
                        .foregroundColor(.purple)
                        .accessibilityHint("Double tap to edit the name")
                    }
                }
                .padding(16)
                .accessibilityElement(children: .combine)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
    }

    private func saveName() {
        if !newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            appState.childProfile.name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        editingName = false
    }

    // MARK: - Profiles & Sync Section
    private var profilesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profiles & Sync")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                // Manage Profiles
                Button(action: {
                    handlePINProtectedAction {
                        appState.goToProfileManagement()
                    }
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Manage Profiles")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("\(appState.profiles.count) profile\(appState.profiles.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(16)
                }

                Divider()
                    .padding(.leading, 52)

                // Switch Profile
                if appState.profiles.count > 1 {
                    Button(action: {
                        appState.goToProfileSelection()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Switch Profile")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Currently: \(appState.childProfile.name)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                    }

                    Divider()
                        .padding(.leading, 52)
                }

                // Sync status
                HStack {
                    Image(systemName: "icloud.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("iCloud Sync")
                            .font(.headline)
                            .foregroundColor(.primary)

                        SyncStatusIndicator(status: appState.syncStatus)
                    }

                    Spacer()
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
    }

    // MARK: - Parent Controls Section
    private var parentControlsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Parent Controls")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                // Time limit toggle
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Time Limit")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Encourage healthy screen time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { appState.timeLimitEnabled },
                        set: { newValue in
                            appState.setTimeLimit(enabled: newValue)
                        }
                    ))
                    .labelsHidden()
                }
                .padding(16)

                if appState.timeLimitEnabled {
                    Divider()
                        .padding(.leading, 52)

                    // Time limit picker
                    HStack {
                        Image(systemName: "timer")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .frame(width: 36)

                        Text("Daily Limit")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()

                        Picker("", selection: Binding(
                            get: { TimeLimitOption.from(minutes: appState.dailyTimeLimitMinutes) },
                            set: { option in
                                appState.setTimeLimit(enabled: true, minutes: option.rawValue)
                            }
                        )) {
                            ForEach(TimeLimitOption.allCases) { option in
                                Text(option.displayName).tag(option)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    .padding(16)

                    Divider()
                        .padding(.leading, 52)

                    // Remaining time display
                    HStack {
                        Image(systemName: "hourglass")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time Remaining Today")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(formatRemainingTime(appState.remainingTimeSeconds))
                                .font(.caption)
                                .foregroundColor(appState.remainingTimeSeconds < 300 ? .orange : .secondary)
                        }

                        Spacer()

                        if appState.todayUsageSeconds > 0 {
                            Button("Reset") {
                                appState.resetDailyUsage()
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(16)
                }

                Divider()
                    .padding(.leading, 52)

                // PIN toggle
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .frame(width: 36)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Require PIN")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("For settings & profile management")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { appState.hasPIN },
                        set: { newValue in
                            if newValue {
                                // Set up PIN
                                pinSheetMode = .setup
                                showPINSheet = true
                            } else {
                                // Remove PIN (requires verification first)
                                if appState.hasPIN {
                                    pinSheetMode = .verify
                                    pendingAction = {
                                        appState.clearPIN()
                                    }
                                    showPINSheet = true
                                }
                            }
                        }
                    ))
                    .labelsHidden()
                }
                .padding(16)

                if appState.hasPIN {
                    Divider()
                        .padding(.leading, 52)

                    // Change PIN
                    Button(action: {
                        pinSheetMode = .verify
                        pendingAction = {
                            pinSheetMode = .change
                            showPINSheet = true
                        }
                        showPINSheet = true
                    }) {
                        HStack {
                            Image(systemName: "key.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                                .frame(width: 36)

                            Text("Change PIN")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(16)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
    }

    private func formatRemainingTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m remaining"
        } else if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s remaining"
        } else {
            return "\(remainingSeconds)s remaining"
        }
    }

    // MARK: - PIN Protected Action Helper
    private func handlePINProtectedAction(action: @escaping () -> Void) {
        if appState.hasPIN && !appState.isPINVerified {
            pinSheetMode = .verify
            pendingAction = action
            showPINSheet = true
        } else {
            action()
        }
    }

    // MARK: - Sound & Haptics Section
    private var soundHapticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sound & Feedback")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                // Sound toggle
                SettingsToggleRow(
                    icon: "speaker.wave.2.fill",
                    title: "Sounds",
                    subtitle: "Play sounds during activities",
                    isOn: $soundManager.soundEnabled,
                    iconColor: .blue
                )

                Divider()
                    .padding(.leading, 52)

                // Haptics toggle
                SettingsToggleRow(
                    icon: "hand.tap.fill",
                    title: "Haptics",
                    subtitle: "Vibration feedback on tap",
                    isOn: $soundManager.hapticsEnabled,
                    iconColor: .orange
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
    }

    // MARK: - App Info Section
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                SettingsInfoRow(
                    icon: "info.circle.fill",
                    title: "Version",
                    value: "1.0.0",
                    iconColor: .gray
                )

                Divider()
                    .padding(.leading, 52)

                SettingsInfoRow(
                    icon: "heart.fill",
                    title: "Made with",
                    value: "SwiftUI",
                    iconColor: .pink
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
        }
    }

    // MARK: - Reset Section
    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data")
                .font(.title3)
                .fontWeight(.bold)
                .accessibilityAddTraits(.isHeader)

            Button(action: {
                showResetConfirmation = true
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reset Progress")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text("Clears all stars and achievements")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                        .accessibilityHidden(true)
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            )
            .accessibilityLabel("Reset progress. Clears all stars and achievements")
            .accessibilityHint("Double tap to reset. You will be asked to confirm")
        }
    }

    private func resetProgress() {
        appState.childProfile.totalStars = 0
        appState.childProfile.mathProgress = [:]
        appState.childProfile.readingProgress = [:]
        // Reset level states
        for index in appState.mathLevels.indices {
            appState.mathLevels[index].starsEarned = 0
            appState.mathLevels[index].isUnlocked = index == 0
        }
        for index in appState.readingLevels.indices {
            appState.readingLevels[index].starsEarned = 0
            appState.readingLevels[index].isUnlocked = index == 0
        }
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var iconColor: Color = .blue

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(16)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityValue(isOn ? "On" : "Off")
        .accessibilityHint("Double tap to toggle")
    }
}

// MARK: - Settings Info Row
struct SettingsInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var iconColor: Color = .gray

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 36)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title): \(value)")
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(AppState())
}
