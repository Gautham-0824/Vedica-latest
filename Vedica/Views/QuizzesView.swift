import SwiftUI

struct QuizzesScreen: View {
    @Environment(AppNavigator.self) private var nav

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Quizzes").font(Theme.round(52, .black)).foregroundColor(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Text("Test what you\u{2019}ve learned so far.").font(Theme.text(22, .medium)).foregroundColor(Theme.sub)
                    .padding(.top, pt(8))
                VStack(spacing: pt(12)) {
                    ForEach(QuizData.ids, id: \.self) { row($0) }
                }
                .padding(.top, pt(24))
            }
            .padding(.horizontal, pt(36))
            .padding(.top, pt(20))
            .padding(.bottom, pt(30))
        }
        .scrollBounceBehavior(.basedOnSize)
        .screenBackground()
    }

    private func row(_ id: String) -> some View {
        let n = QuizData.questions(id).count
        let score = nav.store.s.scores[id], t = nav.store.s.times[id]
        let sub = t.map { "\(n) questions \u{00B7} last \(score ?? 0) of \(n) in \(clockText($0.last)) \u{00B7} best \(clockText($0.best))" } ?? "\(n) questions \u{00B7} timed"
        return Button { nav.startQuiz(id, fromQuizzes: true) } label: {
            HStack(spacing: pt(16)) {
                Icon(d: "M7 3.5h7l4 4V20a.5.5 0 0 1-.5.5h-10.500A.5.5 0 0 1 6.500 20V4a.5.5 0 0 1 .5-.5zM9.500 12.500h5M9.500 16h5", size: 26, stroke: 2.2, color: Theme.blue)
                    .frame(width: pt(50), height: pt(50))
                    .background(RoundedRectangle(cornerRadius: pt(16), style: .continuous).fill(Theme.soft))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: pt(2)) {
                    Text("\(QuizData.names[id] ?? "") quiz").font(Theme.round(20, .heavy)).foregroundColor(Theme.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Text(sub).font(Theme.text(15, .medium)).foregroundColor(Theme.sub).lineLimit(1).minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
                Text(t == nil ? "Start" : "Retake").font(Theme.text(16, .bold)).foregroundColor(Theme.ink)
                    .padding(.horizontal, pt(22)).frame(height: pt(44))
                    .background(Capsule().fill(Color(hex: 0xeef2f6)))
            }
            .padding(.horizontal, pt(20)).frame(height: pt(76))
            .background(RoundedRectangle(cornerRadius: pt(22), style: .continuous).fill(.white))
            .shadow(color: Theme.shadow.opacity(0.04), radius: 1, x: 0, y: 1)
            .shadow(color: Theme.shadow.opacity(0.05), radius: 9, x: 0, y: 6)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(PressStyle(scale: 0.98))
    }
}
