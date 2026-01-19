//
//  AppState.swift
//  Sproutling
//
//  Main app state management with multi-profile support
//

import Foundation
import SwiftUI
import SwiftData
import os.log

/// Logger for AppState operations
private let appStateLogger = Logger(subsystem: "com.sproutling.app", category: "AppState")

@MainActor
class AppState: ObservableObject {
    // MARK: - Navigation
    @Published var currentScreen: Screen = .home

    // MARK: - Multi-Profile Support
    @Published var profiles: [ChildProfile] = []
    @Published var currentProfile: ChildProfile?
    @Published var syncStatus: SyncStatus = .idle

    // MARK: - PIN Session State
    @Published var isPINVerified: Bool = false

    // MARK: - Daily Time Limit Tracking
    @Published var sessionStartTime: Date = Date()
    @Published var todayUsageSeconds: Int = 0
    @Published var isTimeLimitReached: Bool = false
    private var usageTimer: Timer?
    private let usageKey = "dailyUsageSeconds"
    private let usageDateKey = "usageDate"

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
    @Published var shapesLevels: [LessonLevel] = LessonLevel.shapesLevels()

    private var _modelContext: ModelContext?
    private var persistedProfiles: [PersistedProfile] = []
    private var parentSettings: ParentSettings?

    /// Exposes the model context for spaced repetition tracking
    var modelContext: ModelContext? {
        _modelContext
    }

    /// Safely saves the model context with error logging
    /// Use this instead of try? modelContext.save() to track failures
    func saveContext(_ context: ModelContext? = nil) {
        let ctx = context ?? _modelContext
        do {
            try ctx?.save()
        } catch {
            appStateLogger.error("SwiftData save failed: \(error.localizedDescription, privacy: .public)")
            #if DEBUG
            appStateLogger.debug("Save error details: \(String(describing: error), privacy: .public)")
            #endif
        }
    }

    // MARK: - Persistence Setup

    func setupPersistence(modelContext: ModelContext) {
        self._modelContext = modelContext
        loadAllProfiles()
        loadParentSettings()
        checkiCloudStatus()
    }

    // MARK: - iCloud Sync Status

    /// Check if iCloud is available and update sync status accordingly
    private func checkiCloudStatus() {
        // Check if user is signed into iCloud
        if FileManager.default.ubiquityIdentityToken != nil {
            // iCloud is available - SwiftData syncs automatically
            // Use the lastSyncDate from settings if available, otherwise use now
            let lastSync = parentSettings?.lastSyncDate ?? Date()
            syncStatus = .synced(lastSync)

            // Update the lastSyncDate to now since we just loaded
            parentSettings?.lastSyncDate = Date()
            saveContext()
        } else {
            // iCloud not available (not signed in or disabled)
            syncStatus = .idle
        }
    }

    /// Call this when data is saved to update sync status
    func markSyncActivity() {
        if FileManager.default.ubiquityIdentityToken != nil {
            let now = Date()
            syncStatus = .synced(now)
            parentSettings?.lastSyncDate = now
        }
    }

    private func loadParentSettings() {
        guard let modelContext = _modelContext else { return }

        let descriptor = FetchDescriptor<ParentSettings>()
        let settings = (try? modelContext.fetch(descriptor)) ?? []

        if let existing = settings.first {
            parentSettings = existing
        } else {
            let newSettings = ParentSettings()
            modelContext.insert(newSettings)
            parentSettings = newSettings
            saveContext(modelContext)
        }
    }

    // MARK: - Profile Management

    func loadAllProfiles() {
        guard let modelContext = _modelContext else { return }

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
            saveContext(modelContext)
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
        guard let modelContext = _modelContext else { return }

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

            saveContext(modelContext)

            // Update profiles array
            profiles = persistedProfiles.map { $0.toChildProfile() }

            navigateTo(.home)
        }
    }

    func createProfile(name: String, avatarIndex: Int, backgroundIndex: Int = 0, makeActive: Bool = false) {
        guard let modelContext = _modelContext else { return }

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

        saveContext(modelContext)
        profiles = persistedProfiles.map { $0.toChildProfile() }
    }

    func updateProfile(_ profile: ChildProfile) {
        guard let modelContext = _modelContext else { return }

        if let persisted = persistedProfiles.first(where: { $0.profileId == profile.id }) {
            persisted.update(from: profile)
            saveContext(modelContext)

            // Update current profile if it's the one being edited
            if currentProfile?.id == profile.id {
                currentProfile = persisted.toChildProfile()
            }

            profiles = persistedProfiles.map { $0.toChildProfile() }
        }
    }

    func deleteProfile(_ profile: ChildProfile) {
        guard let modelContext = _modelContext else { return }
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

            saveContext(modelContext)
            profiles = persistedProfiles.map { $0.toChildProfile() }
        }
    }

    func reorderProfiles(_ indices: IndexSet, to destination: Int) {
        guard let modelContext = _modelContext else { return }

        var profilesCopy = profiles
        profilesCopy.move(fromOffsets: indices, toOffset: destination)

        // Update sort orders
        for (index, profile) in profilesCopy.enumerated() {
            if let persisted = persistedProfiles.first(where: { $0.profileId == profile.id }) {
                persisted.sortOrder = index
            }
        }

        saveContext(modelContext)
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
            saveContext()
            isPINVerified = true
        }
        return success
    }

    func clearPIN() {
        KeychainManager.shared.deletePIN()
        parentSettings?.requirePinForSettings = false
        saveContext()
        isPINVerified = false
    }

    func lockSettings() {
        isPINVerified = false
    }

    // MARK: - Level Progress

    private func restoreLevelProgress() {
        guard let profile = currentProfile else { return }

        // Restore math level stars
        for (level, stars) in profile.mathProgress {
            if let index = mathLevels.firstIndex(where: { $0.id == level }) {
                mathLevels[index].starsEarned = stars
            }
        }

        // Restore math level unlock status from persisted state
        for levelId in profile.mathUnlockedLevels {
            if let index = mathLevels.firstIndex(where: { $0.id == levelId }) {
                mathLevels[index].isUnlocked = true
            }
        }

        // Restore reading level stars
        for (level, stars) in profile.readingProgress {
            if let index = readingLevels.firstIndex(where: { $0.id == level }) {
                readingLevels[index].starsEarned = stars
            }
        }

        // Restore reading level unlock status from persisted state
        for levelId in profile.readingUnlockedLevels {
            if let index = readingLevels.firstIndex(where: { $0.id == levelId }) {
                readingLevels[index].isUnlocked = true
            }
        }

        // Restore shapes level stars
        for (level, stars) in profile.shapesProgress {
            if let index = shapesLevels.firstIndex(where: { $0.id == level }) {
                shapesLevels[index].starsEarned = stars
            }
        }

        // Restore shapes level unlock status from persisted state
        for levelId in profile.shapesUnlockedLevels {
            if let index = shapesLevels.firstIndex(where: { $0.id == levelId }) {
                shapesLevels[index].isUnlocked = true
            }
        }
    }

    private func saveCurrentProfile() {
        guard let profile = currentProfile,
              let persisted = persistedProfiles.first(where: { $0.profileId == profile.id }) else { return }
        persisted.update(from: profile)
        saveContext()
        profiles = persistedProfiles.map { $0.toChildProfile() }
        markSyncActivity()
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

        // Update level stars (unlocking is now handled via Ready Check)
        switch subject {
        case .math:
            if let index = mathLevels.firstIndex(where: { $0.id == level }) {
                let newStars = max(mathLevels[index].starsEarned, stars)
                mathLevels[index].starsEarned = newStars
                profile.mathProgress[level] = newStars
            }
        case .reading:
            if let index = readingLevels.firstIndex(where: { $0.id == level }) {
                let newStars = max(readingLevels[index].starsEarned, stars)
                readingLevels[index].starsEarned = newStars
                profile.readingProgress[level] = newStars
            }
        case .shapes:
            if let index = shapesLevels.firstIndex(where: { $0.id == level }) {
                let newStars = max(shapesLevels[index].starsEarned, stars)
                shapesLevels[index].starsEarned = newStars
                profile.shapesProgress[level] = newStars
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
        case .shapes: return shapesLevels
        }
    }

    /// Unlock the next level after passing Ready Check
    /// - Parameters:
    ///   - subject: The subject (math, reading, or shapes)
    ///   - level: The current level ID that was just passed (next level will be unlocked)
    func unlockNextLevel(subject: Subject, level: Int) {
        guard var profile = currentProfile else { return }

        let nextLevelId = level + 1

        switch subject {
        case .math:
            // Update in-memory levels array
            if let index = mathLevels.firstIndex(where: { $0.id == nextLevelId }) {
                mathLevels[index].isUnlocked = true
            }
            // Persist to profile
            profile.mathUnlockedLevels.insert(nextLevelId)

        case .reading:
            // Update in-memory levels array
            if let index = readingLevels.firstIndex(where: { $0.id == nextLevelId }) {
                readingLevels[index].isUnlocked = true
            }
            // Persist to profile
            profile.readingUnlockedLevels.insert(nextLevelId)

        case .shapes:
            // Update in-memory levels array
            if let index = shapesLevels.firstIndex(where: { $0.id == nextLevelId }) {
                shapesLevels[index].isUnlocked = true
            }
            // Persist to profile
            profile.shapesUnlockedLevels.insert(nextLevelId)
        }

        currentProfile = profile
        saveCurrentProfile()
    }

    // MARK: - Garden Data Access

    /// Fetches all mastery items for the current profile and subject
    /// Returns GardenItems for visualization in the garden view
    /// Also returns the level ID for each item to enable direct navigation
    func getGardenItems(for subject: Subject) -> [GardenItem] {
        guard let profileId = currentProfile?.id else {
            appStateLogger.debug("getGardenItems: No current profile")
            return []
        }

        guard let modelContext = _modelContext else {
            appStateLogger.warning("getGardenItems: ModelContext not initialized")
            return []
        }

        let subjectString = subject == .math ? "math" : "reading"

        let predicate = #Predicate<ItemMastery> { item in
            item.profileId == profileId &&
            item.subject == subjectString
        }

        var descriptor = FetchDescriptor<ItemMastery>(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.itemId)]

        do {
            let items = try modelContext.fetch(descriptor)
            return items.map { mastery in
                // Extract a display label from the itemId
                let label = extractLabel(from: mastery.itemId, subject: subject)
                return GardenItem(
                    id: mastery.itemId,
                    label: label,
                    stage: mastery.growthStage,
                    itemId: mastery.itemId,
                    levelId: mastery.levelId
                )
            }
        } catch {
            appStateLogger.error("Error fetching garden items for \(subject.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return []
        }
    }

    /// Extracts a user-friendly label from an item ID
    private func extractLabel(from itemId: String, subject: Subject) -> String {
        // Item IDs are like "count_3_stars", "letter_A", etc.
        if subject == .math {
            // Try to extract number from math item IDs
            let components = itemId.split(separator: "_")
            if components.count >= 2, let number = Int(components[1]) {
                return "\(number)"
            }
        } else {
            // Try to extract letter from reading item IDs
            let components = itemId.split(separator: "_")
            if components.count >= 2 {
                return String(components[1]).uppercased()
            }
        }
        return itemId
    }

    /// Gets count of plants that need watering (wilting or significantly overdue)
    func getPlantsNeedingWater(for subject: Subject) -> Int {
        let items = getGardenItems(for: subject)
        return items.filter { $0.stage == .wilting }.count
    }

    /// Gets total plants needing water across all subjects
    func getTotalPlantsNeedingWater() -> Int {
        getPlantsNeedingWater(for: .math) + getPlantsNeedingWater(for: .reading)
    }

    /// Gets mastery statistics for a subject
    func getMasteryStats(for subject: Subject) -> MasteryStats {
        guard let profileId = currentProfile?.id else {
            appStateLogger.debug("getMasteryStats: No current profile")
            return MasteryStats(totalItems: 0, masteredItems: 0, strugglingItems: 0, dueForReview: 0, overallAccuracy: 0)
        }

        guard let modelContext = _modelContext else {
            appStateLogger.warning("getMasteryStats: ModelContext not initialized")
            return MasteryStats(totalItems: 0, masteredItems: 0, strugglingItems: 0, dueForReview: 0, overallAccuracy: 0)
        }

        let subjectString = subject == .math ? "math" : "reading"
        return SpacedRepetitionManager.shared.getMasteryStats(
            profileId: profileId,
            subject: subjectString,
            modelContext: modelContext
        )
    }

    // MARK: - Time Limit Management

    var timeLimitEnabled: Bool {
        parentSettings?.timeLimitEnabled ?? false
    }

    var dailyTimeLimitMinutes: Int {
        parentSettings?.dailyTimeLimitMinutes ?? 30
    }

    var remainingTimeSeconds: Int {
        let limitSeconds = dailyTimeLimitMinutes * 60
        return max(0, limitSeconds - todayUsageSeconds)
    }

    var remainingTimeFormatted: String {
        let minutes = remainingTimeSeconds / 60
        let seconds = remainingTimeSeconds % 60
        if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    func setTimeLimit(enabled: Bool, minutes: Int? = nil) {
        parentSettings?.timeLimitEnabled = enabled
        if let minutes = minutes {
            parentSettings?.dailyTimeLimitMinutes = minutes
        }
        saveContext()
        objectWillChange.send()

        // Check if limit is now reached
        if enabled {
            checkTimeLimit()
        } else {
            isTimeLimitReached = false
        }
    }

    func startTimeTracking() {
        // Load today's usage from UserDefaults
        loadTodayUsage()

        // Check if already over limit
        if timeLimitEnabled {
            checkTimeLimit()
        }

        // Start timer to track usage every second
        usageTimer?.invalidate()
        usageTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.incrementUsage()
        }
    }

    func stopTimeTracking() {
        usageTimer?.invalidate()
        usageTimer = nil
        saveTodayUsage()
    }

    private func loadTodayUsage() {
        let defaults = UserDefaults.standard
        let savedDate = defaults.string(forKey: usageDateKey) ?? ""
        let today = formattedDate(Date())

        if savedDate == today {
            // Same day, restore usage
            todayUsageSeconds = defaults.integer(forKey: usageKey)
        } else {
            // New day, reset usage
            todayUsageSeconds = 0
            defaults.set(today, forKey: usageDateKey)
            defaults.set(0, forKey: usageKey)
        }
    }

    private func saveTodayUsage() {
        let defaults = UserDefaults.standard
        defaults.set(formattedDate(Date()), forKey: usageDateKey)
        defaults.set(todayUsageSeconds, forKey: usageKey)
    }

    private func incrementUsage() {
        todayUsageSeconds += 1

        // Save periodically (every 10 seconds)
        if todayUsageSeconds % 10 == 0 {
            saveTodayUsage()
        }

        // Check limit
        if timeLimitEnabled {
            checkTimeLimit()
        }
    }

    private func checkTimeLimit() {
        let limitSeconds = dailyTimeLimitMinutes * 60
        let wasReached = isTimeLimitReached
        isTimeLimitReached = todayUsageSeconds >= limitSeconds

        // Navigate to break screen if just reached
        if isTimeLimitReached && !wasReached && currentScreen != .settings {
            navigateTo(.timeForBreak)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func resetDailyUsage() {
        todayUsageSeconds = 0
        isTimeLimitReached = false
        saveTodayUsage()
    }
}
