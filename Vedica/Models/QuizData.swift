import Foundation

/// Quiz and practice questions. Owned by the Quiz owner (see CLAUDE.md).
enum QuizData {
    static let ids = ["frac", "sq5", "x11", "x9", "mix"]
    static let quizzes: [String: [Question]] = [
        "frac": [.f(1, 3, 1, 4), .f(2, 5, 1, 2), .f(3, 5, 1, 4), .f(3, 4, 2, 3), .f(1, 6, 3, 5)],
        "x11": [.mul(23, 11), .mul(45, 11), .mul(78, 11), .mul(32, 101), .mul(56, 101)],
        "sq5": [.mul(25, 25), .mul(45, 45), .mul(65, 65), .mul(75, 75), .mul(95, 95)],
        "x9": [.mul(47, 9), .mul(36, 99), .mul(58, 99), .mul(124, 999), .mul(462, 999)],
        "mix": [.f(1, 2, 1, 3), .mul(55, 55), .mul(64, 11), .mul(43, 99), .f(2, 3, 1, 5), .mul(27, 101), .mul(318, 999)],
    ]
    /// "Practice time": two problems on your own after the lesson, before the quiz.
    static let practice: [String: [Question]] = [
        "frac": [.f(2, 3, 1, 4), .f(1, 2, 2, 5)],
        "sq5": [.mul(45, 45), .mul(75, 75)],
    ]
    static let names = ["frac": "Unlike fractions", "sq5": "Squaring 2-digit numbers ending in 5", "x11": "Multiply by 11 and 101",
                        "x9": "Multiply by 9, 99 and 999", "mix": "Mixed review"]
    static let doneLines = ["frac": "Badge earned: Crosswise.", "sq5": "Badge earned: Fives.", "x11": "Badge earned: Elevens.",
                            "x9": "Badge earned: Nines.", "mix": "You\u{2019}ve reviewed every Basics sutra."]
    static func questions(_ id: String) -> [Question] { quizzes[id] ?? quizzes["frac"]! }
}
