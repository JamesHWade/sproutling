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
   ✅ Must see `** BUILD SUCCEEDED **`

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

**MVVM pattern with SwiftUI:**

- **Models** (`Models/Models.swift`): Data structures - `Screen` (navigation enum), `Subject`, `LessonLevel`, `ActivityCard`, `ActivityType`, `ChildProfile`
- **ViewModel** (`ViewModels/AppState.swift`): Single `AppState` ObservableObject injected via `.environmentObject()` - manages navigation, progress, levels
- **Views**: Screens, Components, and Activities

**State Management:**
- `AppState` is created in `SproutlingApp` and injected as environment object
- `LessonState` (local to `LessonView`) manages per-lesson state
- Navigation via `appState.currentScreen` enum switching

**Navigation Flow:**
```
HomeScreen → SubjectScreen (level selection) → LessonView (activities) → LessonCompleteScreen
```

## Activity System

Six activity types across two subjects:

**Math** (`Views/Activities/MathActivities.swift`):
- `numberWithObjects` - Show objects, reveal number
- `numberMatching` - Match object count to number
- `countingTouch` - Tap to count

**Reading** (`Views/Activities/ReadingActivities.swift`):
- `letterCard` - Progressive reveal: letter → sound → word
- `letterMatching` - Match word to starting letter
- `phonicsBlending` - Sequential letter sounds to word

Activities are rendered in `LessonView` based on `ActivityCard.activityType`.

## Key Patterns

**Adding lesson content:**
- Math cards: `LessonState.createMathCards()` in `Views/Screens/LessonView.swift`
- Reading cards: `LessonState.createReadingCards()` in `Views/Screens/LessonView.swift`

**Adding sounds:**
- Add .mp3 to Resources, add case to `SoundEffect` enum, call `SoundManager.shared.playSound()`

**Reusable components** in `Views/Components/Components.swift`:
- `SproutlingNavBar`, `ProgressBar`, `StarReward`, `MascotView`, `ConfettiView`
- Button styles: `PrimaryButtonStyle`, `NumberOptionButton`, `LetterOptionButton`

**Animations:** Spring-based (`.spring(response: 0.3-0.5)`), staggered delays for sequences

**Haptics:** Via `HapticFeedback` struct - `.light()`, `.medium()`, `.success()`, `.error()`

## Design System

- Math: Blue-to-purple gradient (`Subject.math.gradient`)
- Reading: Pink-to-orange gradient (`Subject.reading.gradient`)
- Standard shadow: `.shadow(color: .black.opacity(0.1), radius: 8, y: 4)`
- All screens have `#Preview` sections for Xcode canvas testing
