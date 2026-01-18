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

    // ElevenLabs TTS settings
    @State private var showAPIKeySheet: Bool = false
    @State private var apiKeyInput: String = ""
    @State private var isValidatingKey: Bool = false
    @State private var keyValidationResult: Bool? = nil
    @State private var keyValidationMessage: String? = nil
    @State private var availableVoices: [VoiceInfo] = []
    @State private var isLoadingVoices: Bool = false
    @State private var showVoiceTestFeedback: Bool = false
    @State private var showVoicePicker: Bool = false
    @AppStorage("selectedVoiceId") private var selectedVoiceId: String = ElevenLabsService.Voice.bella.rawValue

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

                        // ElevenLabs Voice
                        elevenLabsSection

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
        .sheet(isPresented: $showAPIKeySheet) {
            ElevenLabsAPIKeySheet(
                apiKey: $apiKeyInput,
                isValidating: $isValidatingKey,
                validationResult: $keyValidationResult,
                validationMessage: keyValidationMessage,
                onSave: saveAPIKey,
                onCancel: { showAPIKeySheet = false }
            )
        }
        .sheet(isPresented: $showVoicePicker) {
            NavigationStack {
                VoiceSelectionView(selectedVoiceId: $selectedVoiceId)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showVoicePicker = false
                            }
                        }
                    }
            }
        }
        .onAppear {
            loadElevenLabsState()
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

    // MARK: - ElevenLabs TTS Section
    private var elevenLabsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Voice Settings")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                if hasElevenLabsKey {
                    Text("Premium")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                        )
                }
            }
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                // ElevenLabs toggle
                SettingsToggleRow(
                    icon: "waveform.circle.fill",
                    title: "Natural Voice",
                    subtitle: hasElevenLabsKey ? "ElevenLabs TTS enabled" : "Configure API key to enable",
                    isOn: $soundManager.elevenLabsEnabled,
                    iconColor: .purple
                )
                .disabled(!hasElevenLabsKey)
                .opacity(hasElevenLabsKey ? 1.0 : 0.6)

                Divider()
                    .padding(.leading, 52)

                // API Key configuration
                Button(action: {
                    handlePINProtectedAction {
                        apiKeyInput = ""
                        keyValidationResult = nil
                        showAPIKeySheet = true
                    }
                }) {
                    HStack {
                        Image(systemName: "key.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                            .frame(width: 36)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("API Key")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text(hasElevenLabsKey ? "Configured" : "Not configured")
                                .font(.caption)
                                .foregroundColor(hasElevenLabsKey ? .green : .secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(16)
                }

                if hasElevenLabsKey && soundManager.elevenLabsEnabled {
                    Divider()
                        .padding(.leading, 52)

                    // Voice selection
                    Button {
                        showVoicePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Voice")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if let voice = ElevenLabsService.Voice(rawValue: selectedVoiceId) {
                                    Text("\(voice.displayName) - \(voice.description)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(16)

                    Divider()
                        .padding(.leading, 52)

                    // Test voice button
                    Button(action: testVoice) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Test Voice")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Text("Hear a sample of the selected voice")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if showVoiceTestFeedback {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
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

    // MARK: - ElevenLabs Helpers
    private var hasElevenLabsKey: Bool {
        UserDefaults.standard.bool(forKey: "hasElevenLabsKey")
    }

    private func loadElevenLabsState() {
        Task {
            let hasKey = await ElevenLabsService.shared.hasAPIKey()
            await MainActor.run {
                UserDefaults.standard.set(hasKey, forKey: "hasElevenLabsKey")
            }
        }
    }

    private func saveAPIKey() {
        guard !apiKeyInput.isEmpty else { return }

        isValidatingKey = true
        keyValidationResult = nil
        keyValidationMessage = nil

        Task {
            // Save the key
            let saved = await ElevenLabsService.shared.saveAPIKey(apiKeyInput)

            if saved {
                // Validate it
                let result = await ElevenLabsService.shared.validateAPIKey()

                await MainActor.run {
                    isValidatingKey = false
                    keyValidationResult = result.isValid
                    keyValidationMessage = result.userMessage

                    if result.isValid {
                        UserDefaults.standard.set(true, forKey: "hasElevenLabsKey")
                        // Close sheet after a brief delay to show success
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            showAPIKeySheet = false
                            // Trigger preloading
                            soundManager.preloadCommonAudio()
                        }
                    }
                }
            } else {
                await MainActor.run {
                    isValidatingKey = false
                    keyValidationResult = false
                    keyValidationMessage = "Failed to save API key."
                }
            }
        }
    }

    private func testVoice() {
        showVoiceTestFeedback = false

        soundManager.speakPersonalized("Great job, {name}! You're doing amazing!", childName: appState.childProfile.name) {
            DispatchQueue.main.async {
                showVoiceTestFeedback = true
                // Hide feedback after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showVoiceTestFeedback = false
                }
            }
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

// MARK: - ElevenLabs API Key Sheet
struct ElevenLabsAPIKeySheet: View {
    @Binding var apiKey: String
    @Binding var isValidating: Bool
    @Binding var validationResult: Bool?
    var validationMessage: String?
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .padding(.top, 20)

                // Title and description
                VStack(spacing: 8) {
                    Text("ElevenLabs API Key")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Enter your ElevenLabs API key to enable natural-sounding voice for your child's learning experience.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // API Key input
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    SecureField("Enter your API key", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal)

                // Validation status
                if isValidating {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Validating...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let result = validationResult {
                    HStack {
                        Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result ? .green : .red)
                        Text(result ? "API key is valid!" : (validationMessage ?? "Invalid API key."))
                            .font(.subheadline)
                            .foregroundColor(result ? .green : .red)
                    }
                }

                // Help link
                Link(destination: URL(string: "https://elevenlabs.io/app/settings/api-keys")!) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Get your API key from ElevenLabs")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }

                Spacer()

                // Save button
                Button(action: onSave) {
                    HStack {
                        if isValidating {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isValidating ? "Validating..." : "Save API Key")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(apiKey.isEmpty ? Color.gray : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(apiKey.isEmpty || isValidating)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Voice Selection View

struct VoiceSelectionView: View {
    @Binding var selectedVoiceId: String
    @Environment(\.dismiss) private var dismiss

    private let femaleVoices = ElevenLabsService.Voice.allCases.filter { $0.isFemale }
    private let maleVoices = ElevenLabsService.Voice.allCases.filter { !$0.isFemale }

    var body: some View {
        List {
            Section {
                ForEach(femaleVoices) { voice in
                    VoiceRow(voice: voice, isSelected: selectedVoiceId == voice.rawValue) {
                        selectedVoiceId = voice.rawValue
                        testVoice(voice)
                    }
                }
            } header: {
                Label("Female Voices", systemImage: "person.fill")
            }

            Section {
                ForEach(maleVoices) { voice in
                    VoiceRow(voice: voice, isSelected: selectedVoiceId == voice.rawValue) {
                        selectedVoiceId = voice.rawValue
                        testVoice(voice)
                    }
                }
            } header: {
                Label("Male Voices", systemImage: "person.fill")
            }
        }
        .navigationTitle("Choose Voice")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func testVoice(_ voice: ElevenLabsService.Voice) {
        let greeting = "Hi there! I'm \(voice.displayName)."
        SoundManager.shared.speakWithElevenLabs(greeting, settings: .childFriendly)
    }
}

struct VoiceRow: View {
    let voice: ElevenLabsService.Voice
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .purple : .gray.opacity(0.4))

                // Voice info
                VStack(alignment: .leading, spacing: 4) {
                    Text(voice.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(voice.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Play indicator
                Image(systemName: "play.circle")
                    .font(.title2)
                    .foregroundColor(.purple.opacity(0.6))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(AppState())
}

#Preview("Voice Selection") {
    NavigationStack {
        VoiceSelectionView(selectedVoiceId: .constant(ElevenLabsService.Voice.bella.rawValue))
    }
}
