//
//  AppState.swift
//  Sproutling
//
//  Main app state management with multi-profile support
//

import Foundation
import SwiftUI
import SwiftData

class AppState: ObservableObject {
    // MARK: - Navigation
    @Published var currentScreen: Screen = .home

    // MARK: - Multi-Profile Support
    @Published var profiles: [ChildProfile] = []
    @Published var currentProfile: ChildProfile?
    @Published var syncStatus: SyncStatus = .idle

    // MARK: - PIN Session State
    @Published var isPINVerified: Bool = false

    // MARK: - Legacy Support (for current profile)
    var childProfile: ChildProfile {
        get { currentProfile ?? .sample }
        set {
            if var profile = currentProfile {
                profile = newValue
                currentProfile = profile
                saveCurrentProfile()
            }
        }
    }

    @Published var mathLevels: [LessonLevel] = LessonLevel.mathLevels()
    @Published var readingLevels: [LessonLevel] = LessonLevel.readingLevels()

    private var modelContext: ModelContext?
    private var persistedProfiles: [PersistedProfile] = []
    private var parentSettings: ParentSettings?

    // MARK: - Persistence Setup

    func setupPersistence(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAllProfiles()
        loadParentSettings()
    }

    private func loadParentSettings() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<ParentSettings>()
        let settings = (try? modelContext.fetch(descriptor)) ?? []

        if let existing = settings.first {
            parentSettings = existing
        } else {
            let newSettings = ParentSettings()
            modelContext.insert(newSettings)
            parentSettings = newSettings
            try? modelContext.save()
        }
    }

    // MARK: - Profile Management

    func loadAllProfiles() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<PersistedProfile>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        persistedProfiles = (try? modelContext.fetch(descriptor)) ?? []

        // Convert to ChildProfile array
        profiles = persistedProfiles.map { $0.toChildProfile() }

        // Find active profile or select first one
        if let activeProfile = persistedProfiles.first(where: { $0.isActive }) {
            activeProfile.updateStreak()
            currentProfile = activeProfile.toChildProfile()
            restoreLevelProgress()
        } else if let firstProfile = persistedProfiles.first {
            // Make first profile active if none are active
            firstProfile.isActive = true
            firstProfile.updateStreak()
            currentProfile = firstProfile.toChildProfile()
            restoreLevelProgress()
            try? modelContext.save()
        } else {
            // No profiles exist, create initial one
            createProfile(name: "Little Learner", avatarIndex: 0, makeActive: true)
        }

        // Determine initial screen
        if profiles.count > 1 && currentProfile == nil {
            currentScreen = .profileSelection
        }
    }

    func selectProfile(_ profile: ChildProfile) {
        guard let modelContext = modelContext else { return }

        // Deactivate all profiles
        for persisted in persistedProfiles {
            persisted.isActive = false
        }

        // Activate selected profile
        if let persisted = persistedProfiles.first(where: { $0.profileId == profile.id }) {
            persisted.isActive = true
            persisted.updateStreak()
            currentProfile = persisted.toChildProfile()

            // Reset and restore level progress for this profile
            mathLevels = LessonLevel.mathLevels()
            readingLevels = LessonLevel.readingLevels()
            restoreLevelProgress()

            try? modelContext.save()

            // Update profiles array
            profiles = persistedProfiles.map { $0.toChildProfile() }

            navigateTo(.home)
        }
    }

    func createProfile(name: String, avatarIndex: Int, backgroundIndex: Int = 0, makeActive: Bool = false) {
        guard let modelContext = modelContext else { return }

        let newProfile = PersistedProfile(
            name: name,
            avatarIndex: avatarIndex,
            backgroundIndex: backgroundIndex,
            isActive: makeActive,
            sortOrder: persistedProfiles.count
        )

        if makeActive {
            // Deactivate all other profiles
            for persisted in persistedProfiles {
                persisted.isActive = false
            }
            newProfile.updateStreak()
        }

        modelContext.insert(newProfile)
        persistedProfiles.append(newProfile)

        if makeActive {
            currentProfile = newProfile.toChildProfile()
            mathLevels = LessonLevel.mathLevels()
            readingLevels = LessonLevel.readingLevels()
        }

        try? modelContext.save()
        profiles = persistedProfiles.map { $0.toChildProfile() }
    }

    func updateProfile(_ profile: ChildProfile) {
        guard let modelContext = modelContext else { return }

        if let persisted = persistedProfiles.first(where: { $0.profileId == profile.id }) {
            persisted.update(from: profile)
            try? modelContext.save()

            // Update current profile if it's the one being edited
            if currentProfile?.id == profile.id {
                currentProfile = persisted.toChildProfile()
            }

            profiles = persistedProfiles.map { $0.toChildProfile() }
        }
    }

    func deleteProfile(_ profile: ChildProfile) {
        guard let modelContext = modelContext else { return }
        guard profiles.count > 1 else { return } // Can't delete last profile

        if let persisted = persistedProfiles.first(where: { $0.profileId == profile.id }) {
            modelContext.delete(persisted)
            persistedProfiles.removeAll { $0.profileId == profile.id }

            // If we deleted the active profile, switch to another
            if currentProfile?.id == profile.id {
                if let firstRemaining = persistedProfiles.first {
                    firstRemaining.isActive = true
                    currentProfile = firstRemaining.toChildProfile()
                    mathLevels = LessonLevel.mathLevels()
                    readingLevels = LessonLevel.readingLevels()
                    restoreLevelProgress()
                }
            }

            try? modelContext.save()
            profiles = persistedProfiles.map { $0.toChildProfile() }
        }
    }

    func reorderProfiles(_ indices: IndexSet, to destination: Int) {
        guard let modelContext = modelContext else { return }

        var profilesCopy = profiles
        profilesCopy.move(fromOffsets: indices, toOffset: destination)

        // Update sort orders
        for (index, profile) in profilesCopy.enumerated() {
            if let persisted = persistedProfiles.first(where: { $0.profileId == profile.id }) {
                persisted.sortOrder = index
            }
        }

        try? modelContext.save()
        profiles = profilesCopy
    }

    // MARK: - PIN Management

    var hasPIN: Bool {
        KeychainManager.shared.hasPIN()
    }

    var requiresPIN: Bool {
        parentSettings?.requirePinForSettings ?? false
    }

    func verifyPIN(_ pin: String) -> Bool {
        let verified = KeychainManager.shared.verifyPIN(pin)
        if verified {
            isPINVerified = true
        }
        return verified
    }

    func setPIN(_ pin: String) -> Bool {
        let success = KeychainManager.shared.savePIN(pin)
        if success {
            parentSettings?.requirePinForSettings = true
            try? modelContext?.save()
            isPINVerified = true
        }
        return success
    }

    func clearPIN() {
        KeychainManager.shared.deletePIN()
        parentSettings?.requirePinForSettings = false
        try? modelContext?.save()
        isPINVerified = false
    }

    func lockSettings() {
        isPINVerified = false
    }

    // MARK: - Level Progress

    private func restoreLevelProgress() {
        guard let profile = currentProfile else { return }

        // Restore math level stars and unlock status
        for (level, stars) in profile.mathProgress {
            if let index = mathLevels.firstIndex(where: { $0.id == level }) {
                mathLevels[index].starsEarned = stars
                // Unlock next level if earned at least 1 star
                if stars >= 1 && index + 1 < mathLevels.count {
                    mathLevels[index + 1].isUnlocked = true
                }
            }
        }

        // Restore reading level stars and unlock status
        for (level, stars) in profile.readingProgress {
            if let index = readingLevels.firstIndex(where: { $0.id == level }) {
                readingLevels[index].starsEarned = stars
                if stars >= 1 && index + 1 < readingLevels.count {
                    readingLevels[index + 1].isUnlocked = true
                }
            }
        }
    }

    private func saveCurrentProfile() {
        guard let profile = currentProfile,
              let persisted = persistedProfiles.first(where: { $0.profileId == profile.id }) else { return }
        persisted.update(from: profile)
        try? modelContext?.save()
        profiles = persistedProfiles.map { $0.toChildProfile() }
    }

    // MARK: - Navigation

    func navigateTo(_ screen: Screen) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = screen
        }
    }

    func goHome() {
        navigateTo(.home)
    }

    func goToProgress() {
        navigateTo(.progress)
    }

    func goToSettings() {
        navigateTo(.settings)
    }

    func goToProfileSelection() {
        navigateTo(.profileSelection)
    }

    func goToProfileManagement() {
        navigateTo(.profileManagement)
    }

    func selectSubject(_ subject: Subject) {
        navigateTo(.subjectSelection(subject))
    }

    func startLesson(subject: Subject, level: Int) {
        navigateTo(.lesson(subject, level))
    }

    func completeLesson(subject: Subject, level: Int, stars: Int) {
        guard var profile = currentProfile else { return }

        // Update progress
        profile.totalStars += stars

        // Update level stars
        switch subject {
        case .math:
            if let index = mathLevels.firstIndex(where: { $0.id == level }) {
                let newStars = max(mathLevels[index].starsEarned, stars)
                mathLevels[index].starsEarned = newStars
                profile.mathProgress[level] = newStars
                // Unlock next level if earned at least 1 star
                if stars >= 1 && index + 1 < mathLevels.count {
                    mathLevels[index + 1].isUnlocked = true
                }
            }
        case .reading:
            if let index = readingLevels.firstIndex(where: { $0.id == level }) {
                let newStars = max(readingLevels[index].starsEarned, stars)
                readingLevels[index].starsEarned = newStars
                profile.readingProgress[level] = newStars
                if stars >= 1 && index + 1 < readingLevels.count {
                    readingLevels[index + 1].isUnlocked = true
                }
            }
        }

        currentProfile = profile

        // Persist progress
        saveCurrentProfile()

        navigateTo(.lessonComplete(subject, stars))
    }

    func levels(for subject: Subject) -> [LessonLevel] {
        switch subject {
        case .math: return mathLevels
        case .reading: return readingLevels
        }
    }
}
