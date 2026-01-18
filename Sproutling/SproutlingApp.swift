//
//  SproutlingApp.swift
//  Sproutling
//
//  Interactive Flashcard App for Kids (Ages 2-4)
//  Built with research-based pedagogical practices
//

import SwiftUI
import SwiftData

@main
struct SproutlingApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PersistedProfile.self,
            ParentSettings.self
        ])

        // Configure CloudKit sync for private database
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.sproutling.app")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    appState.setupPersistence(modelContext: sharedModelContainer.mainContext)
                }
        }
    }
}

// MARK: - Content View (Main Navigation)
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            switch appState.currentScreen {
            case .home:
                HomeScreen()
                    .transition(reduceMotion ? .opacity : .opacity)

            case .progress:
                ProgressScreen()
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))

            case .settings:
                SettingsScreen()
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))

            case .subjectSelection(let subject):
                SubjectScreen(subject: subject)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))

            case .lesson(let subject, let level):
                LessonView(subject: subject, level: level)
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))

            case .lessonComplete(let subject, let stars):
                LessonCompleteScreen(subject: subject, stars: stars)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))

            case .profileSelection:
                ProfileSelectionScreen()
                    .transition(reduceMotion ? .opacity : .opacity)

            case .profileManagement:
                ProfileManagementScreen()
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: appState.currentScreen)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
