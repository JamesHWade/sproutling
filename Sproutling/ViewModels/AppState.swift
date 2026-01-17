//
//  AppState.swift
//  Sproutling
//
//  Main app state management
//

import Foundation
import SwiftUI
import SwiftData

class AppState: ObservableObject {
    @Published var currentScreen: Screen = .home
    @Published var childProfile: ChildProfile = .sample
    @Published var mathLevels: [LessonLevel] = LessonLevel.mathLevels()
    @Published var readingLevels: [LessonLevel] = LessonLevel.readingLevels()

    private var modelContext: ModelContext?
    private var persistedProfile: PersistedProfile?

    // MARK: - Persistence Setup

    func setupPersistence(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadProfile()
    }

    private func loadProfile() {
        guard let modelContext = modelContext else { return }

        let descriptor = FetchDescriptor<PersistedProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []

        if let existing = profiles.first {
            persistedProfile = existing
            // Update streak based on last session
            existing.updateStreak()
            childProfile = existing.toChildProfile()
            // Restore level progress
            restoreLevelProgress()
        } else {
            // Create new profile
            let newProfile = PersistedProfile()
            newProfile.updateStreak()
            modelContext.insert(newProfile)
            persistedProfile = newProfile
            childProfile = newProfile.toChildProfile()
        }

        saveProfile()
    }

    private func restoreLevelProgress() {
        // Restore math level stars and unlock status
        for (level, stars) in childProfile.mathProgress {
            if let index = mathLevels.firstIndex(where: { $0.id == level }) {
                mathLevels[index].starsEarned = stars
                // Unlock next level if earned at least 1 star
                if stars >= 1 && index + 1 < mathLevels.count {
                    mathLevels[index + 1].isUnlocked = true
                }
            }
        }

        // Restore reading level stars and unlock status
        for (level, stars) in childProfile.readingProgress {
            if let index = readingLevels.firstIndex(where: { $0.id == level }) {
                readingLevels[index].starsEarned = stars
                if stars >= 1 && index + 1 < readingLevels.count {
                    readingLevels[index + 1].isUnlocked = true
                }
            }
        }
    }

    private func saveProfile() {
        guard let persistedProfile = persistedProfile else { return }
        persistedProfile.update(from: childProfile)
        try? modelContext?.save()
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

    func selectSubject(_ subject: Subject) {
        navigateTo(.subjectSelection(subject))
    }

    func startLesson(subject: Subject, level: Int) {
        navigateTo(.lesson(subject, level))
    }

    func completeLesson(subject: Subject, level: Int, stars: Int) {
        // Update progress
        childProfile.totalStars += stars

        // Update level stars
        switch subject {
        case .math:
            if let index = mathLevels.firstIndex(where: { $0.id == level }) {
                let newStars = max(mathLevels[index].starsEarned, stars)
                mathLevels[index].starsEarned = newStars
                childProfile.mathProgress[level] = newStars
                // Unlock next level if earned at least 1 star
                if stars >= 1 && index + 1 < mathLevels.count {
                    mathLevels[index + 1].isUnlocked = true
                }
            }
        case .reading:
            if let index = readingLevels.firstIndex(where: { $0.id == level }) {
                let newStars = max(readingLevels[index].starsEarned, stars)
                readingLevels[index].starsEarned = newStars
                childProfile.readingProgress[level] = newStars
                if stars >= 1 && index + 1 < readingLevels.count {
                    readingLevels[index + 1].isUnlocked = true
                }
            }
        }

        // Persist progress
        saveProfile()

        navigateTo(.lessonComplete(subject, stars))
    }

    func levels(for subject: Subject) -> [LessonLevel] {
        switch subject {
        case .math: return mathLevels
        case .reading: return readingLevels
        }
    }
}
