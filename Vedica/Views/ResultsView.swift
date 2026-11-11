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
        ZStack(alignment: .topLeading) {
            if Canvas.portrait {
                summary.frame(width: Canvas.w - 72, height: 520).at(36, 40)
                answers.frame(width: Canvas.w - 72, height: Canvas.h - 600).at(36, 576)
            } else {
                summary.frame(width: 444, height: Canvas.h - 196).at(36, 100)
                answers.frame(width: Canvas.w - 540, height: Canvas.h - 196).at(504, 100)
            }
        }
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        .background(Theme.canvas)
        .onAppear { withAnimation(.timingCurve(0.3, 0.7, 0.4, 1, duration: 0.9).delay(0.15)) { shown = pct } }
    }

    private var summary: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().stroke(Color(hex: 0xeef2f6), lineWidth: 14)
                Circle().trim(from: 0, to: shown)
                    .stroke(ring, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(z.score)/\(total)").font(Theme.round(50, .black)).foregroundColor(Theme.ink)
                    Text("correct").font(Theme.text(15, .semibold)).foregroundColor(Theme.sub)
                }
            }
            .frame(width: 140, height: 140)
            .frame(width: 164, height: 164)
            Text(headline).font(Theme.round(30, .black)).foregroundColor(Theme.ink).padding(.top, 14)
            Text("Quiz: \(QuizData.names[z.id] ?? "")").font(Theme.text(16, .semibold)).foregroundColor(Theme.sub)
                .lineLimit(1).minimumScaleFactor(0.8).padding(.top, 4)
            HStack(spacing: 0) {
                stat("Total time", clockText(z.totalMs))
                stat("Per question", secsText(Double(z.totalMs) / Double(max(total, 1))))
                stat("Best time", clockText(nav.store.s.times[z.id]?.best ?? z.totalMs))
            }
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.panel))
            .padding(.top, 16)
            if let line = QuizData.doneLines[z.id], z.score > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill").font(.system(size: 14)).foregroundColor(Theme.orange)
                    Text(line).font(Theme.text(15, .semibold)).foregroundColor(Color(hex: 0xa8541a))
                }
                .padding(.horizontal, 14).frame(height: 36)
                .background(Capsule().fill(Color(hex: 0xfff3e6)))
                .padding(.top, 14)
            }
            Spacer(minLength: 0)
            HStack(spacing: 12) {
                SecondaryPill(title: "Retake quiz") { nav.startQuiz(z.id, fromQuizzes: z.fromQuizzes) }
                PrimaryPill(title: "Continue") { nav.closeQuiz() }
            }
        }
        .padding(EdgeInsets(top: 30, leading: 28, bottom: 28, trailing: 28))
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
        .cardShadow()
    }

    private func stat(_ l: String, _ v: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(Theme.round(20, .black)).foregroundColor(Theme.ink)
            Text(l).font(Theme.text(13, .medium)).foregroundColor(Theme.sub)
        }
        .frame(maxWidth: .infinity)
    }

    private var answers: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Your answers").font(Theme.round(22, .black)).foregroundColor(Theme.ink)
                Spacer()
                Text(wrong > 0 ? "\(wrong) to review" : "All correct")
                    .font(Theme.text(14, .bold))
                    .foregroundColor(wrong > 0 ? Color(hex: 0xa8541a) : Theme.green)
                    .padding(.horizontal, 12).frame(height: 30)
                    .background(Capsule().fill(wrong > 0 ? Color(hex: 0xfff3e6) : Color(hex: 0xe8f7ef)))
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(Array(z.records.enumerated()), id: \.offset) { _, r in row(r) }
                }
            }
        }
        .padding(EdgeInsets(top: 24, leading: 26, bottom: 24, trailing: 26))
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
        .cardShadow()
    }

    private func row(_ r: AnswerRecord) -> some View {
        let yours = r.question.isFraction ? "\(r.top)/\(r.bot)" : r.top
        return HStack(spacing: 12) {
            Image(systemName: r.ok ? "checkmark" : "xmark")
                .font(.system(size: 14, weight: .heavy)).foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(r.ok ? Theme.green : Theme.orange))
            VStack(alignment: .leading, spacing: 1) {
                Text(r.question.text).font(Theme.round(19, .heavy)).foregroundColor(Theme.ink)
                Text(r.ok ? "\(r.question.answer) \u{00B7} \(secsText(Double(r.ms)))" : "You wrote \(yours). Answer: \(r.question.answer) \u{00B7} \(secsText(Double(r.ms)))")
                    .font(Theme.text(14, .medium)).foregroundColor(Theme.sub).lineLimit(1).minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
            if !r.ok && r.question.isFraction {
                Button {
                    nav.go(.lesson("frac", start: r.part == .bot ? 4 : r.part == .top ? 3 : 1, review: true))
                } label: {
                    Text("Review").font(Theme.text(15, .bold)).foregroundColor(Theme.blue)
                        .padding(.horizontal, 16).frame(height: 40)
                        .background(Capsule().fill(.white))
                        .overlay(Capsule().stroke(Theme.line, lineWidth: 1))
                }
                .buttonStyle(PressStyle())
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(r.ok ? Theme.panel : Color(hex: 0xfffaf4)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(r.ok ? .clear : Color(hex: 0xfbe3cc), lineWidth: 1))
    }
}
