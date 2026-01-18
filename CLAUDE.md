# Agent Instructions

This project uses **bd** (beads) for issue tracking. Run `bd onboard` to get started.

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Workflow

### Quick Commands

```bash
# Build (fast check for compile errors)
xcodebuild -project Sproutling.xcodeproj -scheme Sproutling -sdk iphonesimulator build

# Build for specific device
xcodebuild -project Sproutling.xcodeproj -scheme Sproutling -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests (when tests exist)
xcodebuild -project Sproutling.xcodeproj -scheme Sproutling -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15' test

# Clean build (use when seeing stale artifacts)
xcodebuild -project Sproutling.xcodeproj -scheme Sproutling clean
```

### Quality Gates (Run Before Committing)

**Always run these checks after making code changes:**

1. **Build check** - Ensures code compiles without errors:
   ```bash
   xcodebuild -project Sproutling.xcodeproj -scheme Sproutling -sdk iphonesimulator build 2>&1 | tail -5
   ```
   Must see `** BUILD SUCCEEDED **`

2. **SwiftLint** (if installed) - Code style consistency:
   ```bash
   swiftlint lint --path Sproutling/
   ```

3. **Tests** (when available):
   ```bash
   xcodebuild test -project Sproutling.xcodeproj -scheme Sproutling \
     -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

### Development Workflow

1. **Before starting work:**
   - Run a build to ensure clean baseline
   - Check `bd ready` for available issues

2. **While developing:**
   - Build frequently (after each significant change)
   - Use Xcode previews (`#Preview`) for UI iteration
   - Test on simulator for interaction/sound verification

3. **Before committing:**
   - Run full build
   - Run tests (if available)
   - Verify app launches on simulator

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails with stale errors | `xcodebuild clean` then rebuild |
| "No such module" errors | Close Xcode, delete DerivedData, rebuild |
| Simulator not found | `xcrun simctl list devices` to see available |
| Code signing errors | Build for simulator only (no signing needed) |

```bash
# Nuclear option - clear all derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Sproutling-*
```

### Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- No external dependencies (pure SwiftUI + AVFoundation + SwiftData)

## Architecture

### MVVM Pattern with SwiftUI

**Models** (`Models/`):
- `Models.swift` - Core data structures: `Screen`, `Subject`, `LessonLevel`, `ActivityCard`, `ActivityType`, `ChildProfile`, `ProfileAvatar`, `ProfileBackground`, `MascotEmotion`
- `PersistedProfile.swift` - SwiftData model for profile persistence with CloudKit sync
- `ParentSettings.swift` - SwiftData model for app settings (PIN requirement, time limits, sound/haptics)

**ViewModel** (`ViewModels/AppState.swift`):
- Single `AppState` ObservableObject injected via `.environmentObject()`
- Manages navigation, multi-profile support, PIN verification, time limit tracking
- Handles SwiftData persistence and CloudKit sync

**Views** (`Views/`):
- `Screens/` - Full-screen views for each app state
- `Components/` - Reusable UI components
- `Activities/` - Activity-specific views for lessons

**Utilities** (`Utilities/`):
- `SoundManager.swift` - Audio playback and haptic feedback
- `KeychainManager.swift` - Secure PIN storage in iOS Keychain
- `CurriculumLoader.swift` - Loads lesson content from JSON files

### State Management

- `AppState` is created in `SproutlingApp` and injected as environment object
- `LessonState` (local to `LessonView`) manages per-lesson state
- Navigation via `appState.currentScreen` enum switching
- Profile data persisted via SwiftData with iCloud sync
- Daily usage tracked via UserDefaults (resets each day)

### Navigation Flow

```
ProfileSelectionScreen (if multiple profiles)
    ↓
HomeScreen → ProgressScreen
    ↓           SettingsScreen
SubjectScreen (level selection)
    ↓
LessonView (activities)
    ↓
LessonCompleteScreen
    ↓
TimeForBreakScreen (if time limit reached)
```

### Data Persistence

**SwiftData (with CloudKit sync):**
- `PersistedProfile` - Child profiles with progress, avatars, streaks
- `ParentSettings` - Time limits, sound/haptics toggles, PIN requirement flag

**Keychain:**
- Parent PIN (4-digit, stored securely via `KeychainManager`)

**UserDefaults:**
- Daily usage tracking (seconds used today, resets daily)

**JSON Files:**
- `MathCurriculum.json` - Math lesson content (6 levels, numbers 1-20)
- `ReadingCurriculum.json` - Reading lesson content (6 levels, A-Z)

## Activity System

Nine activity types across two subjects:

**Math** (`Views/Activities/MathActivities.swift`):
- `numberWithObjects` - Show objects, reveal number
- `numberMatching` - Match object count to number
- `countingTouch` - Tap to count objects
- `subitizing` - Quick recognition of quantities (1-5)
- `comparison` - Compare two groups (more/less/same)

**Reading** (`Views/Activities/ReadingActivities.swift`):
- `letterCard` - Progressive reveal: letter → sound → word
- `letterMatching` - Match word to starting letter
- `phonicsBlending` - Sequential letter sounds to word
- `vocabularyCard` - Picture + word vocabulary building

Activities are loaded from JSON curriculum files and rendered in `LessonView` based on `ActivityCard.type`.

## Key Patterns

### Adding Lesson Content

Edit the JSON curriculum files in `Sproutling/Resources/`:
- `MathCurriculum.json` - Add math cards with `type`, `number`, `objects`, etc.
- `ReadingCurriculum.json` - Add reading cards with `type`, `letter`, `word`, `emoji`, `sound`

The `CurriculumLoader` handles parsing and provides fallback content if JSON fails.

### Adding Sounds

Add `.mp3` to Resources, add case to `SoundEffect` enum, call `SoundManager.shared.playSound()`

### Reusable Components

`Views/Components/Components.swift`:
- `SproutlingNavBar`, `ProgressBar`, `StarReward`, `MascotView`, `ConfettiView`
- Button styles: `PrimaryButtonStyle`, `NumberOptionButton`, `LetterOptionButton`

`Views/Components/ProfileComponents.swift`:
- `ProfileCard`, `AvatarPicker`, `BackgroundPicker`

### Animations

Spring-based (`.spring(response: 0.3-0.5)`), staggered delays for sequences

### Haptics

Via `HapticFeedback` struct - `.light()`, `.medium()`, `.success()`, `.error()`

## Design System

- Math: Blue-to-purple gradient (`Subject.math.gradient`)
- Reading: Pink-to-orange gradient (`Subject.reading.gradient`)
- Standard shadow: `.shadow(color: .black.opacity(0.1), radius: 8, y: 4)`
- All screens have `#Preview` sections for Xcode canvas testing

### Profile Customization

- **Avatars**: 50+ emoji options in 5 categories (Animals, Fantasy, Nature, Food, Space)
- **Backgrounds**: 25 gradient options in 5 families (Warm, Cool, Vibrant, Pastel, Dark)

## Parent Controls

### PIN Protection
- 4-digit PIN stored in Keychain via `KeychainManager`
- Required to access Settings and Profile Management when enabled
- Session-based verification (locks when navigating away)

### Time Limits
- Configurable daily limit: 5, 10, 15, 20, 30, 45, or 60 minutes
- Visual countdown in home screen header
- `TimeForBreakScreen` shown when limit reached
- Resets daily at midnight
