import SwiftUI

struct ProgressScreen: View {
    @Environment(AppNavigator.self) private var nav
    private var store: ProgressStore { nav.store }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text(store.trimmedName.isEmpty ? "Your week" : "\(store.trimmedName)\u{2019}s week")
                    .font(Theme.round(52, .black)).foregroundColor(Theme.ink)
                HStack(alignment: .top, spacing: 20) {
                    weekCard.frame(width: Canvas.portrait ? 324 : 344)
                    accuracyCard
                }
                settingsCard
                Button("Reset prototype") { nav.reset() }
                    .font(Theme.text(15, .semibold))
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity)
            }
            .padding(EdgeInsets(top: 8, leading: 36, bottom: 124, trailing: 36))
        }
        .frame(width: Canvas.w, height: Canvas.h - 92)
        .offset(y: 92)
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        .background(Theme.canvas)
    }

    private var weekCard: some View {
        let on = store.week.filter(\.on).count, secs = store.weekSeconds
        return VStack(alignment: .leading, spacing: 0) {
            Text("This week").font(Theme.text(16, .semibold)).foregroundColor(Theme.sub)
            Text("\(on) of 7 days").font(Theme.round(36, .black)).foregroundColor(Theme.ink).padding(.top, 4)
            HStack(spacing: 8) {
                ForEach(Array(store.week.enumerated()), id: \.offset) { _, d in
                    Text(d.letter).font(Theme.text(13, .semibold)).foregroundColor(d.on ? .white : Theme.muted)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(d.on ? Theme.blue : .clear))
                        .overlay(Circle().stroke(d.on ? .clear : Theme.line, lineWidth: 2))
                }
            }
            .padding(.top, 16)
            Rectangle().fill(Color(hex: 0xedf1f5)).frame(height: 1).padding(.vertical, 16)
            Text("\(secs / 60) min spent practising").font(Theme.text(16, .semibold)).foregroundColor(Theme.ink)
            Text("\(store.minutesToday) min so far today").font(Theme.text(15, .medium)).foregroundColor(Theme.sub).padding(.top, 2)
        }
        .card()
    }

    private var accuracyCard: some View {
        let pts = Array(store.s.history.suffix(6))
        let last = pts.last?.percent, first = pts.count > 1 ? pts.first?.percent : nil
        let line = last == nil ? "Take a quiz to see your accuracy here." :
            first.map { last! >= $0 ? "Up \(last! - $0) points over your last \(pts.count) quizzes." : "Down \($0 - last!) points over your last \(pts.count) quizzes." } ?? "From your first quiz."
        return VStack(alignment: .leading, spacing: 0) {
            Text("Accuracy").font(Theme.text(16, .semibold)).foregroundColor(Theme.sub)
            Text(last.map { "\($0)%" } ?? "\u{2014}").font(Theme.round(40, .black)).foregroundColor(Theme.ink).padding(.top, 4)
            Text(line).font(Theme.text(15, .medium)).foregroundColor(Theme.sub)
            AccuracyChart(values: pts.map(\.percent))
                .frame(height: 130)
                .padding(.top, 14)
        }
        .card()
    }

    private var settingsCard: some View {
        @Bindable var store = store
        return VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily reminder").font(Theme.text(17, .semibold)).foregroundColor(Theme.ink)
                    Text("A gentle nudge on this iPad").font(Theme.text(14, .medium)).foregroundColor(Theme.sub)
                }
                Spacer()
                Toggle("", isOn: $store.s.remOn).labelsHidden().tint(Color(hex: 0x34c759))
            }
            .frame(height: 64)
            Rectangle().fill(Color(hex: 0xedf1f5)).frame(height: 1)
            HStack {
                Text("Reminder time").font(Theme.text(17, .semibold)).foregroundColor(Theme.ink)
                Spacer()
                HStack(spacing: 14) {
                    stepper("minus", -15)
                    Text(store.clock(store.s.rem)).font(Theme.round(22, .heavy)).foregroundColor(Theme.ink).frame(minWidth: 110)
                    stepper("plus", 15)
                }
                .opacity(store.s.remOn ? 1 : 0.4)
                .disabled(!store.s.remOn)
            }
            .frame(height: 72)
            Rectangle().fill(Color(hex: 0xedf1f5)).frame(height: 1)
            HStack {
                Text("Practice session length").font(Theme.text(17, .semibold)).foregroundColor(Theme.ink)
                Spacer()
                HStack(spacing: 2) {
                    ForEach([10, 15, 20], id: \.self) { m in
                        Button { store.s.session = m } label: {
                            Text("\(m) min").font(Theme.text(15, store.s.session == m ? .semibold : .medium))
                                .foregroundColor(Theme.ink)
                                .frame(width: 84, height: 38)
                                .background(Capsule().fill(store.s.session == m ? .white : .clear)
                                    .shadow(color: .black.opacity(store.s.session == m ? 0.12 : 0), radius: 4, x: 0, y: 3))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Capsule().fill(Color(hex: 0x767680, alpha: 0.12)))
            }
            .frame(height: 72)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
        .cardShadow()
        .onChange(of: store.s.remOn) { _, _ in store.scheduleReminder() }
        .onChange(of: store.s.rem) { _, _ in store.scheduleReminder() }
    }

    private func stepper(_ symbol: String, _ by: Int) -> some View {
        Button { store.s.rem = (store.s.rem + by + 1440) % 1440 } label: {
            Image(systemName: symbol).font(.system(size: 17, weight: .bold)).foregroundColor(Theme.ink)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(hex: 0xeef2f6)))
        }
        .buttonStyle(PressStyle(scale: 0.92))
    }
}

struct AccuracyChart: View {
    let values: [Int]

    var body: some View {
        SwiftUI.Canvas { ctx, size in
            for y in [10.0, 65.0, 120.0] {
                var g = Path()
                g.move(to: CGPoint(x: 0, y: y))
                g.addLine(to: CGPoint(x: size.width, y: y))
                ctx.stroke(g, with: .color(Color(hex: 0xedf1f5)), lineWidth: 1)
            }
            guard !values.isEmpty else { return }
            let step = values.count > 1 ? (size.width - 20) / CGFloat(values.count - 1) : 0
            let pts = values.enumerated().map { i, v in
                CGPoint(x: 10 + CGFloat(i) * step, y: 120 - CGFloat(v) / 100 * 110)
            }
            var p = Path()
            p.addLines(pts)
            ctx.stroke(p, with: .color(Theme.blue), style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            for pt in pts {
                ctx.fill(Path(ellipseIn: CGRect(x: pt.x - 5, y: pt.y - 5, width: 10, height: 10)), with: .color(Theme.blue))
            }
        }
    }
}

private extension View {
    func card() -> some View {
        padding(24)
            .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white))
            .cardShadow()
    }
}
