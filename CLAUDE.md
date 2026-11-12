# Vedica: notes for Claude Code

Vedica is an iPad-first (also iPhone) SwiftUI app that teaches Vedic maths. The lessons are HTML/React pages shown in a `WKWebView`. Everything else is SwiftUI. Open `Vedica.xcodeproj` (Xcode 16+, iOS 18 deployment target). The `Vedica/` folder is a file-system-synchronized group, so new `.swift` files are picked up automatically.

## Current state

The app is built on native SwiftUI containers. It builds and runs in Xcode 27 (iPhone and iPad simulators). Apple's own tab bar is used: bottom on iPhone, top on iPad.

### Rules the owner set: don't change these
- **The appearance must not change.** Keep the fonts (Nunito and DM Sans, loaded from bundled woff2 in `Theme.swift`), the colours (`Theme`), the cards, shadows and corner radii, the logo and avatar header (`TabHeader`), Apple's tab bar (bottom on iPhone, top on iPad, level with the logo), and the round back buttons. Native containers are fine underneath, but they must not change the look.
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
1. Build after every change; the app must build with no errors.
2. The tab bar: bottom on iPhone, top on iPad in line with the logo. Don't move it.
3. The module sheet's size on iPad (`presentationSizing(.fitted)`) and its height detent on iPhone.
4. The lesson map position (`LessonsScreen.placement`) in landscape, portrait and on iPhone.
5. This flow: Home → Start → lesson → Continue to practice → quiz → Results → Review → back to Results → Continue.
6. Practice/Quiz layout on iPhone: two-row keypad, caption above the buttons, and scrolling in landscape.
7. Profile's nav bar fonts and list row heights should match the old look (iOS Settings style).

## Team, branches and file ownership (read before editing anything)

Repo: https://github.com/Gautham-0824/Vedica-latest (default branch `main`, protected: changes land only through a pull request that Gautham approves and merges).

Each person has ONE working branch and edits ONLY the files they own. If a fix needs a file someone else owns, stop and tell the user who to ask. Never edit another person's files, never push to `main`, never force-push.

| Person | Branch | Owns (may edit) |
| --- | --- | --- |
| Gautham | `advanced-lessons` | Advanced lessons in `Lessons/lessons/`: `binomials.html`, `equations-ratio.html`, `verify-expansion.html`, `two-digit-mult.html`, `completing-cube.html`, `swapped-coeff.html`, `equations-fractions.html`, `algebraic-division.html`, `simultaneous-eq.html`. Also owner/reviewer of everything nobody else owns (shared Swift files, `Lessons/support.js`, `Lessons/vedica-ink.js`, `Lessons/vendor/`, this file). |
| Muskan | `basics-lessons` | Basics lessons: `Lessons/Vedica Fraction Lesson.dc.html` (Adding Unlike Fractions), `Lessons/Vedica Multiply Lesson.dc.html` (Squaring ending in 5, ×11, ×101, ×9, ×99, ×999; only the Basics scripts `sq5 m11 m101 m9 m99 m999 x11 x9`), and in `Lessons/lessons/`: `digit-sum-check.html`, `same-sum-zero.html`, `cube-roots.html`, `three-digit-mult.html`. |
| Nandini | `intermediate-lessons` | Intermediate lessons: `Lessons/Vedica Intermediate Multiply Lesson.dc.html` (only the `rd` Recurring Decimals and `dv` Dividing Near a Base scripts), and in `Lessons/lessons/`: `last-digits-10.html`, `divisibility-7.html`, `squares-50-100.html`, `yavadunam.html`, `divisibility-13.html`, `divisibility-17.html`. |
| Ramya | `quiz-screen` | The Quiz tab and quiz flow in SwiftUI: `Vedica/Views/QuizzesView.swift`, `Vedica/Views/WorkView.swift`, `Vedica/Views/ResultsView.swift`, `Vedica/ViewModels/WorkSession.swift`, `Vedica/Models/QuizData.swift`, and any new files she adds under `Vedica/Views/Quiz/`. |

Lesson owners: "guided learning" and "practice" live inside each lesson's HTML page, so lesson work only touches your own HTML files. The design, fonts and animations must not change.

Daily routine on your branch:
1. `git switch <your-branch>` then `git pull origin main` (gets everyone's merged work).
2. Make changes, build, test on an iPhone AND an iPad simulator, portrait and landscape.
3. Commit with a clear message, `git push origin <your-branch>`, and open (or update) a pull request into `main`.
4. After Gautham merges your PR, run `git pull origin main` again before continuing.

Commits must use an email that is on your GitHub account (GitHub → Settings → Emails), otherwise they don't count as contributions.

## How the owner works
The owner tests by hand in the Simulator or on a device, mostly looking at the lessons, and then sends feedback in plain words. For each piece of feedback:
- Find the cause in the code first, then make the smallest change that fixes it while keeping the look the same.
- Build after every change (`xcodebuild -project Vedica.xcodeproj -scheme Vedica -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M4)' build`, or whichever simulator is installed) and fix any errors before reporting back.
- If the feedback is about a lesson's content or animation, the change goes in the HTML file under `Lessons/` (see `Catalog.page(_:)` for which file belongs to which lesson). Swift only hosts the lesson.
- Explain changes simply. Ask before any big restructure.
