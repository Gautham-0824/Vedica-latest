# Vedica (native iOS)

Every screen is SwiftUI. Only the lesson animations are HTML, shown in a `WKWebView`.

## Run it

1. Unzip, then open `Vedica.xcodeproj` in Xcode 16 or newer.
2. Choose an iPad or iPhone simulator and press **Cmd+R**.
3. For a real device: select the Vedica target, open **Signing & Capabilities**, choose your Team, and change the bundle identifier from `com.example.vedica` to your own.

Needs iOS 17 or newer. Lessons need an internet connection the first time they load (see below).

## Project layout

| Folder | Contents |
| --- | --- |
| `Vedica/App` | App entry point |
| `Vedica/Views` | Name, sign-in, slides, Home, Lessons, tier lists, module sheet, Quizzes, Progress, Profile, Practice/Quiz, Results |
| `Vedica/Components` | Theme, fonts, adaptive canvas, buttons, icons, scratch pad |
| `Vedica/Models` | Lesson catalog, quiz and practice questions |
| `Vedica/ViewModels` | `AppNavigator` (screen flow), `WorkSession` (practice and quiz logic) |
| `Vedica/Services` | `ProgressStore` (saved progress, streaks, reminders), Sign in with Apple, handwriting recognition |
| `Vedica/WebView` | `LessonWebView` (reusable `UIViewRepresentable`) and `LessonScreen` |
| `Vedica/Resources` | Nunito and DM Sans fonts, app icon and colours |
| `Lessons` | The HTML lesson files |

## Portrait and landscape

Both work on iPad and iPhone, and the layout changes live when you rotate. Landscape uses the artifact's 1024 x 768 layout. The artifact has no portrait design, so portrait layouts are new: the same components rearranged (2-column stats, 2-row keypad, stacked Results and Profile). Screens and lessons fill the whole window at any size, including iPad split-window sizes.

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
- **iPhone text is small**, because a tablet layout is scaled down to fit. Lessons are clearer in landscape on iPhone.
- **The Basics pulse** on the Lessons screen was removed on request, so that circle no longer moves.
- **Narration** uses the device's speech voice, so it can differ between devices.
- **Reset prototype** is kept from the artifact on the Progress screen. Remove it before release.
