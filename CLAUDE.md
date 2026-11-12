# Vedica: notes for Claude Code

Vedica is an iPad-first (also iPhone) SwiftUI app that teaches Vedic maths. The lessons are HTML/React pages shown in a `WKWebView`. Everything else is SwiftUI. Open `Vedica.xcodeproj` (Xcode 16+, iOS 18 deployment target). The `Vedica/` folder is a file-system-synchronized group, so new `.swift` files are picked up automatically.

## Current state (branch `feat/swiftui-native`, PR #1)

This branch rebuilds the app on native SwiftUI containers. It was written on Windows and **has never been compiled or run**. The first job is to build it, fix compile errors, and then test it by hand.

### Rules the owner set: don't change these
- **The appearance must not change.** Keep the fonts (Nunito and DM Sans, loaded from bundled woff2 in `Theme.swift`), the colours (`Theme`), the cards, shadows and corner radii, the top tab pill (`TabHeader`), and the round back buttons. Native containers are fine underneath, but they must not change the look.
- Light mode only (`.preferredColorScheme(.light)`), with the status bar hidden. Don't add Dark Mode.
- The lessons stay HTML in a `WKWebView` (`Vedica/WebView/LessonWebView.swift`, files in `Lessons/`). Don't port them to SwiftUI unless asked.
- Minimum iOS 18.
- Work on branches and PRs. Don't push straight to `main`.

### Architecture
- `ViewModels/AppNavigator.swift`: all navigation state. `tab` (`AppTab`), `lessonsPath: [Tier]`, `onboardingPath: [OnboardingStep]`, `flow: Flow?` (what the full-screen cover shows), `sheet` (module sheet id) and `toast`. Use `show(_ flow:)` to open or move within the cover, `closeFlow()` to close it, and `select(_ tab:)`.
- `Views/RootView.swift`:
  - `RootView`: onboarding or tabs, plus a single `.fullScreenCover` → `FlowView`.
  - `MainTabs`: `TabView` (iOS 18 `Tab` API), with the system tab bar hidden through `.hiddenTabBar()` and `.tabViewStyle(.tabBarOnly)`. The Lessons tab holds a `NavigationStack` → `TierScreen`. The module picker is a `.sheet(item:)`.
  - `OnboardingFlow`: a `NavigationStack` that goes Name → Account → Showcase.
  - `FlowView`: switches between Lesson, Work, Results and Profile, with a sideways slide transition.
  - `TabHeader`: the design's logo, tab pill and avatar.
  - The file also holds `ToastView` and View helpers: `.at(x,y)`, `.cardShadow()`, `.hiddenTabBar()`, `.hiddenNavBar()` and `.screenBackground()`.
- `Components/Theme.swift`:
  - `Metrics.shared` holds live window size, `k`, `w`/`h` in design points, and the `portrait`, `compact`, `short` and `wide` flags. `AdaptiveRoot` updates it.
  - `pt(_:)` scales a design-point value by `k`. **Every size in the views is a design point wrapped in `pt()`.** `Theme.round` and `Theme.text` already apply `pt` to font sizes, and so do `Icon`, `RoundIconButton`, `VedicaLogo` and `AvatarView`.
  - On iPad, `k = min(long/1024, short/768)`, which is exactly the old fixed-canvas scale, so iPad should look like the old build. On iPhone, `k` is never below 0.75.
- Screens: `HomeView`, `LessonsViews` (lesson map, `TierScreen`, `ModuleSheet`, `StatusDot`), `OnboardingViews`, `QuizzesView`, `ProgressScreen`, `ProfileView` (a real `NavigationStack` toolbar and an inset-grouped `List`), `WorkView` (Practice/Quiz with keypad, handwriting `InkBox` and `ScratchPanel`) and `ResultsView`.
- `Services/ProgressStore.swift` holds the saved state (UserDefaults plus iCloud key-value storage), streaks and reminders. `WorkSession` holds the practice and quiz logic. `InkRecognizer` does handwriting recognition. `KeyCatcher` handles hardware-keyboard input.
- Lessons talk to the app through the `vedica` `WKScriptMessageHandler` with the messages `exit`, `continue`, `done` and `resume:{...}`. The injected JS also resizes the lesson's own 1024×768 canvas to fit the window.

### Known risks to check first
1. Compile errors anywhere (the code has never been built).
2. The system tab bar must stay hidden on iPadOS 18. It must not appear as a floating bar at the top.
3. The module sheet's size on iPad (`presentationSizing(.fitted)`) and its height detent on iPhone.
4. The lesson map position (`LessonsScreen.placement`) in landscape, portrait and on iPhone.
5. This flow: Home → Start → lesson → Continue to practice → quiz → Results → Review → back to Results → Continue.
6. Practice/Quiz layout on iPhone: two-row keypad, caption above the buttons, and scrolling in landscape.
7. Profile's nav bar fonts and list row heights should match the old look (iOS Settings style).

## How the owner works
The owner tests by hand in the Simulator or on a device, mostly looking at the lessons, and then sends feedback in plain words. For each piece of feedback:
- Find the cause in the code first, then make the smallest change that fixes it while keeping the look the same.
- Build after every change (`xcodebuild -project Vedica.xcodeproj -scheme Vedica -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build`, or whichever simulator is installed) and fix any errors before reporting back.
- If the feedback is about a lesson's content or animation, the change goes in the HTML file under `Lessons/` (see `Catalog.page(_:)` for which file belongs to which lesson). Swift only hosts the lesson.
- Explain changes simply. Ask before any big restructure.
