import SwiftUI

/// Tier colours for the quiz cards: the app's blue, green and orange, with their soft tints.
struct QuizTint {
    var strong: Color
    var soft: Color

    static let basics = QuizTint(strong: Theme.blue, soft: Theme.soft)
    static let inter = QuizTint(strong: Theme.green, soft: Color(hex: 0xe8f7ef))
    static let adv = QuizTint(strong: Theme.orange, soft: Color(hex: 0xfff3e6))

    static func of(_ group: String) -> QuizTint {
        switch group {
        case "inter": return .inter
        case "adv": return .adv
        default: return .basics
        }
    }
}

/// One quiz on the Quizzes tab: the sutra's formula in a tinted tile, the lesson's name,
/// a one-line reminder of the trick, and a dot for each question that fills in with your score.
struct QuizCard: View {
    var id: String
    var tint: QuizTint
    /// Correct answers last time, or nil if it has never been taken.
    var score: Int?
    var best: Int?
    /// Cards are all one height in the two-column grid; on a narrow phone they size themselves.
    var height: CGFloat?
    var action: () -> Void

    private var total: Int { QuizData.questions(id).count }
    private var perfect: Bool { score == total }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: pt(10)) {
                HStack(alignment: .top, spacing: pt(12)) {
                    glyphTile
                    VStack(alignment: .leading, spacing: pt(3)) {
                        Text(QuizData.name(id))
                            .font(Theme.round(19, .heavy)).foregroundColor(Theme.ink)
                            .lineLimit(2).minimumScaleFactor(0.75)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        Text(QuizData.blurb(id))
                            .font(Theme.text(14, .medium)).foregroundColor(Theme.sub)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                    if perfect {
                        Image(systemName: "star.fill")
                            .font(.system(size: pt(15))).foregroundColor(Theme.orange)
                            .padding(pt(7))
                            .background(Circle().fill(Color(hex: 0xfff3e6)))
                    }
                }
                Spacer(minLength: 0)
                HStack(spacing: pt(10)) {
                    dots
                    Text(status).font(Theme.text(13, .semibold)).foregroundColor(Theme.sub)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    Text(score == nil ? "Start" : "Retake")
                        .font(Theme.text(15, .bold)).foregroundColor(Theme.ink)
                        .padding(.horizontal, pt(18)).frame(height: pt(38))
                        .background(Capsule().fill(Color(hex: 0xeef2f6)))
                }
            }
            .padding(EdgeInsets(top: pt(16), leading: pt(16), bottom: pt(14), trailing: pt(16)))
            .frame(height: height.map { pt($0) }, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: pt(22), style: .continuous).fill(.white)
                    .overlay(alignment: .bottom) { underline }
                    .clipShape(RoundedRectangle(cornerRadius: pt(22), style: .continuous))
            )
            .overlay(RoundedRectangle(cornerRadius: pt(22), style: .continuous).stroke(Theme.line, lineWidth: 1))
            .shadow(color: Theme.shadow.opacity(0.04), radius: 1, x: 0, y: 1)
            .shadow(color: Theme.shadow.opacity(0.05), radius: 9, x: 0, y: 6)
        }
        .buttonStyle(PressStyle(scale: 0.98))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(QuizData.name(id)) quiz. \(status).")
        .accessibilityHint(score == nil ? "Start the quiz" : "Retake the quiz")
        .accessibilityAddTraits(.isButton)
    }

    /// The sutra's formula, e.g. `a/b + c/d`, in a tinted rounded tile.
    private var glyphTile: some View {
        Text(QuizData.glyph(id))
            .font(Theme.round(15, .black)).foregroundColor(tint.strong)
            .lineLimit(2).minimumScaleFactor(0.5)
            .multilineTextAlignment(.center)
            .padding(.horizontal, pt(5))
            .frame(width: pt(54), height: pt(54))
            .background(RoundedRectangle(cornerRadius: pt(17), style: .continuous).fill(tint.soft))
            .accessibilityHidden(true)
    }

    /// A dot per question: filled for each one answered right last time.
    private var dots: some View {
        HStack(spacing: pt(4)) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < (score ?? 0) ? tint.strong : Theme.line)
                    .frame(width: pt(7), height: pt(7))
            }
        }
        .accessibilityHidden(true)
    }

    /// A hairline at the foot of the card that grows with your score.
    @ViewBuilder private var underline: some View {
        if let s = score, total > 0 {
            GeometryReader { g in
                Rectangle().fill(tint.strong.opacity(0.75))
                    .frame(width: g.size.width * CGFloat(s) / CGFloat(total))
            }
            .frame(height: pt(3))
        }
    }

    private var status: String {
        guard let s = score else { return "\(total) questions \u{00B7} timed" }
        if let b = best { return "\(s)/\(total) \u{00B7} best \(clockText(b))" }
        return "\(s)/\(total)"
    }
}
