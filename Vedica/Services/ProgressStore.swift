import SwiftUI
import Observation
import UserNotifications
import WebKit

struct TimeRec: Codable, Equatable {
    var last: Int
    var best: Int
    var prevBest: Int?
}

struct QuizPoint: Codable {
    var date: Date
    var percent: Int
}

/// Everything the app remembers. Saved locally, and to iCloud key-value storage when sync is on.
struct SavedState: Codable {
    var name = ""
    var onboarded = false
    var avatar = 0
    var signedIn = false
    var joined = Date()
    var status: [String: Status] = [:]
    var resume: [String: Int] = [:]
    var scores: [String: Int] = [:]
    var times: [String: TimeRec] = [:]
    var history: [QuizPoint] = []
    var activity: [String: Int] = [:]
    var quizAnswered = 0
    var quizMs = 0
    /// Lessons open with narration on unless it is turned off in Profile.
    var narrationOn = true
    var icloud = true
    var haptics = true
    var remOn = true
    var rem = 1050          // minutes after midnight
    var session = 15
    /// Set when onboarding finishes; Home shows a tapping finger on Start until it is tapped.
    var showTapHint = false

    init() {}

    /// Missing keys keep their defaults, so progress saved by an older version still loads.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SavedState()
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? d.name
        onboarded = try c.decodeIfPresent(Bool.self, forKey: .onboarded) ?? d.onboarded
        avatar = try c.decodeIfPresent(Int.self, forKey: .avatar) ?? d.avatar
        signedIn = try c.decodeIfPresent(Bool.self, forKey: .signedIn) ?? d.signedIn
        joined = try c.decodeIfPresent(Date.self, forKey: .joined) ?? d.joined
        status = try c.decodeIfPresent([String: Status].self, forKey: .status) ?? d.status
        resume = try c.decodeIfPresent([String: Int].self, forKey: .resume) ?? d.resume
        scores = try c.decodeIfPresent([String: Int].self, forKey: .scores) ?? d.scores
        times = try c.decodeIfPresent([String: TimeRec].self, forKey: .times) ?? d.times
        history = try c.decodeIfPresent([QuizPoint].self, forKey: .history) ?? d.history
        activity = try c.decodeIfPresent([String: Int].self, forKey: .activity) ?? d.activity
        quizAnswered = try c.decodeIfPresent(Int.self, forKey: .quizAnswered) ?? d.quizAnswered
        quizMs = try c.decodeIfPresent(Int.self, forKey: .quizMs) ?? d.quizMs
        narrationOn = try c.decodeIfPresent(Bool.self, forKey: .narrationOn) ?? d.narrationOn
        icloud = try c.decodeIfPresent(Bool.self, forKey: .icloud) ?? d.icloud
        haptics = try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? d.haptics
        remOn = try c.decodeIfPresent(Bool.self, forKey: .remOn) ?? d.remOn
        rem = try c.decodeIfPresent(Int.self, forKey: .rem) ?? d.rem
        session = try c.decodeIfPresent(Int.self, forKey: .session) ?? d.session
        showTapHint = try c.decodeIfPresent(Bool.self, forKey: .showTapHint) ?? d.showTapHint
    }
}

@MainActor
@Observable
final class ProgressStore {
    var s: SavedState { didSet { persist() } }

    private static let key = "vedica.state.v2"
    private static let days: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        if let d = UserDefaults.standard.data(forKey: Self.key), let v = try? JSONDecoder().decode(SavedState.self, from: d) {
            s = v
        } else {
            s = SavedState()
        }
        NotificationCenter.default.addObserver(forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                                               object: NSUbiquitousKeyValueStore.default, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.pullFromCloud() }
        }
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    private func persist() {
        guard let d = try? JSONEncoder().encode(s) else { return }
        UserDefaults.standard.set(d, forKey: Self.key)
        if s.icloud { NSUbiquitousKeyValueStore.default.set(d, forKey: Self.key) }
    }

    private func pullFromCloud() {
        guard s.icloud, let d = NSUbiquitousKeyValueStore.default.data(forKey: Self.key),
              let v = try? JSONDecoder().decode(SavedState.self, from: d) else { return }
        s = v
    }

    // MARK: lessons

    /// A lesson or module; families (x11, x9) roll up from their modules.
    func status(_ id: String) -> Status {
        guard let subs = Catalog.subs[id] else { return s.status[id] ?? .new }
        let v = subs.map { s.status[$0.id] ?? .new }
        if v.allSatisfy({ $0 == .done }) { return .done }
        return v.contains { $0 != .new } ? .progress : .new
    }
    func begin(_ id: String) { if status(id) != .done { s.status[id] = .progress } }
    func complete(_ id: String) { s.status[id] = .done; s.resume[id] = nil }

    func doneCount(_ t: Tier) -> Int { Catalog.items(t).filter { status($0.id) == .done }.count }
    var basicsDone: Int { doneCount(.basics) }
    var basicsTotal: Int { Catalog.basics.count }

    /// How far into the next sutra you are, 0...1.
    func progress(_ id: String) -> Double {
        if status(id) == .done { return 1 }
        if id == "frac" { return min(Double(s.resume[id] ?? 0) / 5, 0.95) }
        if id == "sq5" { return min(Double(s.resume[id] ?? 0) / 12, 0.95) }
        if let subs = Catalog.subs[id] { return Double(subs.filter { s.status[$0.id] == .done }.count) / Double(subs.count) }
        return status(id) == .progress ? 0.5 : 0
    }

    // MARK: activity

    static func dayKey(_ d: Date) -> String { days.string(from: d) }
    /// Practice time is counted in memory and saved every 30 seconds, not every second: saving rewrites all
    /// progress and redraws the screen, which made Practice and Quiz lag.
    @ObservationIgnored private var unsaved = 0
    func addActivity(_ seconds: Int) {
        unsaved += seconds
        if unsaved >= 30 { flushActivity() }
    }
    func flushActivity() {
        guard unsaved > 0 else { return }
        let n = unsaved
        unsaved = 0
        s.activity[Self.dayKey(Date()), default: 0] += n
    }
    func seconds(on d: Date) -> Int {
        (s.activity[Self.dayKey(d)] ?? 0) + (Self.dayKey(d) == Self.dayKey(Date()) ? unsaved : 0)
    }
    var minutesToday: Int { seconds(on: Date()) / 60 }

    var streak: Int {
        let cal = Calendar.current
        var d = Date()
        if seconds(on: d) == 0 { d = cal.date(byAdding: .day, value: -1, to: d) ?? d }
        var n = 0
        while seconds(on: d) > 0 {
            n += 1
            d = cal.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return n
    }

    /// Questions per minute across every quiz answer, nil before the first quiz.
    var speed: Double? {
        guard s.quizAnswered > 0, s.quizMs > 0 else { return nil }
        return (Double(s.quizAnswered) / (Double(s.quizMs) / 60000) * 10).rounded() / 10
    }

    /// Monday-to-Sunday of the current week: day letter and whether you practised.
    var week: [(letter: String, on: Bool)] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return Array("MTWTFSS").enumerated().map { i, c in
            (String(c), seconds(on: cal.date(byAdding: .day, value: i, to: start) ?? start) > 0)
        }
    }
    var weekSeconds: Int {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        let start = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return (0..<7).reduce(0) { $0 + seconds(on: cal.date(byAdding: .day, value: $1, to: start) ?? start) }
    }

    func recordAnswer(ms: Int) {
        s.quizAnswered += 1
        s.quizMs += ms
    }

    func recordQuiz(_ id: String, score: Int, total: Int, ms: Int) {
        s.scores[id] = score
        let prev = s.times[id]
        s.times[id] = TimeRec(last: ms, best: prev.map { min($0.best, ms) } ?? ms, prevBest: prev?.best)
        s.history.append(QuizPoint(date: Date(), percent: total > 0 ? score * 100 / total : 0))
    }

    var earned: [Bool] { ["frac", "sq5", "x11", "x9"].map { status($0) == .done } }
    var trimmedName: String { s.name.trimmingCharacters(in: .whitespaces) }

    func clock(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        return "\(((h + 11) % 12) + 1):\(String(format: "%02d", m)) \(h < 12 ? "AM" : "PM")"
    }

    // MARK: reminder + account

    func scheduleReminder() {
        let c = UNUserNotificationCenter.current()
        c.removePendingNotificationRequests(withIdentifiers: ["daily"])
        guard s.remOn else { return }
        let hour = s.rem / 60, minute = s.rem % 60
        c.requestAuthorization(options: [.alert, .sound]) { ok, _ in
            guard ok else { return }
            let content = UNMutableNotificationContent()
            content.title = "Time for Vedica"
            content.body = "A few minutes of practice keeps your streak going."
            var when = DateComponents()
            when.hour = hour
            when.minute = minute
            c.add(UNNotificationRequest(identifier: "daily", content: content,
                                        trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: true)))
        }
    }

    /// Wipes local data, the iCloud copy and the lessons' web storage.
    func deleteEverything() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily"])
        NSUbiquitousKeyValueStore.default.removeObject(forKey: Self.key)
        WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) {}
        s = SavedState()
    }
}

func clockText(_ ms: Int) -> String { let s = ms / 1000; return "\(s / 60):\(String(format: "%02d", s % 60))" }
func secsText(_ ms: Double) -> String { ms < 60000 ? "\((ms / 100).rounded() / 10) s" : clockText(Int(ms)) }

enum Haptics {
    static func success(_ on: Bool) { if on { UINotificationFeedbackGenerator().notificationOccurred(.success) } }
    static func error(_ on: Bool) { if on { UINotificationFeedbackGenerator().notificationOccurred(.error) } }
}
