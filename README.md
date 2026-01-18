# Sproutling - Interactive Learning App for Kids

An iOS educational app designed for children ages 2-4, built with SwiftUI and research-based pedagogical practices.

## Features

### Two Learning Tracks

**Numbers & Counting (Math)**
- Number recognition with visual objects (1-20)
- Counting practice with tap interaction
- Number matching games
- Subitizing (quick quantity recognition)
- Comparison activities (more/less/same)
- Six progressive levels

**Letters & Phonics (Reading)**
- Letter recognition with phonetic sounds
- Letter-to-word associations
- Phonics blending (C-A-T → CAT)
- Vocabulary building
- Systematic synthetic phonics approach
- Six progressive levels (A-Z)

### Multi-Profile Support

- Create multiple child profiles
- Customizable avatars (50+ emoji options in 5 categories)
- 25 gradient backgrounds organized by color family
- Independent progress tracking per profile
- iCloud sync across devices
- Profile switching from home screen

### Parent Controls

- **PIN Protection**: 4-digit PIN secures settings and profile management (stored in Keychain)
- **Daily Time Limits**: Configurable 5-60 minute screen time limits
- **Time Tracking**: Visual countdown timer in header
- **"Time for Break" Screen**: Friendly break screen when limit reached
- **Sound & Haptics Toggles**: Control audio and haptic feedback

### Engaging Learning Experience

- Colorful, playful design optimized for young children
- Multi-sensory learning with visual, audio, and haptic feedback
- Positive reinforcement only - celebrations for success, gentle encouragement for retries
- Progressive reveal - scaffolded learning that builds confidence
- Star reward system - earn up to 3 stars per lesson
- Streak tracking - encourages daily learning habits
- Confetti animations for achievements

### Progress Tracking

- Detailed progress screen with per-subject breakdown
- Star counts per level
- Overall completion percentage
- Learning streak display
- Total stars earned

## Project Structure

```
Sproutling/
├── SproutlingApp.swift              # App entry point
├── Models/
│   ├── Models.swift                 # Core data models
│   ├── PersistedProfile.swift       # SwiftData profile persistence
│   └── ParentSettings.swift         # Parent settings model
├── ViewModels/
│   └── AppState.swift               # Main app state management
├── Views/
│   ├── Components/
│   │   ├── Components.swift         # Reusable UI components
│   │   └── ProfileComponents.swift  # Profile-specific components
│   ├── Screens/
│   │   ├── HomeScreen.swift         # Main landing screen
│   │   ├── SubjectScreen.swift      # Level selection
│   │   ├── LessonView.swift         # Activity delivery
│   │   ├── LessonCompleteScreen.swift
│   │   ├── ProgressScreen.swift     # Progress tracking
│   │   ├── SettingsScreen.swift     # Parent settings
│   │   ├── ProfileSelectionScreen.swift
│   │   ├── ProfileManagementScreen.swift
│   │   ├── ProfileEditorSheet.swift
│   │   ├── ParentPINSheet.swift     # PIN entry/setup
│   │   └── TimeForBreakScreen.swift # Time limit reached
│   └── Activities/
│       ├── MathActivities.swift     # Math activity views
│       └── ReadingActivities.swift  # Reading activity views
├── Utilities/
│   ├── SoundManager.swift           # Audio & haptics
│   ├── KeychainManager.swift        # Secure PIN storage
│   └── CurriculumLoader.swift       # JSON curriculum loader
└── Resources/
    ├── Assets.xcassets
    ├── MathCurriculum.json          # Math lesson content
    └── ReadingCurriculum.json       # Reading lesson content
```

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup Instructions

1. **Open the project**
   ```bash
   open Sproutling.xcodeproj
   ```

2. **Select a simulator or device**
   - iPhone 14/15 recommended for best experience
   - iPad also supported

3. **Build and run**
   - Press `Cmd + R` or click the Play button

## Customization

### Adding Curriculum Content

Edit the JSON curriculum files in the Resources folder:

**MathCurriculum.json:**
```json
{
  "subject": "math",
  "levels": [
    {
      "id": 1,
      "title": "Numbers 1-3",
      "subtitle": "Learn to count!",
      "cards": [
        { "type": "numberWithObjects", "number": 1, "objects": "apples" }
      ]
    }
  ]
}
```

**ReadingCurriculum.json:**
```json
{
  "subject": "reading",
  "levels": [
    {
      "id": 1,
      "title": "Letters A-D",
      "subtitle": "First letters!",
      "cards": [
        { "type": "letterCard", "letter": "A", "word": "Apple", "emoji": "🍎", "sound": "ah" }
      ]
    }
  ]
}
```

### Adding Sound Effects

1. Add `.mp3` files to the Resources folder
2. Reference them in `SoundManager.swift`

## Architecture

- **MVVM Pattern** - Clean separation of Views, ViewModels, and Models
- **SwiftUI** - Declarative UI with native iOS animations
- **SwiftData** - Profile and settings persistence with iCloud sync
- **Keychain** - Secure PIN storage
- **@StateObject / @EnvironmentObject** - Reactive state management
- **JSON Curriculum** - Externalized lesson content for easy updates

## Research Foundation

Built following evidence-based early childhood education principles:

1. **Concrete-to-Abstract Learning** - Counting real objects before showing numerals
2. **Learning Trajectories** - Activities matched to child's developmental level
3. **Multi-sensory Engagement** - Visual, auditory, and tactile feedback
4. **Systematic Synthetic Phonics** - Proven method for early reading
5. **Parent Co-Play Design** - Designed for adult supervision per AAP guidelines

## Credits

Built with pedagogical guidance from:
- NAEYC (National Association for the Education of Young Children)
- Research on systematic synthetic phonics
- Khan Academy Kids design principles

---

Made with love for little learners
