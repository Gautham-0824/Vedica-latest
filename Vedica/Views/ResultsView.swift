import SwiftUI

struct ResultsScreen: View {
    @Environment(AppNavigator.self) private var nav
    @State private var shown: Double = 0
    private var z: WorkSession { nav.work }
    private var total: Int { z.questions.count }
    private var pct: Double { total > 0 ? Double(z.score) / Double(total) : 0 }
    private var ring: Color { pct >= 0.8 ? Theme.green : pct >= 0.4 ? Theme.blue : Theme.orange }
    private var headline: String { pct == 1 ? "Perfect score!" : pct >= 0.8 ? "Great work!" : pct >= 0.4 ? "Good effort!" : "Keep practising!" }
    private var wrong: Int { total - z.score }

    var body: some View {
        let l = Metrics.shared
        Group {
            if l.wide {
                HStack(alignment: .top, spacing: pt(24)) {
                    summary.frame(width: pt(444))
                    answers
                }
                .padding(.top, pt(l.short ? 24 : 100))
                .padding(.bottom, pt(l.short ? 24 : 96))
            } else {
                VStack(spacing: pt(16)) {
                    summary.frame(height: pt(520))
                    answers
                }
                .padding(.top, pt(40))
                .padding(.bottom, pt(24))
            }
        }
        .padding(.horizontal, pt(36))
        .screenBackground()
        .onAppear { withAnimation(.timingCurve(0.3, 0.7, 0.4, 1, duration: 0.9).delay(0.15)) { shown = pct } }
    }

    private var summary: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().stroke(Color(hex: 0xeef2f6), lineWidth: pt(14))
                Circle().trim(from: 0, to: shown)
                    .stroke(ring, style: StrokeStyle(lineWidth: pt(14), lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(z.score)/\(total)").font(Theme.round(50, .black)).foregroundColor(Theme.ink)
                    Text("correct").font(Theme.text(15, .semibold)).foregroundColor(Theme.sub)
                }
            }
            .frame(width: pt(140), height: pt(140))
            .frame(width: pt(164), height: pt(164))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(z.score) of \(total) correct")
            Text(headline).font(Theme.round(30, .black)).foregroundColor(Theme.ink).padding(.top, pt(14))
                .accessibilityAddTraits(.isHeader)
            Text("Quiz: \(QuizData.names[z.id] ?? "")").font(Theme.text(16, .semibold)).foregroundColor(Theme.sub)
                .lineLimit(1).minimumScaleFactor(0.8).padding(.top, pt(4))
            HStack(spacing: 0) {
                stat("Total time", clockText(z.totalMs))
                stat("Per question", secsText(Double(z.totalMs) / Double(max(total, 1))))
                stat("Best time", clockText(nav.store.s.times[z.id]?.best ?? z.totalMs))
            }
            .padding(.vertical, pt(14))
            .background(RoundedRectangle(cornerRadius: pt(20), style: .continuous).fill(Theme.panel))
            .padding(.top, pt(16))
            if let line = QuizData.doneLines[z.id], z.score > 0 {
                HStack(spacing: pt(8)) {
                    Image(systemName: "star.fill").font(.system(size: pt(14))).foregroundColor(Theme.orange)
                        .accessibilityHidden(true)
                    Text(line).font(Theme.text(15, .semibold)).foregroundColor(Color(hex: 0xa8541a))
                }
                .padding(.horizontal, pt(14)).frame(height: pt(36))
                .background(Capsule().fill(Color(hex: 0xfff3e6)))
                .padding(.top, pt(14))
            }
            Spacer(minLength: 0)
            HStack(spacing: pt(12)) {
                SecondaryPill(title: "Retake quiz") { nav.startQuiz(z.id, fromQuizzes: z.fromQuizzes) }
                PrimaryPill(title: "Continue") { nav.closeQuiz() }
            }
        }
        .padding(EdgeInsets(top: pt(30), leading: pt(28), bottom: pt(28), trailing: pt(28)))
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: pt(28), style: .continuous).fill(.white))
        .cardShadow()
    }

    private func stat(_ l: String, _ v: String) -> some View {
        VStack(spacing: pt(2)) {
            Text(v).font(Theme.round(20, .black)).foregroundColor(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(l).font(Theme.text(13, .medium)).foregroundColor(Theme.sub)
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var answers: some View {
        VStack(alignment: .leading, spacing: pt(14)) {
            HStack {
                Text("Your answers").font(Theme.round(22, .black)).foregroundColor(Theme.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Text(wrong > 0 ? "\(wrong) to review" : "All correct")
                    .font(Theme.text(14, .bold))
                    .foregroundColor(wrong > 0 ? Color(hex: 0xa8541a) : Theme.green)
                    .padding(.horizontal, pt(12)).frame(height: pt(30))
                    .background(Capsule().fill(wrong > 0 ? Color(hex: 0xfff3e6) : Color(hex: 0xe8f7ef)))
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: pt(8)) {
                    ForEach(Array(z.records.enumerated()), id: \.offset) { _, r in row(r) }
                }
            }
        }
        .padding(EdgeInsets(top: pt(24), leading: pt(26), bottom: pt(24), trailing: pt(26)))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: pt(28), style: .continuous).fill(.white))
        .cardShadow()
    }

    private func row(_ r: AnswerRecord) -> some View {
        let yours = r.question.isFraction ? "\(r.top)/\(r.bot)" : r.top
        return HStack(spacing: pt(12)) {
            Image(systemName: r.ok ? "checkmark" : "xmark")
                .font(.system(size: pt(14), weight: .heavy)).foregroundColor(.white)
                .frame(width: pt(30), height: pt(30))
                .background(Circle().fill(r.ok ? Theme.green : Theme.orange))
                .accessibilityLabel(r.ok ? "Correct" : "Wrong")
            VStack(alignment: .leading, spacing: pt(1)) {
                Text(r.question.text).font(Theme.round(19, .heavy)).foregroundColor(Theme.ink)
                Text(r.ok ? "\(r.question.answer) \u{00B7} \(secsText(Double(r.ms)))" : "You wrote \(yours). Answer: \(r.question.answer) \u{00B7} \(secsText(Double(r.ms)))")
                    .font(Theme.text(14, .medium)).foregroundColor(Theme.sub).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            if !r.ok && r.question.isFraction {
                Button {
                    nav.show(.lesson("frac", start: r.part == .bot ? 4 : r.part == .top ? 3 : 1, review: true))
                } label: {
                    Text("Review").font(Theme.text(15, .bold)).foregroundColor(Theme.blue)
                        .padding(.horizontal, pt(16)).frame(height: pt(40))
                        .background(Capsule().fill(.white))
                        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                }
                .buttonStyle(PressStyle())
            }
        }
        .padding(.horizontal, pt(14)).padding(.vertical, pt(12))
        .background(RoundedRectangle(cornerRadius: pt(18), style: .continuous).fill(r.ok ? Theme.panel : Color(hex: 0xfffaf4)))
        .overlay(RoundedRectangle(cornerRadius: pt(18), style: .continuous).stroke(r.ok ? .clear : Color(hex: 0xfbe3cc), lineWidth: 1))
    }
}
