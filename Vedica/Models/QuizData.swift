import Foundation

/// One quiz or practice question.
///
/// Three shapes cover every lesson in the app:
/// * `.fraction` — `a/b + c/d`, answered in two boxes;
/// * `.times` — `x × m` (or `x²` when both sides match), one box;
/// * `.expr` — any other prompt written out, e.g. `(x+3)(x+4)` or `1234 ÷ 98`, one box.
///
/// `note` is the short line that says what to hand back ("cube root", "coefficient of x"),
/// so an expression question is never ambiguous.
struct QuizQ: Equatable {
    enum Shape: Equatable { case fraction, times, expr }

    var shape = Shape.times
    var a = 0, b = 1, c = 0, d = 1      // fraction question
    var x = 0, m = 0                    // times question
    var prompt = ""                     // expression question
    var note = ""                       // what the answer should be
    var num = 0, den = 1                // the answer

    static func f(_ a: Int, _ b: Int, _ c: Int, _ d: Int) -> QuizQ {
        QuizQ(shape: .fraction, a: a, b: b, c: c, d: d, num: a * d + c * b, den: b * d)
    }
    static func mul(_ x: Int, _ m: Int) -> QuizQ {
        QuizQ(shape: .times, x: x, m: m, num: x * m)
    }
    static func e(_ prompt: String, _ note: String, _ answer: Int) -> QuizQ {
        QuizQ(shape: .expr, prompt: prompt, note: note, num: answer)
    }

    var isFraction: Bool { shape == .fraction }
    var solNum: Int { num }
    var solDen: Int { den }

    /// What the problem looks like written on one line (used in the results list).
    var text: String {
        switch shape {
        case .fraction: return "\(a)/\(b) + \(c)/\(d)"
        case .times: return x == m ? "\(x)\u{00B2}" : "\(x) \u{00D7} \(m)"
        case .expr: return note.isEmpty ? prompt : "\(prompt)  \u{2192}  \(note)"
        }
    }
    var answer: String { isFraction ? "\(num)/\(den)" : "\(num)" }

    /// Read out by VoiceOver.
    var spoken: String {
        switch shape {
        case .fraction: return "\(a) over \(b) plus \(c) over \(d)"
        case .times: return x == m ? "\(x) squared" : "\(x) times \(m)"
        case .expr: return note.isEmpty ? prompt : "\(prompt), give the \(note)"
        }
    }
}

/// Every quiz in the app: one per lesson, plus a mixed review for each tier.
/// Owned by the Quiz owner (see CLAUDE.md).
enum QuizData {

    // MARK: the quizzes

    static let quizzes: [String: [QuizQ]] = [

        // ---------- Basics ----------
        "frac": [.f(1, 3, 1, 4), .f(2, 5, 1, 2), .f(3, 5, 1, 4), .f(3, 4, 2, 3), .f(1, 6, 3, 5), .f(2, 7, 1, 3)],
        "sq5": [.mul(25, 25), .mul(45, 45), .mul(65, 65), .mul(75, 75), .mul(85, 85), .mul(95, 95)],
        "x11": [.mul(23, 11), .mul(45, 11), .mul(78, 11), .mul(32, 101), .mul(56, 101), .mul(87, 101)],
        "x9": [.mul(47, 9), .mul(73, 9), .mul(36, 99), .mul(58, 99), .mul(124, 999), .mul(462, 999)],
        "dsc": [.e("47 \u{00D7} 23", "digit sum of answer", 1),
                .e("138 \u{00D7} 24", "digit sum of answer", 9),
                .e("62 \u{00D7} 57", "digit sum of answer", 6),
                .e("214 \u{00D7} 33", "digit sum of answer", 6),
                .e("96 \u{00D7} 48", "digit sum of answer", 9),
                .e("123 \u{00D7} 45", "digit sum of answer", 9)],
        "ssz": [.e("7x + 5 = 5x + 5", "x", 0),
                .e("4x + 11 = x + 11", "x", 0),
                .e("5x + 9 = 3x + 15", "x", 3),
                .e("6x + 2 = 2x + 18", "x", 4),
                .e("9x + 13 = 4x + 13", "x", 0),
                .e("3x + 20 = x + 30", "x", 5)],
        "cbrt": [.e("4913", "cube root", 17), .e("19683", "cube root", 27), .e("39304", "cube root", 34),
                 .e("250047", "cube root", 63), .e("148877", "cube root", 53), .e("804357", "cube root", 93)],
        "m3": [.mul(123, 456), .mul(214, 312), .mul(132, 231), .mul(405, 203), .mul(321, 123), .mul(111, 222)],

        // ---------- Intermediate ----------
        "rd": [.e("1 / 7", "digits in the block", 6), .e("1 / 11", "digits in the block", 2),
               .e("1 / 13", "digits in the block", 6), .e("1 / 17", "digits in the block", 16),
               .e("1 / 19", "digits in the block", 18), .e("1 / 29", "digits in the block", 28)],
        "dv": [.e("1234 \u{00F7} 98", "quotient", 12), .e("1234 \u{00F7} 98", "remainder", 58),
               .e("4321 \u{00F7} 97", "quotient", 44), .e("2176 \u{00F7} 89", "quotient", 24),
               .e("3452 \u{00F7} 96", "quotient", 35), .e("2345 \u{00F7} 99", "remainder", 68)],
        "ld10": [.mul(34, 36), .mul(43, 47), .mul(62, 68), .mul(71, 79), .mul(96, 94), .mul(27, 23)],
        "d7": [.e("595 \u{00F7} 7", "quotient", 85), .e("861 \u{00F7} 7", "quotient", 123),
               .e("938 \u{00F7} 7", "quotient", 134), .e("1001 \u{00F7} 7", "quotient", 143),
               .e("2401 \u{00F7} 7", "quotient", 343), .e("3493 \u{00F7} 7", "quotient", 499)],
        "sq50": [.mul(54, 54), .mul(58, 58), .mul(62, 62), .mul(67, 67), .mul(73, 73), .mul(76, 76)],
        "yav": [.mul(96, 96), .mul(94, 94), .mul(98, 98), .mul(103, 103), .mul(107, 107), .mul(992, 992)],
        "d13": [.e("858 \u{00F7} 13", "quotient", 66), .e("1001 \u{00F7} 13", "quotient", 77),
                .e("1287 \u{00F7} 13", "quotient", 99), .e("2197 \u{00F7} 13", "quotient", 169),
                .e("3549 \u{00F7} 13", "quotient", 273), .e("4433 \u{00F7} 13", "quotient", 341)],
        "d17": [.e("986 \u{00F7} 17", "quotient", 58), .e("1156 \u{00F7} 17", "quotient", 68),
                .e("1734 \u{00F7} 17", "quotient", 102), .e("2074 \u{00F7} 17", "quotient", 122),
                .e("3485 \u{00F7} 17", "quotient", 205), .e("5219 \u{00F7} 17", "quotient", 307)],

        // ---------- Advanced ----------
        "bin": [.e("(x+3)(x+4)", "coefficient of x", 7), .e("(x+5)(x+6)", "constant term", 30),
                .e("(x+7)(x+2)", "coefficient of x", 9), .e("(x+9)(x+4)", "constant term", 36),
                .e("(x+2)(x+11)", "coefficient of x", 13), .e("(x+8)(x+8)", "constant term", 64)],
        "eqr": [.e("x : 5 = 12 : 15", "x", 4), .e("3 : 7 = 12 : x", "x", 28), .e("x : 9 = 8 : 12", "x", 6),
                .e("4 : x = 10 : 25", "x", 10), .e("x : 6 = 14 : 21", "x", 4), .e("7 : 4 = x : 12", "x", 21)],
        "vex": [.e("(x+5)\u{00B2}", "coefficient of x", 10), .e("(x+7)\u{00B2}", "constant term", 49),
                .e("(x+9)\u{00B2}", "coefficient of x", 18), .e("(2x+3)\u{00B2}", "coefficient of x", 12),
                .e("(x+11)\u{00B2}", "constant term", 121), .e("(3x+2)\u{00B2}", "constant term", 4)],
        "tdm": [.mul(43, 67), .mul(58, 72), .mul(34, 89), .mul(76, 54), .mul(61, 49), .mul(96, 87)],
        "cube": [.e("(x+2)\u{00B3}", "coefficient of x\u{00B2}", 6), .e("(x+3)\u{00B3}", "constant term", 27),
                 .e("(x+4)\u{00B3}", "coefficient of x\u{00B2}", 12), .e("(x+1)\u{00B3}", "coefficient of x", 3),
                 .e("(x+5)\u{00B3}", "constant term", 125), .e("(x+2)\u{00B3}", "coefficient of x", 12)],
        "swc": [.e("7x+5y=23,  5x+7y=25", "x + y", 4), .e("9x+7y=48,  7x+9y=16", "x + y", 4),
                .e("4x+3y=25,  3x+4y=24", "x + y", 7), .e("6x+5y=34,  5x+6y=32", "x + y", 6),
                .e("8x+3y=31,  3x+8y=24", "x + y", 5), .e("2x+7y=29,  7x+2y=34", "x + y", 7)],
        "eqf": [.e("x/3 + x/4 = 7", "x", 12), .e("x/2 + x/5 = 7", "x", 10), .e("x/3 + x/6 = 5", "x", 10),
                .e("x/4 + x/6 = 5", "x", 12), .e("x/2 + x/3 = 10", "x", 12), .e("x/5 + x/10 = 3", "x", 10)],
        "adiv": [.e("(x\u{00B2}+7x+12) \u{00F7} (x+3)", "constant in quotient", 4),
                 .e("(x\u{00B2}+9x+20) \u{00F7} (x+4)", "constant in quotient", 5),
                 .e("(x\u{00B2}+5x+6) \u{00F7} (x+2)", "constant in quotient", 3),
                 .e("(x\u{00B2}+11x+24) \u{00F7} (x+3)", "constant in quotient", 8),
                 .e("(x\u{00B2}+13x+42) \u{00F7} (x+6)", "constant in quotient", 7),
                 .e("(x\u{00B2}+10x+21) \u{00F7} (x+7)", "constant in quotient", 3)],
        "sim": [.e("2x + 3y = 13,  x + y = 5", "x", 2), .e("3x + 2y = 16,  x + y = 6", "x", 4),
                .e("x + 2y = 11,  x + y = 7", "x", 3), .e("4x + y = 14,  x + y = 5", "x", 3),
                .e("5x + 2y = 24,  x + y = 6", "x", 4), .e("2x + 5y = 27,  x + y = 9", "x", 6)],

        // ---------- Mixed reviews ----------
        "mix": [.f(1, 2, 1, 3), .mul(55, 55), .mul(64, 11), .mul(43, 99), .mul(27, 101),
                .e("4913", "cube root", 17), .e("5x + 9 = 3x + 15", "x", 3), .mul(132, 231)],
        "mixi": [.mul(34, 36), .mul(58, 58), .mul(96, 96), .e("1287 \u{00F7} 13", "quotient", 99),
                 .e("2074 \u{00F7} 17", "quotient", 122), .e("1234 \u{00F7} 98", "quotient", 12),
                 .e("1 / 7", "digits in the block", 6), .mul(103, 103)],
        "mixa": [.e("(x+3)(x+4)", "coefficient of x", 7), .mul(43, 67), .e("x/3 + x/4 = 7", "x", 12),
                 .e("(x+2)\u{00B3}", "coefficient of x\u{00B2}", 6), .e("7x+5y=23,  5x+7y=25", "x + y", 4),
                 .e("(x\u{00B2}+9x+20) \u{00F7} (x+4)", "constant in quotient", 5),
                 .e("x : 9 = 8 : 12", "x", 6), .e("(x+5)\u{00B2}", "coefficient of x", 10)],
    ]

    /// "Practice time": two problems on your own after the lesson, before the quiz.
    static let practice: [String: [QuizQ]] = [
        "frac": [.f(2, 3, 1, 4), .f(1, 2, 2, 5)],
        "sq5": [.mul(45, 45), .mul(75, 75)],
    ]

    static func questions(_ id: String) -> [QuizQ] { quizzes[id] ?? quizzes["frac"]! }

    // MARK: grouping, names and blurbs

    struct Group: Identifiable {
        var id: String
        var title: String
        var ids: [String]
    }

    /// The Quizzes tab, in the same order as the lesson map.
    static let groups = [
        Group(id: "basics", title: "Basics", ids: ["frac", "sq5", "x11", "x9", "dsc", "ssz", "cbrt", "m3", "mix"]),
        Group(id: "inter", title: "Intermediate", ids: ["rd", "dv", "ld10", "d7", "sq50", "yav", "d13", "d17", "mixi"]),
        Group(id: "adv", title: "Advanced", ids: ["bin", "eqr", "vex", "tdm", "cube", "swc", "eqf", "adiv", "sim", "mixa"]),
    ]

    static let ids = groups.flatMap(\.ids)

    private static let mixed: [String: (name: String, glyph: String, blurb: String)] = [
        "mix": ("Basics Mixed Review", "\u{2605}", "A little of every Basics sutra"),
        "mixi": ("Intermediate Mixed Review", "\u{2605}", "A little of every Intermediate sutra"),
        "mixa": ("Advanced Mixed Review", "\u{2605}", "A little of every Advanced sutra"),
    ]

    private static let catalog: [String: Catalog.Item] = {
        var out: [String: Catalog.Item] = [:]
        for i in Catalog.basics + Catalog.inter + Catalog.adv { out[i.id] = i }
        return out
    }()

    static func name(_ id: String) -> String { mixed[id]?.name ?? catalog[id]?.name ?? "Quiz" }

    /// The little formula shown on the quiz card, e.g. `a/b + c/d`.
    /// A few of the lesson map's glyphs are too wide for the card's square tile,
    /// so they are broken over two lines here.
    static func glyph(_ id: String) -> String {
        if let g = wrapped[id] { return g }
        return mixed[id]?.glyph ?? catalog[id]?.glyph ?? "?"
    }

    private static let wrapped = ["bin": "(x+a)\n(x+b)", "eqr": "a : b\n= c : d",
                                  "swc": "ax+by\nbx+ay", "sim": "ax + by\n= c"]

    /// One line under the title on the quiz card.
    static func blurb(_ id: String) -> String {
        if let b = mixed[id]?.blurb { return b }
        return blurbs[id] ?? "\(questions(id).count) questions"
    }

    private static let blurbs = [
        "frac": "Cross-multiply, then add",
        "sq5": "Ends in 5: n(n+1) then 25",
        "x11": "Drop the digits apart and add",
        "x9": "All from 9, the last from 10",
        "dsc": "Cast out nines to check a product",
        "ssz": "When the sums match, x is zero",
        "cbrt": "Read the cube root off the ends",
        "m3": "Vertically and crosswise, 3 digits",
        "rd": "Ekadhikena: one more than before",
        "dv": "Divide with the deficiency",
        "ld10": "Last digits add to 10",
        "d7": "Osculate your way to 7",
        "sq50": "Squares between 50 and 100",
        "yav": "Yavadunam: squares near a base",
        "d13": "Osculate your way to 13",
        "d17": "Osculate your way to 17",
        "bin": "Vertically and crosswise on (x+a)",
        "eqr": "Proportion in one step",
        "vex": "Check an expansion by its parts",
        "tdm": "Two digits, one line",
        "cube": "Expand (x+a)\u{00B3} by the pattern",
        "swc": "Add and subtract the equations",
        "eqf": "Clear the fractions in one move",
        "adiv": "Paravartya division",
        "sim": "Two equations, one line each",
    ]

    /// The badge line shown on the results screen once at least one answer is right.
    static func doneLine(_ id: String) -> String? {
        switch id {
        case "mix": return "You\u{2019}ve reviewed every Basics sutra."
        case "mixi": return "You\u{2019}ve reviewed every Intermediate sutra."
        case "mixa": return "You\u{2019}ve reviewed every Advanced sutra."
        default: return "Badge earned: \(badges[id] ?? name(id))."
        }
    }

    /// Short badge names, so the results line stays one tidy phrase.
    private static let badges = ["frac": "Crosswise", "sq5": "Fives", "x11": "Elevens", "x9": "Nines",
                                 "dsc": "Digit Sums", "ssz": "Zero Sum", "cbrt": "Cube Roots", "m3": "Three Digits",
                                 "rd": "Recurring Decimals", "dv": "Near a Base", "ld10": "Last Digits",
                                 "d7": "Sevens", "sq50": "Fifties", "yav": "Yavadunam", "d13": "Thirteens",
                                 "d17": "Seventeens", "bin": "Binomials", "eqr": "Ratios", "vex": "Expansions",
                                 "tdm": "Two Digits", "cube": "Cubes", "swc": "Swapped Coefficients",
                                 "eqf": "Fractions in x", "adiv": "Paravartya", "sim": "Simultaneous"]
}
