import SwiftUI

/// Practice time and quiz screen, native as in the artifact's screens 10 and 11.
struct WorkScreen: View {
    @Environment(AppNavigator.self) private var nav
    @State private var padMode = PadMode.pen
    @State private var elapsed = 0
    private var z: WorkSession { nav.work }
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var caption: AttributedString {
        var out = AttributedString()
        func bold(_ s: String) { var a = AttributedString(s); a.font = Theme.round(23, .black); out += a }
        func plain(_ s: String) { out += AttributedString(s) }
        if z.status == .ok { bold(z.praise) }
        else if z.status == .bad {
            bold(z.quiz ? "Not quite. " : "Not quite, look again. ")
            if z.quiz { plain("It\u{2019}s \(z.q.answer).") }
            else { plain(z.part == .top ? "Check the top." : z.part == .bot ? "Check the bottom." : z.q.isFraction ? "Check the top and bottom." : "Try that one again.") }
        } else {
            plain(z.quiz ? "Your time is being recorded. Get it right first." : "Write in a box, or tap it and type.")
        }
        return out
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 8) {
                VedicaLogo(size: 28, shadowed: false)
                Text("Vedica").font(Theme.round(21, .heavy)).tracking(-0.6).foregroundColor(Theme.ink)
                Spacer()
                Text(QuizData.names[z.id] ?? "").font(Theme.text(15, .semibold)).foregroundColor(Color(hex: 0x8290a5)).padding(.trailing, 6)
                RoundIconButton(d: IconPath.close, size: 40, icon: 18, stroke: 2.6) { z.stopAuto(); nav.closeQuiz() }
            }
            .frame(width: Canvas.w - 72, height: 40)
            .at(36, 22)

            HStack(spacing: 6) {
                ForEach(0..<z.questions.count, id: \.self) { i in
                    Capsule().fill(i < z.index || (i == z.index && z.status == .ok) ? Theme.blue : i == z.index ? Theme.blue.opacity(0.4) : Theme.line)
                        .frame(width: 42, height: 5)
                }
            }
            .frame(width: Canvas.w).at(0, 62)

            VStack(alignment: .leading, spacing: 6) {
                Text(z.quiz ? "Quiz: \(QuizData.names[z.id] ?? "")" : "Practice time")
                    .font(Theme.round(34, .black)).foregroundColor(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                HStack(spacing: 10) {
                    Text("Question \(z.index + 1) of \(z.questions.count)").font(Theme.text(16, .semibold)).foregroundColor(Theme.sub)
                    if z.quiz {
                        Text(clockText(elapsed * 1000)).font(Theme.text(15, .bold)).foregroundColor(Theme.blue).monospacedDigit()
                            .padding(.horizontal, 12).frame(height: 32)
                            .background(Capsule().fill(Theme.soft))
                    }
                }
            }
            .frame(width: 500, alignment: .leading)
            .at(36, 112)

            problem.frame(width: Canvas.portrait ? Canvas.w : 524, height: 200)
                .at(Canvas.portrait ? 0 : 16, Canvas.portrait ? 196 : 222).offset(x: z.shake)

            if Canvas.portrait {
                ScratchPanel(mode: $padMode, session: z, width: Canvas.w - 72, height: Canvas.h - 734).at(36, 450)
                keypad.frame(width: Canvas.w).at(0, Canvas.h - 264)
            } else {
                ScratchPanel(mode: $padMode, session: z, width: Canvas.w - 596, height: Canvas.h - 316).at(560, 112)
                keypad.frame(width: Canvas.w).at(0, Canvas.h - 178)
            }

            ZStack {
                Text(caption).font(Theme.round(23, .bold)).foregroundColor(z.status == .ok ? Theme.green : z.status == .bad ? Theme.orange : Theme.body)
                    .multilineTextAlignment(.center)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.horizontal, 170)
                HStack {
                    RoundIconButton(d: IconPath.back, size: 56, icon: 26) { z.stopAuto(); nav.workBack() }
                    Spacer()
                    actionButton
                }
            }
            .frame(width: Canvas.w - 72, height: 56)
            .at(36, Canvas.h - 30 - 56)
        }
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        .background(Theme.canvas)
        .onReceive(timer) { _ in
            // One clock for the whole quiz; it stops once the last question is answered.
            if !(z.isLast && z.status != .none) { elapsed = Int(Date().timeIntervalSince(z.quizStarted)) }
            nav.store.addActivity(1)
        }
        .onDisappear { z.stopAuto(); nav.store.flushActivity() }
        .background(KeyCatcher(onKey: handleKey).frame(width: 1, height: 1))
    }

    @ViewBuilder private var problem: some View {
        let q = z.q
        if q.isFraction {
            HStack(spacing: 18) {
                frac(q.a, q.b)
                Text("+").font(Theme.round(52, .heavy)).foregroundColor(Theme.blue)
                frac(q.c, q.d)
                Text("=").font(Theme.round(52, .heavy)).foregroundColor(Theme.muted)
                VStack(spacing: 10) {
                    box(.top, z.top, width: 116, height: 76)
                    Capsule().fill(Theme.ink).frame(width: 116, height: 7)
                    box(.bot, z.bot, width: 116, height: 76)
                }
            }
        } else {
            HStack(spacing: 16) {
                if q.x == q.m {
                    Text("\(q.x)\u{00B2}").font(Theme.round(52, .heavy)).foregroundColor(Theme.ink)
                } else {
                    Text("\(q.x) \u{00D7} \(q.m)").font(Theme.round(52, .heavy)).foregroundColor(Theme.ink)
                }
                Text("=").font(Theme.round(52, .heavy)).foregroundColor(Theme.muted)
                box(.top, z.top, width: 196, height: 88)
            }
        }
    }

    private func frac(_ a: Int, _ b: Int) -> some View {
        VStack(spacing: 8) {
            Text("\(a)").font(Theme.round(60, .heavy)).foregroundColor(Theme.ink)
            Capsule().fill(Theme.ink).frame(width: 60, height: 7)
            Text("\(b)").font(Theme.round(60, .heavy)).foregroundColor(Theme.ink)
        }
    }

    private func box(_ b: AnswerBox, _ value: String, width: CGFloat, height: CGFloat) -> some View {
        let on = z.active == b && !z.locked
        let wrong = z.status == .bad && (z.part == nil || z.part == .both || (z.part == .top) == (b == .top))
        let color = z.status == .ok ? Theme.green : wrong ? Theme.orange : Theme.ink
        return ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(z.status == .ok ? Theme.green : wrong ? Theme.orange : on ? Theme.blue : Theme.dash, style: StrokeStyle(lineWidth: 3, dash: value.isEmpty && !on ? [7, 7] : []))
            Text(value).font(Theme.round(value.count > 4 ? 42 : 52, .heavy)).foregroundColor(color)
            InkBox(enabled: !z.locked, onTouch: { z.setBox(b) }, onDigits: { z.append($0, to: b) })
        }
        .frame(width: width, height: height)
    }

    private var keypad: some View {
        Group {
            if Canvas.portrait {
                VStack(spacing: 10) {
                    HStack(spacing: 10) { digits(["1", "2", "3", "4", "5", "6"]) }
                    HStack(spacing: 10) { digits(["7", "8", "9", "0"]); deleteKey }
                }
            } else {
                HStack(spacing: 8) { digits(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]); deleteKey }
            }
        }
        .opacity(z.locked ? 0.45 : 1)
        .disabled(z.locked)
    }

    private func digits(_ ks: [String]) -> some View {
        ForEach(ks, id: \.self) { k in
            key { z.append(k) } label: { Text(k).font(Theme.round(28, .heavy)).foregroundColor(Theme.ink) }
        }
    }

    private var deleteKey: some View {
        key { z.del() } label: { Image(systemName: "delete.left").font(.system(size: 24, weight: .semibold)).foregroundColor(Theme.body) }
    }

    private func key<L: View>(_ action: @escaping () -> Void, @ViewBuilder label: () -> L) -> some View {
        Button(action: action) {
            label().frame(width: Canvas.portrait ? 107 : 62, height: Canvas.portrait ? 72 : 62)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(PressStyle(scale: 0.92))
    }

    private var actionTitle: String {
        if z.status == .none || (!z.quiz && z.status == .bad) { return "Check" }
        if z.isLast { return z.quiz ? "See results" : "Start quiz" }
        return "Next"
    }

    private var actionEnabled: Bool { z.status == .none || (!z.quiz && z.status == .bad) ? z.ready : true }

    @ViewBuilder private var actionButton: some View {
        if z.quiz && z.status != .none {
            // Netflix-style: the button fills over five seconds, then moves on.
            Button(action: advance) {
                ZStack {
                    Capsule().fill(.white)
                    Text(actionTitle).font(Theme.text(17, .bold)).foregroundColor(Theme.ink)
                    ZStack {
                        Theme.blue
                        Text(actionTitle).font(Theme.text(17, .bold)).foregroundColor(.white)
                    }
                    .mask(alignment: .leading) {
                        Rectangle().frame(width: z.filling ? 148 : 0)
                    }
                }
                .frame(width: 148, height: 56)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.blue, lineWidth: 2))
            }
            .buttonStyle(PressStyle())
        } else {
            Button(action: action) {
                Text(actionTitle).font(Theme.text(17, .bold)).foregroundColor(actionEnabled ? .white : Theme.muted)
                    .padding(.horizontal, 30)
                    .frame(minWidth: 124, minHeight: 56)
                    .background(Capsule().fill(actionEnabled ? Theme.blue : Color(hex: 0xeef2f6)))
                    .shadow(color: Theme.blue.opacity(actionEnabled ? 0.3 : 0), radius: 12, x: 0, y: 10)
            }
            .buttonStyle(PressStyle())
            .disabled(!actionEnabled)
        }
    }

    private func handleKey(_ k: KeyCatcher.Key) {
        switch k {
        case .digit(let d): z.append(d)
        case .delete: z.del()
        case .toggleBox: z.setBox(z.active == .top ? .bot : .top)
        case .enter:
            // In a fraction, Return moves from the top box to the bottom one first.
            if z.q.isFraction && z.status == .none && !z.top.isEmpty && z.bot.isEmpty { z.setBox(.bot) }
            else if z.quiz && z.status != .none { advance() }
            else if actionEnabled { action() }
        }
    }

    private func action() {
        if z.status == .none || z.status == .bad {
            z.check(store: nav.store)
            if z.quiz { z.startAuto(advance) }
        } else {
            advance()
        }
    }

    private func advance() {
        z.stopAuto()
        if !z.isLast { withAnimation(.easeOut(duration: 0.2)) { z.nextQuestion() }; return }
        if z.quiz { nav.showResults() } else { nav.startQuiz(z.id, fromQuizzes: false) }
    }
}
