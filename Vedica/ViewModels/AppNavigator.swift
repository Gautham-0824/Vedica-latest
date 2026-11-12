import SwiftUI
import Observation

/// The four tabs.
enum AppTab: Hashable, CaseIterable {
    case home, lessons, quizzes, progress

    var title: String {
        switch self {
        case .home: return "Home"
        case .lessons: return "Lessons"
        case .quizzes: return "Quiz"
        case .progress: return "Progress"
        }
    }
    var symbol: String {
        switch self {
        case .home: return "house"
        case .lessons: return "book"
        case .quizzes: return "checklist"
        case .progress: return "chart.bar"
        }
    }
}

/// Screens pushed on the onboarding `NavigationStack` after the name screen.
enum OnboardingStep: Hashable { case account, showcase }

/// Screens shown full screen over the tabs (one `fullScreenCover` that moves between them).
enum Flow: Hashable {
    case lesson(String, start: Int, review: Bool)
    case work, results, profile
}

/// Identifies the module sheet (x11 or x9) for `.sheet(item:)`.
struct ModuleSheetID: Identifiable, Hashable { var id: String }

/// App-wide navigation and shared state, following the artifact's screen flow.
/// Tabs, stacks and covers are native SwiftUI containers; this only holds their state.
@MainActor
@Observable
final class AppNavigator {
    let store = ProgressStore()
    let work = WorkSession()

    var tab = AppTab.home
    var lessonsPath: [Tier] = []
    var onboardingPath: [OnboardingStep] = []
    /// What the full-screen cover shows; nil when it is closed.
    var flow: Flow?
    /// The last flow shown, so the cover keeps its content while it slides away.
    private(set) var shownFlow = Flow.profile
    /// Direction of the slide between flow screens.
    var forward = true
    var toast = ""
    var sheet: String?                // "x11" or "x9" module sheet
    /// True while a new user is in the lesson opened from the last intro slide.
    var firstLesson = false
    private var toastTask: Task<Void, Never>?

    static let slide = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.55)

    // MARK: tabs and flows

    func select(_ t: AppTab) {
        sheet = nil
        tab = t
    }

    private func rank(_ f: Flow) -> Int {
        switch f {
        case .lesson: return 0
        case .work: return 1
        case .results: return 2
        case .profile: return 3
        }
    }

    /// Opens the cover, or moves within it with the artifact's slide when it is already open.
    func show(_ f: Flow, forward fw: Bool? = nil) {
        sheet = nil
        if flow == nil {
            forward = true
            shownFlow = f
            flow = f
        } else {
            forward = fw ?? (rank(f) >= rank(shownFlow))
            withAnimation(Self.slide) {
                shownFlow = f
                flow = f
            }
        }
    }

    func closeFlow() { flow = nil }

    func openProfile() { show(.profile) }

    func flash(_ msg: String) {
        withAnimation { toast = msg }
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if !Task.isCancelled { withAnimation { self?.toast = "" } }
        }
    }

    // MARK: onboarding

    func finishOnboarding() {
        store.s.onboarded = true
        store.s.showTapHint = true
        store.s.joined = Date()
        // Start Learning goes to Home, where a finger shows the new user where to tap.
        tab = .home
        lessonsPath = []
        onboardingPath = []
    }

    // MARK: lessons

    func tapCard(_ id: String) {
        if Catalog.subs[id] != nil {
            sheet = id
        } else {
            openLesson(id)
        }
    }

    func openLesson(_ id: String) {
        // A lesson already under way reopens where it was left, not at its start.
        let at = store.status(id) == .progress ? (store.s.resume[id] ?? 0) : 0
        store.begin(id)
        sheet = nil
        show(.lesson(id, start: at, review: false))
    }

    func nextLessonTapped() {
        store.s.showTapHint = false
        guard let n = Catalog.basics.first(where: { store.status($0.id) != .done }) else {
            tab = .lessons
            lessonsPath = [.basics]
            return
        }
        if let subs = Catalog.subs[n.id] {
            openLesson((subs.first { store.status($0.id) != .done } ?? subs[0]).id)
        } else {
            openLesson(n.id)
        }
    }

    /// The lesson page finished: mark it, then follow the artifact's flow.
    func lessonFinished(_ id: String) {
        switch Catalog.after(id) {
        case .practice: work.beginPractice(id); show(.work)
        case .quiz(let fam): store.complete(id); startQuiz(fam, fromQuizzes: false)
        case .list: store.complete(id); lessonExit(id)
        }
    }

    func lessonExit(_ id: String) {
        if firstLesson { firstLesson = false; tab = .home; closeFlow(); return }
        tab = .lessons
        lessonsPath = [Catalog.tier(of: id)]
        closeFlow()
        if let fam = Catalog.family(of: id) {
            // Reopen the module sheet once the cover has slid away.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 600_000_000)
                self.sheet = fam
            }
        }
    }

    // MARK: practice and quiz

    func startQuiz(_ id: String, fromQuizzes: Bool) {
        work.beginQuiz(id, fromQuizzes: fromQuizzes)
        show(.work)
    }

    /// Back from Practice time goes to the lesson's last step, never its start.
    func workBack() {
        if work.mode == .practice {
            let id = work.id
            show(.lesson(id, start: id == "frac" ? 5 : 12, review: false), forward: false)
        } else {
            closeQuiz()
        }
    }

    func closeQuiz() {
        if firstLesson {
            firstLesson = false
            tab = .home
        } else if work.fromQuizzes {
            tab = .quizzes
        } else {
            tab = .lessons
            lessonsPath = [.basics]
        }
        closeFlow()
    }

    func showResults() {
        let z = work
        store.recordQuiz(z.id, score: z.score, total: z.questions.count, ms: z.totalMs)
        if z.id == "frac" || z.id == "sq5" { store.complete(z.id) }
        show(.results)
    }

    func reset() {
        store.deleteEverything()
        flow = nil
        sheet = nil
        tab = .home
        lessonsPath = []
        onboardingPath = []
    }
}
