import Foundation

enum Status: String, Codable { case new, progress, done }

/// A practice or quiz question: a fraction sum (a/b + c/d) or a multiplication (x × m).
struct Question: Equatable {
    var isFraction: Bool
    var a = 0, b = 1, c = 0, d = 1
    var x = 0, m = 0

    static func f(_ a: Int, _ b: Int, _ c: Int, _ d: Int) -> Question { Question(isFraction: true, a: a, b: b, c: c, d: d) }
    static func mul(_ x: Int, _ m: Int) -> Question { Question(isFraction: false, x: x, m: m) }

    var solNum: Int { isFraction ? a * d + c * b : x * m }
    var solDen: Int { isFraction ? b * d : 1 }
    var text: String { isFraction ? "\(a)/\(b) + \(c)/\(d)" : "\(x) \u{00D7} \(m)" }
    var answer: String { isFraction ? "\(solNum)/\(solDen)" : "\(solNum)" }
}

enum Tier: Hashable { case basics, inter, adv }

enum Catalog {
    struct Item: Identifiable { var id: String; var name: String; var glyph: String }
    struct Sub: Identifiable { var id: String; var name: String; var glyph: String; var example: String }

    static let core = [Item(id: "frac", name: "Adding Unlike Fractions", glyph: "a/b + c/d"),
                       Item(id: "sq5", name: "Squaring 2-Digit Numbers Ending in 5", glyph: "_5 \u{00D7} _5"),
                       Item(id: "x11", name: "Multiply by 11 and 101", glyph: "__ \u{00D7} 11"),
                       Item(id: "x9", name: "Multiply by 9, 99 and 999", glyph: "__ \u{00D7} 99")]
    static let basicsExtra = [Item(id: "dsc", name: "Checking with Digit Sums", glyph: "_ \u{00D7} _ \u{2713}"),
                              Item(id: "ssz", name: "Same Sum Means Zero", glyph: "x + _ = 0"),
                              Item(id: "cbrt", name: "2-Digit Cube Roots", glyph: "\u{221B} 4913"),
                              Item(id: "m3", name: "Multiply 3-Digit Numbers", glyph: "___ \u{00D7} ___")]
    static let inter = [Item(id: "rd", name: "Recurring Decimals", glyph: "1 / _9"),
                        Item(id: "dv", name: "Dividing Near a Base", glyph: "___ \u{00F7} 98"),
                        Item(id: "ld10", name: "Last Digits Add to 10", glyph: "_4 \u{00D7} _6"),
                        Item(id: "d7", name: "Divisibility by 7", glyph: "\u{00F7} 7 ?"),
                        Item(id: "sq50", name: "Squaring 50 to 100", glyph: "5_\u{00B2}"),
                        Item(id: "yav", name: "Squaring Near a Base", glyph: "9_\u{00B2}"),
                        Item(id: "d13", name: "Divisibility by 13", glyph: "\u{00F7} 13 ?"),
                        Item(id: "d17", name: "Divisibility by 17", glyph: "\u{00F7} 17 ?")]
    static let adv = [Item(id: "bin", name: "Multiplying Two Binomials", glyph: "(x+a)(x+b)"),
                      Item(id: "eqr", name: "Equations in Ratio", glyph: "a : b = c : d"),
                      Item(id: "vex", name: "Verify an Expansion", glyph: "(x+a)\u{00B2} \u{2713}"),
                      Item(id: "tdm", name: "Two-digit \u{00D7} Two-digit", glyph: "__ \u{00D7} __"),
                      Item(id: "cube", name: "Completing the Cube", glyph: "(x+a)\u{00B3}"),
                      Item(id: "swc", name: "Swapped Coefficients", glyph: "ax+by, bx+ay"),
                      Item(id: "eqf", name: "Equations with Fractions", glyph: "x/_ + x/_"),
                      Item(id: "adiv", name: "Algebraic Division", glyph: "\u{00F7} (x + a)"),
                      Item(id: "sim", name: "Simultaneous Equations", glyph: "ax + by = c")]
    static let basics = core + basicsExtra

    static let subs: [String: [Sub]] = [
        "x11": [Sub(id: "m11", name: "Times 11", glyph: "\u{00D7} 11", example: "32 \u{00D7} 11 = 352"),
                Sub(id: "m101", name: "Times 101", glyph: "\u{00D7} 101", example: "32 \u{00D7} 101 = 3232")],
        "x9": [Sub(id: "m9", name: "Times 9", glyph: "\u{00D7} 9", example: "47 \u{00D7} 9 = 423"),
               Sub(id: "m99", name: "Times 99", glyph: "\u{00D7} 99", example: "47 \u{00D7} 99 = 4653"),
               Sub(id: "m999", name: "Times 999", glyph: "\u{00D7} 999", example: "235 \u{00D7} 999 = 234765")],
    ]
    static func family(of id: String) -> String? { subs.first { $0.value.contains { $0.id == id } }?.key }
    static func items(_ t: Tier) -> [Item] { t == .basics ? basics : t == .inter ? inter : adv }
    static func tier(of id: String) -> Tier {
        if adv.contains(where: { $0.id == id }) { return .adv }
        if inter.contains(where: { $0.id == id }) { return .inter }
        return .basics
    }

    private static let scripted = ["sq5", "m11", "m101", "m9", "m99", "m999", "rd", "dv"]
    private static let pages = ["dsc": "digit-sum-check", "ssz": "same-sum-zero", "cbrt": "cube-roots", "m3": "three-digit-mult",
                                "ld10": "last-digits-10", "d7": "divisibility-7", "sq50": "squares-50-100", "yav": "yavadunam",
                                "d13": "divisibility-13", "d17": "divisibility-17", "bin": "binomials", "eqr": "equations-ratio",
                                "vex": "verify-expansion", "tdm": "two-digit-mult", "cube": "completing-cube", "swc": "swapped-coeff",
                                "eqf": "equations-fractions", "adiv": "algebraic-division", "sim": "simultaneous-eq"]

    /// Page inside the bundled Lessons folder, and its query, for a lesson id.
    static func page(_ id: String) -> (file: String, query: String) {
        if id == "frac" { return ("Vedica Fraction Lesson.dc.html", "") }
        // Recurring Decimals and Dividing Near a Base (Intermediate) have their own copy of the multiply
        // lesson page, so the Basics and Intermediate owners never edit the same file.
        if id == "rd" || id == "dv" { return ("Vedica Intermediate Multiply Lesson.dc.html", "script=\(id)") }
        if scripted.contains(id) { return ("Vedica Multiply Lesson.dc.html", "script=\(id)") }
        return ("lessons/\(pages[id] ?? "digit-sum-check").html", "")
    }

    /// Where a finished lesson goes next.
    enum After { case practice, quiz(String), list }
    static func after(_ id: String) -> After {
        if id == "frac" || id == "sq5" { return .practice }
        if let f = family(of: id) { return .quiz(f) }
        return .list
    }
}
