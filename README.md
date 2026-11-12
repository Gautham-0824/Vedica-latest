# Vedica (native iOS)

Every screen is SwiftUI, built on native containers (`TabView`, `NavigationStack`, `fullScreenCover`, `.sheet`, `.alert`, `List`). Only the lesson animations are HTML, shown in a `WKWebView`.

## Run it

1. Unzip, then open `Vedica.xcodeproj` in Xcode 16 or newer.
2. Choose an iPad or iPhone simulator and press **Cmd+R**.
3. For a real device: select the Vedica target, open **Signing & Capabilities**, choose your Team, and change the bundle identifier from `com.example.vedica` to your own.

Needs iOS 18 or newer. Lessons need an internet connection the first time they load (see below).

## Project layout

| Folder | Contents |
| --- | --- |
| `Vedica/App` | App entry point |
| `Vedica/Views` | Name, sign-in, slides, Home, Lessons, tier lists, module sheet, Quizzes, Progress, Profile, Practice/Quiz, Results |
| `Vedica/Components` | Theme, fonts, window metrics, buttons, icons, scratch pad |
| `Vedica/Models` | Lesson catalog, quiz and practice questions |
| `Vedica/ViewModels` | `AppNavigator` (tab, stack, cover and sheet state), `WorkSession` (practice and quiz logic) |
| `Vedica/Services` | `ProgressStore` (saved progress, streaks, reminders), Sign in with Apple, handwriting recognition |
| `Vedica/WebView` | `LessonWebView` (reusable `UIViewRepresentable`) and `LessonScreen` |
| `Vedica/Resources` | Nunito and DM Sans fonts, app icon and colours |
| `Lessons` | The HTML lesson files |

## Navigation

| Part of the app | Native container |
| --- | --- |
| Home, Lessons, Quiz, Progress | `TabView` (iOS 18 `Tab` API). The system tab bar is hidden; the design's tab pill selects the tab. |
| Lessons > Basics / Intermediate / Advanced | `NavigationStack` with `NavigationLink(value:)`. The system nav bar is hidden; the round back button pops. |
| Name > Sign in > Intro slides | `NavigationStack` |
| Lesson, Practice/Quiz, Results, Profile | One `fullScreenCover`; moving between them keeps the sideways slide |
| Choose a module | `.sheet` sized to its content (`presentationSizing(.fitted)`, height detent on iPhone) |
| Delete Account | `.alert` |
| Profile settings | Inset-grouped `List` with a real navigation bar |

## Layout and scale

Screens use real adaptive layout (stacks, grids, scroll views, safe areas) instead of one fixed canvas scaled to fit. Sizes in the code are design points; `pt(_:)` scales them by `Metrics.shared.k`:

- **iPad:** `k` equals the scale the old fixed 1024 x 768 canvas had, so iPad looks the same as before.
- **iPhone and narrow split views:** `k` is at least 0.75, so text is larger and easier to read than before. Narrow windows stack cards, put the tab pill under the logo, and use a two-row keypad.
- **Landscape iPhone:** Practice/Quiz scrolls, because the screen is too short for it.

The app stays in light mode with the status bar hidden, as before.

## Typing with a keyboard

Number keys, Delete and Return work on Practice, Quiz and lesson questions. Tab or an arrow key switches between the top and bottom boxes. In the Simulator, turn on **I/O > Keyboard > Connect Hardware Keyboard** first.

## How lessons talk to the app

Pages open with `?native=1` and send messages through `WKScriptMessageHandler` under the name `vedica`:

- `exit`: the lesson's close button
- `continue`: the lesson's own Continue button
- `done`: a stand-alone lesson page finished
- `resume:{...}`: the saved step

## What could not be fully migrated

- **Lessons load React and two helper libraries from the internet.** The lesson pages use unpkg.com, as agreed, so a first load with no connection will not show a lesson.
- **Sign in with Apple and iCloud sync need a paid Apple Developer team.** Add both capabilities under Signing & Capabilities. Without them, the app runs, saves progress on the device, and Sign in with Apple shows a "didn't finish" message.
- **Help, Privacy and Terms links** point to placeholder `vedica.app` addresses. Replace them in `Views/ProfileView.swift`.
- **Intro slide pictures** were empty boxes in the artifact, so they use simple SF Symbol illustrations.
- **Lessons on iPhone** are still the HTML lessons drawn for a 1024 x 768 canvas, so they are clearer in landscape.
- **The Basics pulse** on the Lessons screen was removed on request, so that circle no longer moves.
- **Narration** uses the device's speech voice, so it can differ between devices.
- **Reset prototype** is kept from the artifact on the Progress screen. Remove it before release.
