import SwiftUI
import Observation

enum Route: Hashable {
    case name, account, showcase(Int)
    case home, lessons, tier(Tier), quizzes, progress, profile
    case lesson(String, start: Int, review: Bool)
    case work, results
}

/// App-wide navigation and shared state, following the artifact's screen flow.
@MainActor
@Observable
final class AppNavigator {
    let store = ProgressStore()
    let work = WorkSession()
    var route: Route
    var forward = true
    var toast = ""
    var sheet: String?                // "x11" or "x9" module sheet
    var profileFrom: Route = .home
    /// True while a new user is in the lesson opened from the last intro slide.
    var firstLesson = false
    private var toastTask: Task<Void, Never>?

    init() {
        route = store.s.onboarded ? .home : .name
    }

    private func rank(_ r: Route) -> Int {
        switch r {
        case .name: return 0
        case .account: return 1
        case .showcase(let i): return 2 + i
        case .home: return 10
        case .lessons, .quizzes: return 11
        case .progress, .tier: return 12
        case .lesson: return 13
        case .work: return 14
        case .results: return 15
        case .profile: return 20
        }
    }

    func go(_ r: Route, forward f: Bool? = nil) {
        forward = f ?? (rank(r) >= rank(route))
        withAnimation(.timingCurve(0.32, 0.72, 0, 1, duration: 0.55)) { route = r }
    }

    func flash(_ msg: String) {
        withAnimation { toast = msg }
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            if !Task.isCancelled { withAnimation { self?.toast = "" } }
        }
    }

    // MARK: lessons

    func tapCard(_ id: String) {
        if Catalog.subs[id] != nil {
            withAnimation(.easeOut(duration: 0.26)) { sheet = id }
        } else {
            openLesson(id)
        }
    }

    func openLesson(_ id: String) {
        // A lesson already under way reopens where it was left, not at its start.
        let at = store.status(id) == .progress ? (store.s.resume[id] ?? 0) : 0
        store.begin(id)
        sheet = nil
        go(.lesson(id, start: at, review: false))
    }

    func nextLessonTapped() {
        store.s.showTapHint = false
        guard let n = Catalog.basics.first(where: { store.status($0.id) != .done }) else { go(.tier(.basics)); return }
        if let subs = Catalog.subs[n.id] {
            openLesson((subs.first { store.status($0.id) != .done } ?? subs[0]).id)
        } else {
            openLesson(n.id)
        }
    }

    /// The lesson page finished: mark it, then follow the artifact's flow.
    func lessonFinished(_ id: String) {
        switch Catalog.after(id) {
        case .practice: work.beginPractice(id); go(.work)
        case .quiz(let fam): store.complete(id); startQuiz(fam, fromQuizzes: false)
        case .list: store.complete(id); lessonExit(id)
        }
    }

    func lessonExit(_ id: String) {
        if firstLesson { firstLesson = false; go(.home, forward: false); return }
        go(.tier(Catalog.tier(of: id)), forward: false)
        if let fam = Catalog.family(of: id) {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 420_000_000)
                withAnimation(.easeOut(duration: 0.26)) { self.sheet = fam }
            }
        }
    }

    // MARK: practice and quiz

    func startQuiz(_ id: String, fromQuizzes: Bool) {
        work.beginQuiz(id, fromQuizzes: fromQuizzes)
        go(.work)
    }

    /// Back from Practice time goes to the lesson's last step, never its start.
    func workBack() {
        if work.mode == .practice {
            let id = work.id
            go(.lesson(id, start: id == "frac" ? 5 : 12, review: false), forward: false)
        } else {
            closeQuiz()
        }
    }

    func closeQuiz() {
        if firstLesson { firstLesson = false; go(.home, forward: false); return }
        go(work.fromQuizzes ? .quizzes : .tier(.basics), forward: false)
    }

    func showResults() {
        let z = work
        store.recordQuiz(z.id, score: z.score, total: z.questions.count, ms: z.totalMs)
        if z.id == "frac" || z.id == "sq5" { store.complete(z.id) }
        go(.results)
    }

    func reset() {
        store.deleteEverything()
        go(.name, forward: false)
    }
}
