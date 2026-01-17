# Sproutling - Interactive Flashcard App for Kids

An iOS flashcard app designed for children ages 2-4, built with SwiftUI and research-based pedagogical practices.

## Features

### 📚 Two Learning Tracks

**Numbers & Counting (Math)**
- Number recognition with visual objects
- Counting practice with tap interaction
- Number matching games
- Progressive difficulty (1-5, then 6-10)

**Letters & Phonics (Reading)**
- Letter recognition with phonetic sounds
- Letter-to-word associations
- Phonics blending (C-A-T → CAT)
- Systematic synthetic phonics approach

### 🎮 Engaging Learning Experience

- **Colorful, playful design** optimized for young children
- **Multi-sensory learning** with visual, audio, and haptic feedback
- **Positive reinforcement only** - celebrations for success, gentle encouragement for retries
- **Progressive reveal** - scaffolded learning that builds confidence
- **Star reward system** - earn up to 3 stars per lesson
- **Streak tracking** - encourages daily learning habits

### 🧠 Research-Based Pedagogy

Built following evidence-based early childhood education principles:

1. **Concrete-to-Abstract Learning** - counting real objects before showing numerals
2. **Learning Trajectories** - activities matched to child's developmental level
3. **Multi-sensory Engagement** - visual, auditory, and tactile feedback
4. **Systematic Synthetic Phonics** - proven method for early reading
5. **Parent Co-Play Design** - designed for adult supervision per AAP guidelines

## Project Structure

```
Sproutling/
├── SproutlingApp.swift          # App entry point
├── Models/
│   └── Models.swift           # Data models (Subject, ActivityCard, etc.)
├── ViewModels/
│   └── AppState.swift         # App state management
├── Views/
│   ├── Components/
│   │   └── Components.swift   # Reusable UI components
│   ├── Screens/
│   │   ├── HomeScreen.swift
│   │   ├── SubjectScreen.swift
│   │   ├── LessonView.swift
│   │   └── LessonCompleteScreen.swift
│   └── Activities/
│       ├── MathActivities.swift
│       └── ReadingActivities.swift
├── Utilities/
│   └── SoundManager.swift     # Audio & haptics
└── Resources/
    └── Assets.xcassets
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

4. **Add app icon** (optional)
   - Add a 1024x1024 image to `Assets.xcassets/AppIcon.appiconset`

## Customization

### Adding New Content

**Math Activities:**
Edit `LessonState.createMathCards()` in `LessonView.swift`:
```swift
ActivityCard(type: .numberWithObjects, number: 6, objects: "stars")
```

**Reading Activities:**
Edit `LessonState.createReadingCards()` in `LessonView.swift`:
```swift
ActivityCard(type: .letterCard, letter: "E", word: "Elephant", emoji: "🐘", sound: "eh")
```

### Adding Sound Effects

1. Add `.mp3` files to the Resources folder
2. Reference them in `SoundManager.swift`:
```swift
SoundManager.shared.playSound(.correct)
```

### Customizing Child Profile

Edit `ChildProfile.sample` in `Models.swift`:
```swift
ChildProfile(name: "Your Child's Name", totalStars: 0, streakDays: 0, ...)
```

## Architecture

- **MVVM Pattern** - Clean separation of Views, ViewModels, and Models
- **SwiftUI** - Declarative UI with native iOS animations
- **@StateObject / @EnvironmentObject** - Reactive state management
- **Haptic Feedback** - UIImpactFeedbackGenerator for tactile response

## Future Enhancements

- [ ] Data persistence with SwiftData
- [ ] Parent dashboard with progress reports
- [ ] More activity types (tracing, coloring)
- [ ] Audio pronunciations with AVSpeechSynthesizer
- [ ] Difficulty adaptation based on performance
- [ ] Additional subjects (shapes, colors, simple math)

## Credits

Built with pedagogical guidance from:
- NAEYC (National Association for the Education of Young Children)
- Research on systematic synthetic phonics
- Khan Academy Kids design principles

---

Made with ❤️ for little learners
