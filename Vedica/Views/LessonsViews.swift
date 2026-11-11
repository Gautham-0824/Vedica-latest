import SwiftUI

struct LessonsScreen: View {
    @Environment(AppNavigator.self) private var nav
    private var store: ProgressStore { nav.store }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Lessons").font(Theme.round(40, .black)).foregroundColor(Theme.ink)
                Text("Start with the basics.").font(Theme.text(19, .medium)).foregroundColor(Theme.sub)
            }
            .at(36, 112)

            ZStack(alignment: .topLeading) {
            SVGShape(d: "M380 575 C380 470 660 510 660 400 C660 300 500 320 500 215", viewBox: CGRect(x: 0, y: 0, width: 1024, height: 768))
                .stroke(Color(hex: 0xdfe7ef), style: StrokeStyle(lineWidth: 5, lineCap: .round, dash: [0.1, 16]))
                .frame(width: 1024, height: 768)

            node(.basics, "1", 148, 60, x: 306, y: 501, filled: true, labelX: 478, labelY: 548, title: "Basics", titleSize: 24, sub: nil)
            node(.inter, "2", 116, 48, x: 602, y: 342, filled: false, labelX: 740, labelY: 360, title: "Intermediate", titleSize: 22, sub: "Decimals and division")
            node(.adv, "3", 116, 48, x: 442, y: 157, filled: false, labelX: 580, labelY: 175, title: "Advanced", titleSize: 22, sub: "Algebra")
            }
            .frame(width: 1024, height: 768, alignment: .topLeading)
            // The path is authored for landscape; portrait slides it onto the narrower page.
            .offset(x: Canvas.portrait ? -190 : Canvas.extraX, y: Canvas.portrait ? 130 + Canvas.extraY / 2 : Canvas.extraY)
            .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        }
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        .background(Theme.canvas)
    }

    private func node(_ t: Tier, _ n: String, _ size: CGFloat, _ font: CGFloat, x: CGFloat, y: CGFloat, filled: Bool,
                      labelX: CGFloat, labelY: CGFloat, title: String, titleSize: CGFloat, sub: String?) -> some View {
        let done = store.doneCount(t), total = Catalog.items(t).count
        let c = done == total ? Theme.green : Theme.blue
        return ZStack(alignment: .topLeading) {
            Button { nav.go(.tier(t)) } label: {
                Text(n).font(Theme.round(font, .black)).foregroundColor(filled ? .white : c)
                    .frame(width: size, height: size)
                    .background(Circle().fill(filled ? c : .white))
                    .overlay(Circle().stroke(c, lineWidth: filled ? 0 : 3))
                    .shadow(color: c.opacity(filled ? 0.35 : 0), radius: 20, x: 0, y: 18)
            }
            .buttonStyle(PressStyle())
            .at(x, y)

            Button { nav.go(.tier(t)) } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.round(titleSize, .heavy)).foregroundColor(Theme.ink)
                    if let sub { Text(sub).font(Theme.text(15, .semibold)).foregroundColor(Theme.sub) }
                    Text("\(done) of \(total) done").font(Theme.text(15, .semibold)).foregroundColor(c)
                }
            }
            .buttonStyle(.plain)
            .at(labelX, labelY)
        }
    }
}

struct StatusDot: View {
    let status: Status
    var body: some View {
        switch status {
        case .done:
            Icon(d: IconPath.check, size: 16, stroke: 3, color: .white)
                .frame(width: 24, height: 24).background(Circle().fill(Theme.green))
        case .progress:
            ZStack {
                Circle().stroke(Theme.blue, lineWidth: 2.5)
                Circle().trim(from: 0, to: 0.5).fill(Theme.blue).rotationEffect(.degrees(90)).padding(4)
            }
            .frame(width: 24, height: 24)
        case .new:
            Circle().stroke(Color(hex: 0xdfe7ef), lineWidth: 2.5).frame(width: 24, height: 24)
        }
    }
}

private func statusText(_ s: Status) -> String { s == .done ? "Done" : s == .progress ? "In progress" : "Not started" }

struct TierScreen: View {
    @Environment(AppNavigator.self) private var nav
    let tier: Tier
    private var items: [Catalog.Item] { Catalog.items(tier) }
    private var title: String { tier == .basics ? "Basics" : tier == .inter ? "Intermediate" : "Advanced" }
    private var focus: String? { items.first { nav.store.status($0.id) != .done }?.id }

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 12) {
                Text(title).font(Theme.round(40, .black)).foregroundColor(Theme.ink)
                Text("\(items.count) sutras \u{00B7} \(nav.store.doneCount(tier)) done").font(Theme.text(19, .medium)).foregroundColor(Theme.sub)
            }
            .at(36, 112)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: Canvas.portrait ? (items.count > 6 ? 3 : 2) : (items.count > 6 ? 4 : 3)), spacing: 16) {
                    ForEach(items) { card($0) }
                }
                .padding(EdgeInsets(top: 4, leading: 36, bottom: 124, trailing: 36))
            }
            .frame(width: Canvas.w, height: Canvas.h - 214)
            .at(0, 214)

            RoundIconButton(d: IconPath.back, size: 56, icon: 26) { nav.go(.lessons, forward: false) }
                .at(36, Canvas.h - 30 - 56)
        }
        .frame(width: Canvas.w, height: Canvas.h, alignment: .topLeading)
        .background(Theme.canvas)
    }

    private func card(_ it: Catalog.Item) -> some View {
        let st = nav.store.status(it.id), on = it.id == focus
        return Button { nav.tapCard(it.id) } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(it.glyph)
                    .font(Theme.round(28, .heavy)).tracking(-0.8).foregroundColor(Color(hex: 0x3a4860))
                    .lineLimit(1).minimumScaleFactor(0.6)
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity).frame(height: 92)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.panel))
                Text(it.name).font(Theme.round(22, .heavy)).foregroundColor(Theme.ink)
                    .multilineTextAlignment(.leading).lineLimit(2).minimumScaleFactor(0.8)
                    .padding(.top, 14)
                Spacer(minLength: 0)
                HStack(spacing: 10) {
                    StatusDot(status: st)
                    Text(statusText(st)).font(Theme.text(15, .semibold)).foregroundColor(st == .done ? Theme.green : st == .progress ? Theme.blue : Theme.muted)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity).frame(height: 214)
            .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(on ? Theme.blue : Color(hex: 0xedf1f5), lineWidth: on ? 2 : 1))
            .shadow(color: Theme.blue.opacity(on ? 0.16 : 0), radius: 17, x: 0, y: 14)
        }
        .buttonStyle(PressStyle(scale: 0.98))
    }
}

struct ModuleSheet: View {
    @Environment(AppNavigator.self) private var nav
    let family: String
    private var title: String { Catalog.basics.first { $0.id == family }?.name ?? "" }

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).opacity(0.5)
            Color(hex: 0x17233a, alpha: 0.32)
                .onTapGesture(perform: close)
            VStack(alignment: .leading, spacing: 0) {
                Text("CHOOSE A MODULE").font(Theme.text(13, .bold)).foregroundColor(Theme.blue)
                Text(title).font(Theme.round(30, .black)).foregroundColor(Theme.ink).padding(.top, 6)
                VStack(spacing: 10) {
                    ForEach(Catalog.subs[family] ?? []) { row($0) }
                }
                .padding(.top, 20)
            }
            .padding(EdgeInsets(top: 30, leading: 28, bottom: 28, trailing: 28))
            .frame(width: 520, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 32, style: .continuous).fill(.white))
            .overlay(alignment: .topTrailing) {
                RoundIconButton(d: IconPath.close, size: 40, icon: 20, bg: Color(hex: 0xf1f4f8), border: .clear, shadowOn: false, action: close)
                    .padding(18)
            }
        }
        .frame(width: Canvas.w, height: Canvas.h)
        .transition(.opacity)
    }

    private func close() { withAnimation(.easeOut(duration: 0.26)) { nav.sheet = nil } }

    private func row(_ s: Catalog.Sub) -> some View {
        let st = nav.store.status(s.id)
        return Button { nav.openLesson(s.id) } label: {
            HStack(spacing: 14) {
                Text(s.glyph).font(Theme.round(20, .black)).foregroundColor(Theme.blue)
                    .frame(width: 80, height: 56)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.soft))
                VStack(alignment: .leading, spacing: 2) {
                    Text(s.name).font(Theme.round(20, .heavy)).foregroundColor(Theme.ink)
                    Text(s.example).font(Theme.text(15, .medium)).foregroundColor(Theme.sub)
                }
                Spacer(minLength: 0)
                StatusDot(status: st)
                Icon(d: IconPath.forward, size: 22, stroke: 2.4, color: Theme.muted)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.white))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color(hex: 0xe6ecf2), lineWidth: 1))
        }
        .buttonStyle(PressStyle(scale: 0.98))
    }
}
