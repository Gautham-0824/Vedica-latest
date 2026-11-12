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

    private var layout: Metrics { Metrics.shared }

    var body: some View {
        Group {
            // Landscape iPhone is too short for the whole screen, so it scrolls there.
            if layout.short {
                ScrollView(showsIndicators: false) { content.frame(height: pt(640)) }
            } else {
                content
            }
        }
        .screenBackground()
        .onReceive(timer) { _ in
            // One clock for the whole quiz; it stops once the last question is answered.
            if !(z.isLast && z.status != .none) { elapsed = Int(Date().timeIntervalSince(z.quizStarted)) }
            nav.store.addActivity(1)
        }
        .onDisappear { z.stopAuto(); nav.store.flushActivity() }
        .background(KeyCatcher(onKey: handleKey).frame(width: 1, height: 1))
    }

    private var content: some View {
        VStack(spacing: 0) {
            topBar
            if layout.wide {
                HStack(alignment: .top, spacing: pt(20)) {
                    VStack(alignment: .leading, spacing: 0) {
                        titleBlock.frame(height: pt(110), alignment: .topLeading).padding(.leading, pt(20))
                        problem.frame(maxWidth: .infinity).frame(height: pt(200)).offset(x: z.shake)
                    }
                    .frame(width: pt(524))
                    ScratchPanel(mode: $padMode, session: z)
                }
                .padding(.leading, pt(16)).padding(.trailing, pt(36))
                .padding(.top, pt(45))
                keypad.padding(.top, pt(26))
            } else {
                titleBlock.frame(maxWidth: .infinity, alignment: .leading).frame(height: pt(84), alignment: .topLeading)
                    .padding(.horizontal, pt(36)).padding(.top, pt(45))
                problem.frame(maxWidth: .infinity).frame(height: pt(200)).offset(x: z.shake)
                ScratchPanel(mode: $padMode, session: z)
                    .padding(.horizontal, pt(36)).padding(.top, pt(54))
                keypad.padding(.top, pt(20))
            }
            bottomBar.padding(.top, pt(layout.wide ? 30 : 24)).padding(.bottom, pt(30))
        }
    }

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: pt(8)) {
                VedicaLogo(size: 28, shadowed: false)
                Text("Vedica").font(Theme.round(21, .heavy)).tracking(pt(-0.6)).foregroundColor(Theme.ink)
                    .accessibilityHidden(true)
                Spacer()
                Text(QuizData.names[z.id] ?? "").font(Theme.text(15, .semibold)).foregroundColor(Color(hex: 0x8290a5)).padding(.trailing, pt(6))
                    .lineLimit(1).minimumScaleFactor(0.7)
                RoundIconButton(d: IconPath.close, size: 40, icon: 18, stroke: 2.6) { z.stopAuto(); nav.closeQuiz() }
                    .accessibilityLabel("Close")
            }
            .frame(height: pt(40))
            .padding(.horizontal, pt(36))
            .padding(.top, pt(22))

            HStack(spacing: pt(6)) {
                ForEach(0..<z.questions.count, id: \.self) { i in
                    Capsule().fill(i < z.index || (i == z.index && z.status == .ok) ? Theme.blue : i == z.index ? Theme.blue.opacity(0.4) : Theme.line)
                        .frame(width: pt(42), height: pt(5))
                }
            }
            .accessibilityHidden(true)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: pt(6)) {
            Text(z.quiz ? "Quiz: \(QuizData.names[z.id] ?? "")" : "Practice time")
                .font(Theme.round(34, .black)).foregroundColor(Theme.ink)
                .lineLimit(1).minimumScaleFactor(0.6)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: pt(10)) {
                Text("Question \(z.index + 1) of \(z.questions.count)").font(Theme.text(16, .semibold)).foregroundColor(Theme.sub)
                if z.quiz {
                    Text(clockText(elapsed * 1000)).font(Theme.text(15, .bold)).foregroundColor(Theme.blue).monospacedDigit()
                        .padding(.horizontal, pt(12)).frame(height: pt(32))
                        .background(Capsule().fill(Theme.soft))
                        .accessibilityLabel("Time \(clockText(elapsed * 1000))")
                }
            }
        }
        .frame(maxWidth: pt(500), alignment: .leading)
    }

    @ViewBuilder private var bottomBar: some View {
        if layout.compact {
            // A narrow window has no room for the caption between the buttons, so it sits above them.
            VStack(spacing: pt(12)) {
                captionText.lineLimit(2)
                buttons.frame(height: pt(56))
            }
            .padding(.horizontal, pt(36))
        } else {
            ZStack {
                captionText.lineLimit(1).padding(.horizontal, pt(170))
                buttons
            }
            .frame(height: pt(56))
            .padding(.horizontal, pt(36))
        }
    }

    private var captionText: some View {
        Text(caption).font(Theme.round(23, .bold)).foregroundColor(z.status == .ok ? Theme.green : z.status == .bad ? Theme.orange : Theme.body)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
            .accessibilityAddTraits(.updatesFrequently)
    }

    private var buttons: some View {
        HStack {
            RoundIconButton(d: IconPath.back, size: 56, icon: 26) { z.stopAuto(); nav.workBack() }
                .accessibilityLabel("Back")
            Spacer()
            actionButton
        }
    }

    @ViewBuilder private var problem: some View {
        let q = z.q
        if q.isFraction {
            HStack(spacing: pt(18)) {
                frac(q.a, q.b)
                Text("+").font(Theme.round(52, .heavy)).foregroundColor(Theme.blue)
                frac(q.c, q.d)
                Text("=").font(Theme.round(52, .heavy)).foregroundColor(Theme.muted)
                VStack(spacing: pt(10)) {
                    box(.top, z.top, width: 116, height: 76)
                    Capsule().fill(Theme.ink).frame(width: pt(116), height: pt(7))
                    box(.bot, z.bot, width: 116, height: 76)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(q.a) over \(q.b) plus \(q.c) over \(q.d)")
        } else {
            HStack(spacing: pt(16)) {
                if q.x == q.m {
                    Text("\(q.x)\u{00B2}").font(Theme.round(52, .heavy)).foregroundColor(Theme.ink)
                } else {
                    Text("\(q.x) \u{00D7} \(q.m)").font(Theme.round(52, .heavy)).foregroundColor(Theme.ink)
                }
                Text("=").font(Theme.round(52, .heavy)).foregroundColor(Theme.muted)
                box(.top, z.top, width: 196, height: 88)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(q.x == q.m ? "\(q.x) squared" : "\(q.x) times \(q.m)")
        }
    }

    private func frac(_ a: Int, _ b: Int) -> some View {
        VStack(spacing: pt(8)) {
            Text("\(a)").font(Theme.round(60, .heavy)).foregroundColor(Theme.ink)
            Capsule().fill(Theme.ink).frame(width: pt(60), height: pt(7))
            Text("\(b)").font(Theme.round(60, .heavy)).foregroundColor(Theme.ink)
        }
        .accessibilityHidden(true)
    }

    private func box(_ b: AnswerBox, _ value: String, width: CGFloat, height: CGFloat) -> some View {
        let on = z.active == b && !z.locked
        let wrong = z.status == .bad && (z.part == nil || z.part == .both || (z.part == .top) == (b == .top))
        let color = z.status == .ok ? Theme.green : wrong ? Theme.orange : Theme.ink
        return ZStack {
            RoundedRectangle(cornerRadius: pt(18), style: .continuous).fill(.white)
            RoundedRectangle(cornerRadius: pt(18), style: .continuous)
                .stroke(z.status == .ok ? Theme.green : wrong ? Theme.orange : on ? Theme.blue : Theme.dash, style: StrokeStyle(lineWidth: pt(3), dash: value.isEmpty && !on ? [pt(7), pt(7)] : []))
            Text(value).font(Theme.round(value.count > 4 ? 42 : 52, .heavy)).foregroundColor(color)
            InkBox(enabled: !z.locked, onTouch: { z.setBox(b) }, onDigits: { z.append($0, to: b) })
        }
        .frame(width: pt(width), height: pt(height))
        .accessibilityElement()
        .accessibilityLabel(b == .top ? (z.q.isFraction ? "Top answer box" : "Answer box") : "Bottom answer box")
        .accessibilityValue(value.isEmpty ? "Empty" : value)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { z.setBox(b) }
    }

    private var keypad: some View {
        Group {
            if layout.wide {
                HStack(spacing: pt(8)) { digits(["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]); deleteKey }
            } else {
                VStack(spacing: pt(10)) {
                    HStack(spacing: pt(10)) { digits(["1", "2", "3", "4", "5", "6"]) }
                    HStack(spacing: pt(10)) { digits(["7", "8", "9", "0"]); deleteKey }
                }
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
        key { z.del() } label: { Image(systemName: "delete.left").font(.system(size: pt(24), weight: .semibold)).foregroundColor(Theme.body) }
            .accessibilityLabel("Delete")
    }

    private func key<L: View>(_ action: @escaping () -> Void, @ViewBuilder label: () -> L) -> some View {
        Button(action: action) {
            label().frame(width: pt(keyW), height: pt(layout.wide ? 62 : 72))
                .background(RoundedRectangle(cornerRadius: pt(18), style: .continuous).fill(.white))
                .overlay(RoundedRectangle(cornerRadius: pt(18), style: .continuous).stroke(Theme.line, lineWidth: 1))
        }
        .buttonStyle(PressStyle(scale: 0.92))
    }

    /// Key width: the design's 62 (one row) or 107 (two rows), narrower when six keys must fit a slim window.
    private var keyW: CGFloat {
        if layout.wide { return 62 }
        return min(107, (layout.w - 72 - 50) / 6)
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
                        Rectangle().frame(width: z.filling ? pt(148) : 0)
                    }
                }
                .frame(width: pt(148), height: pt(56))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.blue, lineWidth: 2))
            }
            .buttonStyle(PressStyle())
        } else {
            Button(action: action) {
                Text(actionTitle).font(Theme.text(17, .bold)).foregroundColor(actionEnabled ? .white : Theme.muted)
                    .padding(.horizontal, pt(30))
                    .frame(minWidth: pt(124), minHeight: pt(56))
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
