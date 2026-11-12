import SwiftUI

struct ProgressScreen: View {
    @Environment(AppNavigator.self) private var nav
    private var store: ProgressStore { nav.store }
    private var layout: Metrics { Metrics.shared }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: pt(20)) {
                Text(store.trimmedName.isEmpty ? "Your week" : "\(store.trimmedName)\u{2019}s week")
                    .font(Theme.round(52, .black)).foregroundColor(Theme.ink)
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .accessibilityAddTraits(.isHeader)
                if layout.compact {
                    weekCard
                    accuracyCard
                } else {
                    HStack(alignment: .top, spacing: pt(20)) {
                        weekCard.frame(width: pt(layout.portrait ? 324 : 344))
                        accuracyCard
                    }
                }
                settingsCard
                Button("Reset prototype") { nav.reset() }
                    .font(Theme.text(15, .semibold))
                    .foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity)
            }
            .padding(EdgeInsets(top: pt(20), leading: pt(36), bottom: pt(124), trailing: pt(36)))
        }
        .screenBackground()
    }

    private var weekCard: some View {
        let on = store.week.filter(\.on).count, secs = store.weekSeconds
        return VStack(alignment: .leading, spacing: 0) {
            Text("This week").font(Theme.text(16, .semibold)).foregroundColor(Theme.sub)
            Text("\(on) of 7 days").font(Theme.round(36, .black)).foregroundColor(Theme.ink).padding(.top, pt(4))
            HStack(spacing: pt(8)) {
                ForEach(Array(store.week.enumerated()), id: \.offset) { _, d in
                    Text(d.letter).font(Theme.text(13, .semibold)).foregroundColor(d.on ? .white : Theme.muted)
                        .frame(width: pt(32), height: pt(32))
                        .background(Circle().fill(d.on ? Theme.blue : .clear))
                        .overlay(Circle().stroke(d.on ? .clear : Theme.line, lineWidth: 2))
                }
            }
            .accessibilityHidden(true)
            .padding(.top, pt(16))
            Rectangle().fill(Color(hex: 0xedf1f5)).frame(height: 1).padding(.vertical, pt(16))
            Text("\(secs / 60) min spent practising").font(Theme.text(16, .semibold)).foregroundColor(Theme.ink)
            Text("\(store.minutesToday) min so far today").font(Theme.text(15, .medium)).foregroundColor(Theme.sub).padding(.top, pt(2))
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
            Text(last.map { "\($0)%" } ?? "\u{2014}").font(Theme.round(40, .black)).foregroundColor(Theme.ink).padding(.top, pt(4))
            Text(line).font(Theme.text(15, .medium)).foregroundColor(Theme.sub)
            AccuracyChart(values: pts.map(\.percent))
                .frame(height: 130)
                .padding(.top, pt(14))
                .accessibilityHidden(true)
        }
        .card()
    }

    private var settingsCard: some View {
        @Bindable var store = store
        return VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: pt(2)) {
                    Text("Daily reminder").font(Theme.text(17, .semibold)).foregroundColor(Theme.ink)
                    Text("A gentle nudge on this \(UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone")").font(Theme.text(14, .medium)).foregroundColor(Theme.sub)
                }
                Spacer()
                Toggle("Daily reminder", isOn: $store.s.remOn).labelsHidden().tint(Color(hex: 0x34c759))
            }
            .frame(minHeight: pt(64))
            Rectangle().fill(Color(hex: 0xedf1f5)).frame(height: 1)
            HStack {
                Text("Reminder time").font(Theme.text(17, .semibold)).foregroundColor(Theme.ink)
                Spacer()
                HStack(spacing: pt(14)) {
                    stepper("minus", -15, label: "15 minutes earlier")
                    Text(store.clock(store.s.rem)).font(Theme.round(22, .heavy)).foregroundColor(Theme.ink).frame(minWidth: pt(110))
                    stepper("plus", 15, label: "15 minutes later")
                }
                .opacity(store.s.remOn ? 1 : 0.4)
                .disabled(!store.s.remOn)
            }
            .frame(minHeight: pt(72))
            Rectangle().fill(Color(hex: 0xedf1f5)).frame(height: 1)
            if layout.compact {
                VStack(alignment: .leading, spacing: pt(10)) {
                    Text("Practice session length").font(Theme.text(17, .semibold)).foregroundColor(Theme.ink)
                    sessionPicker
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, pt(16))
            } else {
                HStack {
                    Text("Practice session length").font(Theme.text(17, .semibold)).foregroundColor(Theme.ink)
                    Spacer()
                    sessionPicker
                }
                .frame(minHeight: pt(72))
            }
        }
        .padding(.horizontal, pt(24))
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: pt(24), style: .continuous).fill(.white))
        .cardShadow()
        .onChange(of: store.s.remOn) { _, _ in store.scheduleReminder() }
        .onChange(of: store.s.rem) { _, _ in store.scheduleReminder() }
    }

    /// Segmented choice of 10, 15 or 20 minutes, drawn as in the design.
    private var sessionPicker: some View {
        HStack(spacing: pt(2)) {
            ForEach([10, 15, 20], id: \.self) { m in
                let on = store.s.session == m
                Button { store.s.session = m } label: {
                    Text("\(m) min").font(Theme.text(15, on ? .semibold : .medium))
                        .foregroundColor(Theme.ink)
                        .frame(width: pt(84), height: pt(38))
                        .background(Capsule().fill(on ? .white : .clear)
                            .shadow(color: .black.opacity(on ? 0.12 : 0), radius: 4, x: 0, y: 3))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(pt(3))
        .background(Capsule().fill(Color(hex: 0x767680, alpha: 0.12)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Practice session length")
    }

    private func stepper(_ symbol: String, _ by: Int, label: String) -> some View {
        Button { store.s.rem = (store.s.rem + by + 1440) % 1440 } label: {
            Image(systemName: symbol).font(.system(size: pt(17), weight: .bold)).foregroundColor(Theme.ink)
                .frame(width: pt(44), height: pt(44))
                .background(Circle().fill(Color(hex: 0xeef2f6)))
        }
        .buttonStyle(PressStyle(scale: 0.92))
        .accessibilityLabel(label)
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
        padding(pt(24))
            .frame(maxWidth: .infinity, minHeight: pt(300), alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: pt(24), style: .continuous).fill(.white))
            .cardShadow()
    }
}
