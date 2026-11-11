import SwiftUI
import Observation

enum AnswerBox { case top, bot }
enum Part { case top, bot, both }
enum AnsStatus { case none, ok, bad }
enum WorkMode { case practice, quiz }

struct AnswerRecord {
    var question: Question
    var top: String, bot: String
    var ok: Bool
    var part: Part?
    var ms: Int
}

private let praises = ["Nice!", "Great job!", "Well done!", "Brilliant!", "Spot on!", "You got it!"]

/// Practice time and quizzes share one screen; this drives both.
@MainActor
@Observable
final class WorkSession {
    var mode = WorkMode.quiz
    var id = "frac"
    var fromQuizzes = false
    var questions: [Question] = QuizData.questions("frac")
    var index = 0
    var top = ""
    var bot = ""
    var active = AnswerBox.top
    var status = AnsStatus.none
    var part: Part?
    var hint = false
    var records: [AnswerRecord] = []
    var shake: CGFloat = 0
    var filling = false           // quiz auto-next fill on the action button
    var started = Date()
    /// When question 1 appeared: the quiz clock runs from here across every question.
    var quizStarted = Date()
    var padStrokes: [[CGPoint]] = []
    private var auto: Task<Void, Never>?

    var q: Question { questions[min(index, questions.count - 1)] }
    var quiz: Bool { mode == .quiz }
    var isLast: Bool { index >= questions.count - 1 }
    var score: Int { records.filter(\.ok).count }
    var totalMs: Int { records.reduce(0) { $0 + $1.ms } }
    var locked: Bool { status == .ok || (quiz && status != .none) }
    var ready: Bool { q.isFraction ? (!top.isEmpty && !bot.isEmpty) : !top.isEmpty }
    var praise: String { praises[index % praises.count] }

    func beginPractice(_ lesson: String) {
        mode = .practice; id = lesson; fromQuizzes = false
        questions = QuizData.practice[lesson] ?? []
        restart()
    }

    func beginQuiz(_ quizId: String, fromQuizzes f: Bool) {
        mode = .quiz; id = quizId; fromQuizzes = f
        questions = QuizData.questions(quizId)
        restart()
    }

    func restart() {
        index = 0; records = []
        blank()
        quizStarted = started
    }

    private func blank() {
        stopAuto()
        top = ""; bot = ""; active = .top; status = .none; part = nil; hint = false; padStrokes = []
        started = Date()
    }

    func setBox(_ b: AnswerBox) {
        guard !locked else { return }
        active = q.isFraction ? b : .top
    }

    func append(_ s: String, to box: AnswerBox? = nil) {
        guard !locked else { return }
        if status == .bad { status = .none; part = nil; if active == .top { top = "" } else { bot = "" } }
        let b = q.isFraction ? (box ?? active) : .top
        active = b
        let cur = b == .top ? top : bot
        let n = String((cur + s).prefix(q.isFraction ? 3 : 6))
        if b == .top { top = n } else { bot = n }
        // Once the top of a fraction is right, move straight on to the bottom box.
        if q.isFraction && b == .top && Int(top) == q.solNum { active = .bot }
    }

    func del() {
        guard !locked else { return }
        if status == .bad { status = .none; part = nil }
        if active == .top { top = String(top.dropLast()) } else { bot = String(bot.dropLast()) }
    }

    func check(store: ProgressStore) {
        let t = Int(top) ?? 0, b = Int(bot) ?? 0
        var ok: Bool
        var p: Part?
        if !q.isFraction {
            ok = t == q.solNum
        } else {
            ok = b > 0 && t * q.solDen == q.solNum * b
            if !ok { p = b == q.solDen ? .top : (t == q.solNum ? .bot : .both) }
        }
        status = ok ? .ok : .bad
        part = p
        ok ? Haptics.success(store.s.haptics) : Haptics.error(store.s.haptics)
        if !ok { shakeIt() }
        if quiz {
            let ms = Int(Date().timeIntervalSince(started) * 1000)
            records.append(AnswerRecord(question: q, top: top, bot: bot, ok: ok, part: p, ms: ms))
            store.recordAnswer(ms: ms)
        }
    }

    private func shakeIt() {
        Task { @MainActor in
            for x: CGFloat in [-12, 10, -7, 5, 0] {
                withAnimation(.easeInOut(duration: 0.06)) { shake = x }
                try? await Task.sleep(nanoseconds: 60_000_000)
            }
        }
    }

    /// Five seconds after a quiz answer, moves on by itself.
    func startAuto(_ fire: @escaping () -> Void) {
        stopAuto()
        auto = Task { @MainActor in
            // A beat later, so the button is on screen before its fill starts.
            try? await Task.sleep(nanoseconds: 60_000_000)
            if Task.isCancelled { return }
            withAnimation(.linear(duration: 5)) { filling = true }
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if !Task.isCancelled { fire() }
        }
    }

    func stopAuto() {
        auto?.cancel()
        auto = nil
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { filling = false }
    }

    func nextQuestion() {
        index += 1
        blank()
    }
}
